import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';
import '../data/models/memory_model.dart';
import '../data/repositories/memory_repository.dart';

final fileAgentServiceProvider = Provider<FileAgentService>((ref) {
  return FileAgentService();
});

class FileAgentService {
  final MemoryRepository _memoryRepository = MemoryRepository();

  Future<List<FileSystemEntity>> listDirectory(String path) async {
    try {
      final directory = Directory(path);
      if (!await directory.exists()) {
        return [];
      }

      final entities = await directory.list().toList();
      entities.sort((a, b) {
        if (a is Directory && b is File) return -1;
        if (a is File && b is Directory) return 1;
        return path.basename(a.path).compareTo(path.basename(b.path));
      });

      return entities;
    } catch (e) {
      print('Error listing directory: $e');
      return [];
    }
  }

  Future<List<FileIndexModel>> searchFiles({
    required String query,
    String? extension,
    int? minSize,
    int? maxSize,
    DateTime? modifiedAfter,
    DateTime? modifiedBefore,
  }) async {
    final results = <FileIndexModel>[];

    try {
      final storagePath = await _getStoragePath();
      await _searchDirectoryRecursive(
        Directory(storagePath),
        query,
        results,
        extension: extension,
        minSize: minSize,
        maxSize: maxSize,
        modifiedAfter: modifiedAfter,
        modifiedBefore: modifiedBefore,
      );
    } catch (e) {
      print('Error searching files: $e');
    }

    return results;
  }

  Future<void> _searchDirectoryRecursive(
    Directory directory,
    String query,
    List<FileIndexModel> results, {
    String? extension,
    int? minSize,
    int? maxSize,
    DateTime? modifiedAfter,
    DateTime? modifiedBefore,
    int maxDepth = 5,
    int currentDepth = 0,
  }) async {
    if (currentDepth >= maxDepth) {
      return;
    }

    try {
      await for (final entity in directory.list()) {
        if (entity is File) {
          final filename = path.basename(entity.path);
          final fileExtension = path.extension(entity.path).toLowerCase();
          final stat = await entity.stat();

          if (!filename.toLowerCase().contains(query.toLowerCase())) {
            continue;
          }

          if (extension != null && fileExtension != '.$extension') {
            continue;
          }

          if (minSize != null && stat.size < minSize) {
            continue;
          }

          if (maxSize != null && stat.size > maxSize) {
            continue;
          }

          if (modifiedAfter != null && stat.modified.isBefore(modifiedAfter)) {
            continue;
          }

          if (modifiedBefore != null && stat.modified.isAfter(modifiedBefore)) {
            continue;
          }

          results.add(FileIndexModel.create(
            path: entity.path,
            filename: filename,
            extension: fileExtension.isNotEmpty ? fileExtension.substring(1) : null,
            size: stat.size,
            modifiedTime: stat.modified,
            isDirectory: false,
            mimeType: _getMimeType(fileExtension),
          ));
        } else if (entity is Directory) {
          await _searchDirectoryRecursive(
            entity,
            query,
            results,
            extension: extension,
            minSize: minSize,
            maxSize: maxSize,
            modifiedAfter: modifiedAfter,
            modifiedBefore: modifiedBefore,
            maxDepth: maxDepth,
            currentDepth: currentDepth + 1,
          );
        }
      }
    } catch (e) {
    }
  }

  Future<bool> renameFile(String oldPath, String newName) async {
    try {
      final file = File(oldPath);
      if (!await file.exists()) {
        return false;
      }

      final directory = path.dirname(oldPath);
      final newPath = path.join(directory, newName);
      await file.rename(newPath);
      return true;
    } catch (e) {
      print('Error renaming file: $e');
      return false;
    }
  }

  Future<bool> moveFile(String sourcePath, String destinationPath) async {
    try {
      final file = File(sourcePath);
      if (!await file.exists()) {
        return false;
      }

      await file.rename(destinationPath);
      return true;
    } catch (e) {
      print('Error moving file: $e');
      return false;
    }
  }

