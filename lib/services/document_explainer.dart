import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'groq_service.dart';

final documentExplainerProvider = Provider<DocumentExplainer>((ref) {
  final groqService = ref.read(groqServiceProvider);
  return DocumentExplainer(groqService);
});

class DocumentExplainer {
  final GroqService _groqService;
  final TextRecognizer _textRecognizer = TextRecognizer();

  DocumentExplainer(this._groqService);

  Future<DocumentAnalysis> analyzeDocument(String filePath) async {
    try {
      final extension = filePath.split('.').last.toLowerCase();
      
      switch (extension) {
        case 'pdf':
          return await _analyzePDF(filePath);
        case 'txt':
          return await _analyzeTextFile(filePath);
        case 'docx':
        case 'doc':
          return await _analyzeDocx(filePath);
        case 'jpg':
        case 'jpeg':
        case 'png':
          return await _analyzeImage(filePath);
        default:
          return DocumentAnalysis(
            filePath: filePath,
            fileType: extension,
            content: '',
            summary: 'Unsupported file type: $extension',
            keyPoints: [],
            error: 'Unsupported file type',
          );
      }
    } catch (e) {
      return DocumentAnalysis(
        filePath: filePath,
        fileType: 'unknown',
        content: '',
        summary: 'Error analyzing document: $e',
        keyPoints: [],
        error: e.toString(),
      );
    }
  }

  Future<DocumentAnalysis> _analyzePDF(String filePath) async {
    try {
      final file = File(filePath);
      final bytes = await file.readAsBytes();
      
      final document = PdfDocument(inputBytes: bytes);
      final text = StringBuffer();
      
      for (int i = 0; i < document.pages.count; i++) {
        final page = document.pages[i];
        final extractor = PdfTextExtractor(document);
        text.writeln(extractor.extractText(startPageIndex: i, endPageIndex: i));
      }
      
      document.dispose();
      
      final content = text.toString();
      final analysis = await _generateAnalysis(content);
      
      return DocumentAnalysis(
        filePath: filePath,
        fileType: 'pdf',
        content: content,
        summary: analysis['summary'] ?? '',
        keyPoints: List<String>.from(analysis['keyPoints'] ?? []),
        wordCount: content.split(RegExp(r'\s+')).length,
        pageCount: document.pages.count,
      );
    } catch (e) {
      throw Exception('Failed to analyze PDF: $e');
    }
  }

  Future<DocumentAnalysis> _analyzeTextFile(String filePath) async {
    try {
      final file = File(filePath);
      final content = await file.readAsString();
      final analysis = await _generateAnalysis(content);
      
      return DocumentAnalysis(
        filePath: filePath,
        fileType: 'txt',
        content: content,
        summary: analysis['summary'] ?? '',
        keyPoints: List<String>.from(analysis['keyPoints'] ?? []),
        wordCount: content.split(RegExp(r'\s+')).length,
      );
    } catch (e) {
      throw Exception('Failed to analyze text file: $e');
    }
  }

  Future<DocumentAnalysis> _analyzeDocx(String filePath) async {
    return DocumentAnalysis(
      filePath: filePath,
      fileType: 'docx',
      content: '',
      summary: 'DOCX support coming soon. Please convert to PDF or text.',
      keyPoints: [],
      error: 'DOCX not yet supported',
    );
  }

  Future<DocumentAnalysis> _analyzeImage(String filePath) async {
    try {
      final inputImage = InputImage.fromFilePath(filePath);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      
      final content = recognizedText.text;
      final analysis = await _generateAnalysis(content);
      
      return DocumentAnalysis(
        filePath: filePath,
        fileType: 'image',
        content: content,
        summary: analysis['summary'] ?? '',
        keyPoints: List<String>.from(analysis['keyPoints'] ?? []),
        wordCount: content.split(RegExp(r'\s+')).length,
      );
    } catch (e) {
      throw Exception('Failed to analyze image: $e');
    }
  }

