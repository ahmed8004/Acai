import 'dart:convert';
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_constants.dart';
import 'settings_service.dart';

final groqServiceProvider = Provider<GroqService>((ref) {
  final settings = ref.read(settingsServiceProvider);
  return GroqService(settings);
});

class GroqService {
  final SettingsService _settings;
  late final Dio _dio;

  GroqService(this._settings) {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.groqBaseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 60),
        headers: {
          'Content-Type': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final apiKey = await _settings.getGroqApiKey();
          if (apiKey != null && apiKey.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $apiKey';
          }
          handler.next(options);
        },
        onError: (error, handler) {
          print('Groq API Error: ${error.message}');
          handler.next(error);
        },
      ),
    );
  }

  Future<GroqResponse> chatCompletion({
    required List<GroqMessage> messages,
    String model = 'llama-3.1-70b-versatile',
    double temperature = 0.7,
    int maxTokens = 4096,
    double topP = 0.9,
    bool stream = false,
  }) async {
    try {
      final response = await _dio.post(
        '/chat/completions',
        data: {
          'model': model,
          'messages': messages.map((m) => m.toJson()).toList(),
          'temperature': temperature,
          'max_tokens': maxTokens,
          'top_p': topP,
          'stream': stream,
        },
      );

      if (response.statusCode == 200) {
        return GroqResponse.fromJson(response.data);
      } else {
        throw Exception('Failed to get completion: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('API Error: ${e.message}');
    } catch (e) {
      throw Exception('Unknown error: $e');
    }
  }

  Future<GroqResponse> reasoningCompletion({
    required String query,
    String model = 'llama-3.1-70b-versatile',
  }) async {
    final messages = [
      GroqMessage.system('''You are AC AI, an advanced technical assistant. 
Think step by step and provide clear, detailed reasoning.'''),
      GroqMessage.user(query),
    ];

    return await chatCompletion(
      messages: messages,
      model: model,
      temperature: 0.3,
    );
  }

  Future<GroqResponse> planningCompletion({
    required String task,
    String model = 'llama-3.1-70b-versatile',
  }) async {
    final messages = [
      GroqMessage.system('''You are AC AI, a planning assistant. 
Break down complex tasks into actionable steps.'''),
      GroqMessage.user('Create a plan for: $task'),
    ];

    return await chatCompletion(
      messages: messages,
      model: model,
      temperature: 0.5,
    );
  }

  Future<GroqResponse> summarizeText({
    required String text,
    int maxLength = 200,
    String model = 'llama-3.1-8b-instant',
  }) async {
    final messages = [
      GroqMessage.system('''You are a summarization assistant. 
Provide concise summaries while maintaining key information.'''),
      GroqMessage.user('Summarize the following text in $maxLength words or less:\n\n$text'),
    ];

    return await chatCompletion(
      messages: messages,
      model: model,
      temperature: 0.3,
      maxTokens: maxLength * 2,
    );
  }

  Future<GroqResponse> explainConcept({
    required String concept,
    String model = 'llama-3.1-70b-versatile',
  }) async {
    final messages = [
      GroqMessage.system('''You are an educational assistant. 
Explain concepts clearly with examples.'''),
      GroqMessage.user('Explain: $concept'),
    ];

    return await chatCompletion(
      messages: messages,
      model: model,
      temperature: 0.5,
    );
  }

  Future<GroqResponse> analyzeImage({
    required String imageBase64,
    String prompt = 'Describe what you see in this image.',
    String model = 'llama-3.2-90b-vision-preview',
  }) async {
    final messages = [
      GroqMessage.system('You are a visual analysis assistant.'),
      GroqMessage.userWithImage(prompt, imageBase64),
    ];

    return await chatCompletion(
      messages: messages,
      model: model,
      temperature: 0.7,
    );
  }

  Future<GroqResponse> analyzePDF({
    required String pdfContent,
    String query = 'Summarize the key points of this document.',
    String model = 'llama-3.1-70b-versatile',
  }) async {
    final messages = [
      GroqMessage.system('''You are a document analysis assistant. 
Analyze PDF content and answer questions accurately.'''),
      GroqMessage.user('$query\n\nDocument Content:\n$pdfContent'),
    ];

    return await chatCompletion(
      messages: messages,
      model: model,
      temperature: 0.3,
      maxTokens: 4096,
    );
  }

  Future<bool> testConnection(String apiKey) async {
    try {
      final testDio = Dio(
        BaseOptions(
          baseUrl: AppConstants.groqBaseUrl,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $apiKey',
          },
        ),
      );

      final response = await testDio.get('/models');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<List<GroqModel>> getAvailableModels() async {
    try {
      final response = await _dio.get('/models');
      
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final models = data['data'] as List<dynamic>;
        return models.map((m) => GroqModel.fromJson(m as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}

class GroqMessage {
  final String role;
  final String content;
  final List<GroqContent>? contentParts;

  GroqMessage({
    required this.role,
    required this.content,
    this.contentParts,
  });

  factory GroqMessage.system(String content) {
    return GroqMessage(role: 'system', content: content);
  }

  factory GroqMessage.user(String content) {
    return GroqMessage(role: 'user', content: content);
  }

  factory GroqMessage.assistant(String content) {
    return GroqMessage(role: 'assistant', content: content);
  }

  factory GroqMessage.userWithImage(String text, String imageBase64) {
    return GroqMessage(
      role: 'user',
      content: text,
      contentParts: [
        GroqContent(type: 'text', text: text),
        GroqContent(type: 'image_url', imageUrl: GroqImageUrl(url: 'data:image/jpeg;base64,$imageBase64')),
      ],
    );
  }

  Map<String, dynamic> toJson() {
    if (contentParts != null) {
      return {
        'role': role,
        'content': contentParts!.map((p) => p.toJson()).toList(),
      };
    }
    return {
      'role': role,
      'content': content,
    };
  }
}

class GroqContent {
  final String type;
  final String? text;
  final GroqImageUrl? imageUrl;

  GroqContent({
    required this.type,
    this.text,
    this.imageUrl,
  });

  Map<String, dynamic> toJson() {
    if (type == 'text') {
      return {'type': type, 'text': text};
    } else if (type == 'image_url') {
      return {'type': type, 'image_url': imageUrl?.toJson()};
    }
    return {'type': type};
  }
}

class GroqImageUrl {
  final String url;

  GroqImageUrl({required this.url});

  Map<String, dynamic> toJson() {
    return {'url': url};
  }
}

class GroqResponse {
  final String id;
  final String object;
  final int created;
  final String model;
  final List<GroqChoice> choices;
  final GroqUsage usage;

  GroqResponse({
    required this.id,
    required this.object,
    required this.created,
    required this.model,
    required this.choices,
    required this.usage,
  });

  factory GroqResponse.fromJson(Map<String, dynamic> json) {
    return GroqResponse(
      id: json['id'] as String,
      object: json['object'] as String,
      created: json['created'] as int,
      model: json['model'] as String,
      choices: (json['choices'] as List<dynamic>)
          .map((c) => GroqChoice.fromJson(c as Map<String, dynamic>))
          .toList(),
      usage: GroqUsage.fromJson(json['usage'] as Map<String, dynamic>),
    );
  }

  String get content => choices.isNotEmpty ? choices.first.message.content : '';
}

class GroqChoice {
  final int index;
  final GroqMessage message;
  final String? finishReason;

  GroqChoice({
    required this.index,
    required this.message,
    this.finishReason,
  });

  factory GroqChoice.fromJson(Map<String, dynamic> json) {
    return GroqChoice(
      index: json['index'] as int,
      message: GroqMessage(
        role: json['message']['role'] as String,
        content: json['message']['content'] as String,
      ),
      finishReason: json['finish_reason'] as String?,
    );
  }
}

class GroqUsage {
  final int promptTokens;
  final int completionTokens;
  final int totalTokens;

  GroqUsage({
    required this.promptTokens,
    required this.completionTokens,
    required this.totalTokens,
  });

  factory GroqUsage.fromJson(Map<String, dynamic> json) {
    return GroqUsage(
      promptTokens: json['prompt_tokens'] as int,
      completionTokens: json['completion_tokens'] as int,
      totalTokens: json['total_tokens'] as int,
    );
  }
}

class GroqModel {
  final String id;
  final String object;
  final int created;
  final String ownedBy;

  GroqModel({
    required this.id,
    required this.object,
    required this.created,
    required this.ownedBy,
  });

  factory GroqModel.fromJson(Map<String, dynamic> json) {
    return GroqModel(
      id: json['id'] as String,
      object: json['object'] as String,
      created: json['created'] as int,
      ownedBy: json['owned_by'] as String,
    );
  }
}
