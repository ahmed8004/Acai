import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import '../data/models/memory_model.dart';
import '../data/repositories/memory_repository.dart';

final downloadManagerProvider = Provider<DownloadManager>((ref) {
  return DownloadManager();
});

class DownloadManager {
  final MemoryRepository _memoryRepository = MemoryRepository();
  final Map<int, DownloadTask> _activeDownloads = {};
  final StreamController<DownloadTask> _downloadProgressController = StreamController<DownloadTask>.broadcast();
  final StreamController<DownloadTask> _downloadCompleteController = StreamController<DownloadTask>.broadcast();
  
  Stream<DownloadTask> get onProgress => _downloadProgressController.stream;
  Stream<DownloadTask> get onComplete => _downloadCompleteController.stream;

  Future<DownloadTask?> enqueueDownload({
    required String url,
    String? filename,
    String? destinationPath,
    Map<String, String>? headers,
  }) async {
    try {
      final fileName = filename ?? _extractFilenameFromUrl(url);
      final destPath = destinationPath ?? await _getDefaultDownloadPath();
      final fullPath = '$destPath/$fileName';

      final task = DownloadTask(
        id: DateTime.now().millisecondsSinceEpoch,
        url: url,
        filePath: fullPath,
        filename: fileName,
        status: DownloadTaskStatus.pending,
        progress: 0,
        totalBytes: 0,
        downloadedBytes: 0,
        createdAt: DateTime.now(),
      );

      await _memoryRepository.addReminder(
        ReminderModel.create(
          title: 'Download: $fileName',
          description: url,
        ),
      );

      _activeDownloads[task.id] = task;
      _startDownload(task, headers);

      return task;
    } catch (e) {
      print('Error enqueueing download: $e');
      return null;
    }
  }

  Future<void> _startDownload(DownloadTask task, Map<String, String>? headers) async {
    try {
      _updateTaskStatus(task.id, DownloadTaskStatus.downloading);

      final client = http.Client();
      final request = http.Request('GET', Uri.parse(task.url));
      
      if (headers != null) {
        request.headers.addAll(headers);
      }

      final response = await client.send(request);
      
      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }

      final totalBytes = response.contentLength ?? 0;
      task.totalBytes = totalBytes;

      final file = File(task.filePath);
      await file.create(recursive: true);
      final sink = file.openWrite();

      int downloadedBytes = 0;
      await for (final chunk in response.stream) {
        sink.add(chunk);
        downloadedBytes += chunk.length;
        
        task.downloadedBytes = downloadedBytes;
        task.progress = totalBytes > 0 ? (downloadedBytes / totalBytes * 100).toInt() : 0;
        
        _downloadProgressController.add(task);
      }

      await sink.close();
      client.close();

      task.status = DownloadTaskStatus.completed;
      task.completedAt = DateTime.now();
      
      _downloadProgressController.add(task);
      _downloadCompleteController.add(task);
      _activeDownloads.remove(task.id);

    } catch (e) {
      print('Download error: $e');
      _updateTaskStatus(task.id, DownloadTaskStatus.failed);
      task.status = DownloadTaskStatus.failed;
      _downloadProgressController.add(task);
      _activeDownloads.remove(task.id);
    }
  }

  Future<bool> pauseDownload(int id) async {
    final task = _activeDownloads[id];
    if (task != null && task.status == DownloadTaskStatus.downloading) {
      _updateTaskStatus(id, DownloadTaskStatus.paused);
      return true;
    }
    return false;
  }

  Future<bool> resumeDownload(int id) async {
    final task = _activeDownloads[id];
    if (task != null && task.status == DownloadTaskStatus.paused) {
      _updateTaskStatus(id, DownloadTaskStatus.downloading);
      return true;
    }
    return false;
  }

  Future<bool> cancelDownload(int id) async {
    final task = _activeDownloads[id];
    if (task != null) {
      _updateTaskStatus(id, DownloadTaskStatus.cancelled);
      _activeDownloads.remove(id);
      return true;
    }
    return false;
  }

  Future<bool> retryDownload(int id) async {
    final task = _activeDownloads[id];
    if (task != null && task.status == DownloadTaskStatus.failed) {
      _updateTaskStatus(id, DownloadTaskStatus.pending);
      _startDownload(task, null);
      return true;
    }
    return false;
  }

  void _updateTaskStatus(int id, DownloadTaskStatus status) {
    final task = _activeDownloads[id];
    if (task != null) {
      task.status = status;
    }
  }

  Future<List<DownloadTask>> getDownloadHistory() async {
    return _activeDownloads.values.toList();
  }

  Future<List<DownloadTask>> getActiveDownloads() async {
    return _activeDownloads.values
        .where((t) => t.status == DownloadTaskStatus.downloading)
        .toList();
  }

  Future<List<DownloadTask>> getPendingDownloads() async {
    return _activeDownloads.values
        .where((t) => t.status == DownloadTaskStatus.pending || t.status == DownloadTaskStatus.paused)
        .toList();
  }

  Future<bool> deleteDownload(int id, {bool deleteFile = true}) async {
    final task = _activeDownloads[id];
    if (task != null) {
      if (deleteFile) {
        try {
          final file = File(task.filePath);
          if (await file.exists()) {
            await file.delete();
          }
        } catch (e) {
          print('Error deleting file: $e');
        }
      }
      _activeDownloads.remove(id);
      return true;
    }
    return false;
  }

  Future<String> _getDefaultDownloadPath() async {
    final directory = await getExternalStorageDirectory();
    final path = directory?.path ?? (await getApplicationDocumentsDirectory()).path;
    return '$path/Downloads';
  }

  String _extractFilenameFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final path = uri.path;
      final segments = path.split('/');
      if (segments.isNotEmpty && segments.last.isNotEmpty) {
        return Uri.decodeComponent(segments.last);
      }
    } catch (e) {
      print('Error extracting filename: $e');
    }
    return 'download_${DateTime.now().millisecondsSinceEpoch}';
  }

  void dispose() {
    _downloadProgressController.close();
    _downloadCompleteController.close();
  }
}