  Future<Map<String, dynamic>> _generateAnalysis(String content) async {
    try {
      final truncatedContent = content.length > 8000 
          ? '${content.substring(0, 8000)}...' 
          : content;
      
      final response = await _groqService.chatCompletion(
        messages: [
          GroqMessage.system('''You are a document analysis assistant. 
Provide a JSON response with "summary" (brief overview) and "keyPoints" (list of important points).'''),
          GroqMessage.user('Analyze this document and provide summary and key points:\n\n$truncatedContent'),
        ],
        temperature: 0.3,
        maxTokens: 1000,
      );

      final aiResponse = response.content;
      
      try {
        final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(aiResponse);
        if (jsonMatch != null) {
          final jsonStr = jsonMatch.group(0);
          final parsed = jsonDecode(jsonStr!) as Map<String, dynamic>;
          return {
            'summary': parsed['summary'] ?? aiResponse,
            'keyPoints': List<String>.from(parsed['keyPoints'] ?? []),
          };
        }
      } catch (e) {
        print('JSON parsing failed, using raw response');
      }
      
      return {
        'summary': aiResponse,
        'keyPoints': _extractKeyPointsFromText(aiResponse),
      };
    } catch (e) {
      print('AI analysis failed: $e');
      return {
        'summary': 'Analysis failed. Content preview: ${content.substring(0, 200)}',
        'keyPoints': [],
      };
    }
  }

  List<String> _extractKeyPointsFromText(String text) {
    final lines = text.split('\n');
    final keyPoints = <String>[];
    
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.startsWith('-') || trimmed.startsWith('*') || trimmed.startsWith('•')) {
        keyPoints.add(trimmed.replaceFirst(RegExp(r'^[-*•]\s*'), ''));
      } else if (RegExp(r'^\d+\.').hasMatch(trimmed)) {
        keyPoints.add(RegExp(r'^\d+\.\s*').firstMatch(trimmed)?.after ?? trimmed);
      }
    }
    
    return keyPoints.isEmpty 
        ? [text.split('.').firstWhere((s) => s.length > 20, orElse: () => text.substring(0, text.length.clamp(0, 100)))] 
        : keyPoints;
  }

  Future<String> answerQuestion({
    required String filePath,
    required String question,
  }) async {
    try {
      final analysis = await analyzeDocument(filePath);
      
      if (analysis.error != null) {
        return 'Error: ${analysis.error}';
      }

      final response = await _groqService.chatCompletion(
        messages: [
          GroqMessage.system('''You are a helpful assistant. Answer questions based on the provided document content.'''),
          GroqMessage.user('''Document content:\n${analysis.content.substring(0, analysis.content.length.clamp(0, 6000))}

Question: $question'''),
        ],
        temperature: 0.3,
        maxTokens: 1000,
      );

      return response.content;
    } catch (e) {
      return 'Error answering question: $e';
    }
  }

  Future<String> extractTopics(String filePath) async {
    try {
      final analysis = await analyzeDocument(filePath);
      
      if (analysis.error != null) {
        return 'Error: ${analysis.error}';
      }

      final response = await _groqService.chatCompletion(
        messages: [
          GroqMessage.system('''Extract the main topics and themes from the document. Return as a comma-separated list.'''),
          GroqMessage.user(analysis.content.substring(0, analysis.content.length.clamp(0, 6000))),
        ],
        temperature: 0.3,
        maxTokens: 500,
      );

      return response.content;
    } catch (e) {
      return 'Error extracting topics: $e';
    }
  }

  Future<String> translateDocument({
    required String filePath,
    required String targetLanguage,
  }) async {
    try {
      final analysis = await analyzeDocument(filePath);
      
      if (analysis.error != null) {
        return 'Error: ${analysis.error}';
      }

      final response = await _groqService.chatCompletion(
        messages: [
          GroqMessage.system('''Translate the following document to $targetLanguage. Maintain the original formatting as much as possible.'''),
          GroqMessage.user(analysis.content.substring(0, analysis.content.length.clamp(0, 6000))),
        ],
        temperature: 0.3,
        maxTokens: 4000,
      );

      return response.content;
    } catch (e) {
      return 'Error translating document: $e';
    }
  }
}

class DocumentAnalysis {
  final String filePath;
  final String fileType;
  final String content;
  final String summary;
  final List<String> keyPoints;
  final int? wordCount;
  final int? pageCount;
  final String? error;

  DocumentAnalysis({
    required this.filePath,
    required this.fileType,
    required this.content,
    required this.summary,
    required this.keyPoints,
    this.wordCount,
    this.pageCount,
    this.error,
  });

  bool get hasError => error != null;
}

extension on RegExpMatch {
  String get after => input.substring(end);
}
