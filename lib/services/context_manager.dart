import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/memory_repository.dart';
import '../services/groq_service.dart';

final contextManagerProvider = Provider<ContextManager>((ref) {
  final groqService = ref.read(groqServiceProvider);
  return ContextManager(groqService);
});

class ContextManager {
  final GroqService _groqService;
  final MemoryRepository _memoryRepository = MemoryRepository();

  final Map<String, dynamic> _contextCache = {};

  ContextManager(this._groqService);

  Future<void> updateContext(String key, dynamic value) async {
    _contextCache[key] = value;
    await _memoryRepository.saveMemory(
      MemoryModel.create(
        key: 'context_$key',
        value: value.toString(),
        category: 'context',
        metadata: {'timestamp': DateTime.now().toIso8601String()},
      ),
    );
  }

  dynamic getContext(String key) {
    return _contextCache[key];
  }

  Future<void> trackCurrentApp(String packageName, String? appName) async {
    await updateContext('current_app', {
      'packageName': packageName,
      'appName': appName,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<void> trackCurrentPDF(String filePath) async {
    await updateContext('current_pdf', {
      'path': filePath,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<void> trackCurrentFile(String filePath) async {
    await updateContext('current_file', {
      'path': filePath,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<void> trackCurrentImage(String filePath) async {
    await updateContext('current_image', {
      'path': filePath,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<void> trackLastScreenshot(String filePath) async {
    await updateContext('last_screenshot', {
      'path': filePath,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<void> trackLastDownload(String filePath) async {
    await updateContext('last_download', {
      'path': filePath,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<void> trackLastPhoto(String filePath) async {
    await updateContext('last_photo', {
      'path': filePath,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<void> trackLastSharedItem(String content) async {
    await updateContext('last_shared', {
      'content': content,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<void> clearContext(String key) async {
    _contextCache.remove(key);
    await _memoryRepository.deleteMemoryByKey('context_$key');
  }

  Future<void> clearAllContext() async {
    _contextCache.clear();
    final contexts = await _memoryRepository.getMemoryByCategory('context');
    for (final ctx in contexts) {
      if (ctx.id != null) {
        await _memoryRepository.deleteMemory(ctx.id!);
      }
    }
  }

  Future<Map<String, dynamic>> getFullContext() async {
    final context = <String, dynamic>{};
    
    final currentApp = getContext('current_app');
    if (currentApp != null) context['current_app'] = currentApp;
    
    final currentPDF = getContext('current_pdf');
    if (currentPDF != null) context['current_pdf'] = currentPDF;
    
    final currentFile = getContext('current_file');
    if (currentFile != null) context['current_file'] = currentFile;
    
    final currentImage = getContext('current_image');
    if (currentImage != null) context['current_image'] = currentImage;
    
    final lastScreenshot = getContext('last_screenshot');
    if (lastScreenshot != null) context['last_screenshot'] = lastScreenshot;
    
    final lastDownload = getContext('last_download');
    if (lastDownload != null) context['last_download'] = lastDownload;
    
    final lastPhoto = getContext('last_photo');
    if (lastPhoto != null) context['last_photo'] = lastPhoto;
    
    final lastShared = getContext('last_shared');
    if (lastShared != null) context['last_shared'] = lastShared;
    
    return context;
  }

  Future<String> resolveContextReference(String reference) async {
    final lower = reference.toLowerCase();
    final context = await getFullContext();
    
    if (lower.contains('ye photo') || lower.contains('this photo') || lower.contains('this image')) {
      final image = getContext('current_image') ?? getContext('last_photo');
      if (image != null) return image['path'] as String;
    }
    
    if (lower.contains('ye file') || lower.contains('this file')) {
      final file = getContext('current_file') ?? getContext('last_download');
      if (file != null) return file['path'] as String;
    }
    
    if (lower.contains('ye pdf') || lower.contains('this pdf')) {
      final pdf = getContext('current_pdf');
      if (pdf != null) return pdf['path'] as String;
    }
    
    if (lower.contains('screenshot') || lower.contains('ss')) {
      final screenshot = getContext('last_screenshot');
      if (screenshot != null) return screenshot['path'] as String;
    }
    
    return reference;
  }

  String? getCurrentAppPackage() {
    final app = getContext('current_app');
    return app?['packageName'] as String?;
  }

  String? getCurrentFile() {
    final file = getContext('current_file');
    return file?['path'] as String?;
  }

  String? getCurrentImage() {
    final image = getContext('current_image');
    return image?['path'] as String?;
  }

  String? getLastScreenshot() {
    final screenshot = getContext('last_screenshot');
    return screenshot?['path'] as String?;
  }

  String? getLastDownload() {
    final download = getContext('last_download');
    return download?['path'] as String?;
  }

  String? getLastPhoto() {
    final photo = getContext('last_photo');
    return photo?['path'] as String?;
  }
}
