import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final pdfServiceProvider = Provider<PDFService>((ref) {
  return PDFService();
});

class PDFService {
  static const MethodChannel _channel = MethodChannel('com.ac.ai/pdf');

  Future<bool> openPDF(String filePath) async {
    try {
      final result = await _channel.invokeMethod<bool>('openPDF', {
        'filePath': filePath,
      });
      return result ?? false;
    } catch (e) {
      print('Open PDF error: $e');
      return false;
    }
  }

  Future<bool> openPDFWithNativeReader(String filePath) async {
    try {
      final result = await _channel.invokeMethod<bool>('openPDFWithNativeReader', {
        'filePath': filePath,
      });
      return result ?? false;
    } catch (e) {
      print('Open PDF with native reader error: $e');
      return false;
    }
  }

  Future<bool> isPDFAvailable(String filePath) async {
    try {
      final result = await _channel.invokeMethod<bool>('isPDFAvailable', {
        'filePath': filePath,
      });
      return result ?? false;
    } catch (e) {
      print('Check PDF available error: $e');
      return false;
    }
  }

  Future<PDFInfo?> getPDFInfo(String filePath) async {
    try {
      final result = await _channel.invokeMethod<String>('getPDFInfo', {
        'filePath': filePath,
      });
      if (result != null) {
        return PDFInfo.fromJson(jsonDecode(result) as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Get PDF info error: $e');
      return null;
    }
  }

  Future<bool> openPDFWithExternalApp(String filePath) async {
    return openPDFWithNativeReader(filePath);
  }
}

class PDFInfo {
  final String path;
  final String fileName;
  final String extension;
  final int size;
  final bool exists;
  final bool isPDF;
  final int lastModified;

  PDFInfo({
    required this.path,
    required this.fileName,
    required this.extension,
    required this.size,
    required this.exists,
    required this.isPDF,
    required this.lastModified,
  });

  factory PDFInfo.fromJson(Map<String, dynamic> json) {
    return PDFInfo(
      path: json['path'] as String,
      fileName: json['fileName'] as String,
      extension: json['extension'] as String,
      size: json['size'] as int,
      exists: json['exists'] as bool,
      isPDF: json['isPDF'] as bool,
      lastModified: json['lastModified'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'path': path,
      'fileName': fileName,
      'extension': extension,
      'size': size,
      'exists': exists,
      'isPDF': isPDF,
      'lastModified': lastModified,
    };
  }

  String get formattedSize {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  DateTime get lastModifiedDate =>
      DateTime.fromMillisecondsSinceEpoch(lastModified);
}