  Future<bool> copyFile(String sourcePath, String destinationPath) async {
    try {
      final file = File(sourcePath);
      if (!await file.exists()) {
        return false;
      }

      await file.copy(destinationPath);
      return true;
    } catch (e) {
      print('Error copying file: $e');
      return false;
    }
  }

  Future<bool> deleteFile(String filePath, {bool requireConfirmation = true}) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return false;
      }

      await file.delete();
      return true;
    } catch (e) {
      print('Error deleting file: $e');
      return false;
    }
  }

  Future<List<FileIndexModel>> findDuplicates(String directoryPath) async {
    final fileHashes = <String, List<File>>{};
    final duplicates = <FileIndexModel>[];

    try {
      await _calculateHashesRecursive(Directory(directoryPath), fileHashes);

      for (final entry in fileHashes.entries) {
        if (entry.value.length > 1) {
          for (final file in entry.value.skip(1)) {
            final stat = await file.stat();
            duplicates.add(FileIndexModel.create(
              path: file.path,
              filename: path.basename(file.path),
              extension: path.extension(file.path),
              size: stat.size,
              modifiedTime: stat.modified,
              isDirectory: false,
            ));
          }
        }
      }
    } catch (e) {
      print('Error finding duplicates: $e');
    }

    return duplicates;
  }

  Future<void> _calculateHashesRecursive(
    Directory directory,
    Map<String, List<File>> fileHashes,
  ) async {
    try {
      await for (final entity in directory.list()) {
        if (entity is File) {
          try {
            final bytes = await entity.readAsBytes();
            final hash = _calculateSimpleHash(bytes);
            fileHashes.putIfAbsent(hash, () => []).add(entity);
          } catch (e) {
          }
        } else if (entity is Directory) {
          await _calculateHashesRecursive(entity, fileHashes);
        }
      }
    } catch (e) {
    }
  }

  String _calculateSimpleHash(List<int> bytes) {
    int hash = 0;
    for (int i = 0; i < bytes.length && i < 10000; i++) {
      hash = ((hash << 5) - hash + bytes[i]) & 0xFFFFFFFF;
    }
    return hash.toString();
  }

  Future<List<FileIndexModel>> findLargeFiles({
    required String directoryPath,
    int minSizeMB = 100,
  }) async {
    final largeFiles = <FileIndexModel>[];
    final minSizeBytes = minSizeMB * 1024 * 1024;

    try {
      await for (final entity in Directory(directoryPath).list(recursive: true)) {
        if (entity is File) {
          try {
            final stat = await entity.stat();
            if (stat.size >= minSizeBytes) {
              largeFiles.add(FileIndexModel.create(
                path: entity.path,
                filename: path.basename(entity.path),
                extension: path.extension(entity.path),
                size: stat.size,
                modifiedTime: stat.modified,
                isDirectory: false,
              ));
            }
          } catch (e) {
          }
        }
      }
    } catch (e) {
      print('Error finding large files: $e');
    }

    largeFiles.sort((a, b) => (b.size ?? 0).compareTo(a.size ?? 0));
    return largeFiles;
  }

  Future<bool> organizeFiles({
    required String sourcePath,
    required String destinationPath,
    required String strategy,
  }) async {
    try {
      switch (strategy) {
        case 'by_extension':
          return await _organizeByExtension(sourcePath, destinationPath);
        case 'by_date':
          return await _organizeByDate(sourcePath, destinationPath);
        case 'by_size':
          return await _organizeBySize(sourcePath, destinationPath);
        default:
          return false;
      }
    } catch (e) {
      print('Error organizing files: $e');
      return false;
    }
  }

  Future<bool> _organizeByExtension(String sourcePath, String destinationPath) async {
    try {
      final sourceDir = Directory(sourcePath);
      if (!await sourceDir.exists()) {
        return false;
      }

      await for (final entity in sourceDir.list()) {
        if (entity is File) {
          final extension = path.extension(entity.path).toLowerCase();
          final extDir = extension.isNotEmpty ? extension.substring(1) : 'no_extension';
          final targetDir = Directory(path.join(destinationPath, extDir));
          await targetDir.create(recursive: true);
          await entity.copy(path.join(targetDir.path, path.basename(entity.path)));
        }
      }
      return true;
    } catch (e) {
      print('Error organizing by extension: $e');
      return false;
    }
  }

  Future<bool> _organizeByDate(String sourcePath, String destinationPath) async {
    try {
      final sourceDir = Directory(sourcePath);
      if (!await sourceDir.exists()) {
        return false;
      }

      await for (final entity in sourceDir.list()) {
        if (entity is File) {
          final stat = await entity.stat();
          final dateStr = '${stat.modified.year}-${stat.modified.month.toString().padLeft(2, '0')}';
          final targetDir = Directory(path.join(destinationPath, dateStr));
          await targetDir.create(recursive: true);
          await entity.copy(path.join(targetDir.path, path.basename(entity.path)));
        }
      }
      return true;
    } catch (e) {
      print('Error organizing by date: $e');
      return false;
    }
  }

  Future<bool> _organizeBySize(String sourcePath, String destinationPath) async {
    try {
      final sourceDir = Directory(sourcePath);
      if (!await sourceDir.exists()) {
        return false;
      }

      await for (final entity in sourceDir.list()) {
        if (entity is File) {
          final stat = await entity.stat();
          String sizeCategory;
          if (stat.size < 1024 * 1024) {
            sizeCategory = 'small_under_1mb';
          } else if (stat.size < 100 * 1024 * 1024) {
            sizeCategory = 'medium_1mb_to_100mb';
          } else {
            sizeCategory = 'large_over_100mb';
          }
          final targetDir = Directory(path.join(destinationPath, sizeCategory));
          await targetDir.create(recursive: true);
          await entity.copy(path.join(targetDir.path, path.basename(entity.path)));
        }
      }
      return true;
    } catch (e) {
      print('Error organizing by size: $e');
      return false;
    }
  }

  Future<String> getFileStats(String directoryPath) async {
    try {
      final directory = Directory(directoryPath);
      if (!await directory.exists()) {
        return 'Directory not found';
      }

      int fileCount = 0;
      int directoryCount = 0;
      int totalSize = 0;
      final extensions = <String, int>{};

      await for (final entity in directory.list(recursive: true)) {
        if (entity is File) {
          fileCount++;
          final stat = await entity.stat();
          totalSize += stat.size;
          final ext = path.extension(entity.path).toLowerCase();
          extensions[ext] = (extensions[ext] ?? 0) + 1;
        } else if (entity is Directory) {
          directoryCount++;
        }
      }

      final sortedExtensions = extensions.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return '''
File Statistics for $directoryPath:
- Total Files: $fileCount
- Total Directories: $directoryCount
- Total Size: ${_formatSize(totalSize)}

Top Extensions:
${sortedExtensions.take(10).map((e) => '  ${e.key}: ${e.value} files').join('\n')}
''';
    } catch (e) {
      return 'Error getting stats: $e';
    }
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  String _getMimeType(String extension) {
    final mimeTypes = {
      '.jpg': 'image/jpeg',
      '.jpeg': 'image/jpeg',
      '.png': 'image/png',
      '.gif': 'image/gif',
      '.pdf': 'application/pdf',
      '.doc': 'application/msword',
      '.docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      '.txt': 'text/plain',
      '.mp3': 'audio/mpeg',
      '.mp4': 'video/mp4',
      '.zip': 'application/zip',
    };
    return mimeTypes[extension.toLowerCase()] ?? 'application/octet-stream';
  }

  Future<String> _getStoragePath() async {
    final directory = await getExternalStorageDirectory();
    return directory?.path ?? (await getApplicationDocumentsDirectory()).path;
  }
}