class DownloadTask {
  final int id;
  final String url;
  final String filePath;
  final String filename;
  DownloadTaskStatus status;
  int progress;
  int totalBytes;
  int downloadedBytes;
  final DateTime createdAt;
  DateTime? completedAt;

  DownloadTask({
    required this.id,
    required this.url,
    required this.filePath,
    required this.filename,
    required this.status,
    required this.progress,
    required this.totalBytes,
    required this.downloadedBytes,
    required this.createdAt,
    this.completedAt,
  });

  String get formattedSize {
    if (totalBytes < 1024) return '$totalBytes B';
    if (totalBytes < 1024 * 1024) return '${(totalBytes / 1024).toStringAsFixed(1)} KB';
    if (totalBytes < 1024 * 1024 * 1024) return '${(totalBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(totalBytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  String get formattedSpeed {
    final elapsed = DateTime.now().difference(createdAt).inSeconds;
    if (elapsed == 0) return '0 B/s';
    final speed = downloadedBytes / elapsed;
    if (speed < 1024) return '${speed.toStringAsFixed(1)} B/s';
    if (speed < 1024 * 1024) return '${(speed / 1024).toStringAsFixed(1)} KB/s';
    return '${(speed / (1024 * 1024)).toStringAsFixed(1)} MB/s';
  }

  Duration get estimatedTimeRemaining {
    if (totalBytes == 0 || downloadedBytes == 0) return Duration.zero;
    final elapsed = DateTime.now().difference(createdAt).inSeconds;
    final speed = downloadedBytes / elapsed;
    final remaining = totalBytes - downloadedBytes;
    return Duration(seconds: (remaining / speed).toInt());
  }
}

enum DownloadTaskStatus {
  pending,
  downloading,
  paused,
  completed,
  failed,
  cancelled,
}
