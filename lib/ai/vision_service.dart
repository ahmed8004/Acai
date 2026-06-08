import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:path_provider/path_provider.dart';
import 'groq_service.dart';

final visionServiceProvider = Provider<VisionService>((ref) {
  final groqService = ref.read(groqServiceProvider);
  return VisionService(groqService);
});

class VisionService {
  final GroqService _groqService;
  final TextRecognizer _textRecognizer = TextRecognizer();
  final ImageLabeler _imageLabeler = ImageLabeler(
    options: ImageLabelerOptions(confidenceThreshold: 0.5),
  );
  late ObjectDetector _objectDetector;

  VisionService(this._groqService) {
    _objectDetector = ObjectDetector(
      options: ObjectDetectorOptions(
        mode: DetectionMode.single,
        classifyObjects: true,
        trackMultipleObjects: true,
      ),
    );
  }

  Future<ImageAnalysisResult> analyzeImage(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);
      
      final recognizedText = await _performOCR(imageFile);
      final labels = await _detectLabels(imageFile);
      final objects = await _detectObjects(imageFile);
      
      final sceneDescription = await _generateSceneDescription(
        labels: labels,
        objects: objects,
        text: recognizedText,
        base64Image: base64Image,
      );
      
      return ImageAnalysisResult(
        imagePath: imageFile.path,
        ocrText: recognizedText,
        labels: labels,
        detectedObjects: objects,
        sceneDescription: sceneDescription,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      return ImageAnalysisResult(
        imagePath: imageFile.path,
        ocrText: '',
        labels: [],
        detectedObjects: [],
        sceneDescription: 'Error analyzing image: $e',
        timestamp: DateTime.now(),
        error: e.toString(),
      );
    }
  }

  Future<String> _performOCR(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      return recognizedText.text;
    } catch (e) {
      print('OCR error: $e');
      return '';
    }
  }

  Future<List<ImageLabel>> _detectLabels(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final labels = await _imageLabeler.processImage(inputImage);
      return labels;
    } catch (e) {
      print('Label detection error: $e');
      return [];
    }
  }

  Future<List<DetectedObject>> _detectObjects(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final objects = await _objectDetector.processImage(inputImage);
      return objects;
    } catch (e) {
      print('Object detection error: $e');
      return [];
    }
  }

  Future<String> _generateSceneDescription({
    required List<ImageLabel> labels,
    required List<DetectedObject> objects,
    required String text,
    required String base64Image,
  }) async {
    try {
      final labelTexts = labels.map((l) => '${l.label} (${(l.confidence * 100).toStringAsFixed(0)}%)').join(', ');
      final objectTexts = objects.expand((o) => o.labels).map((l) => l.text).join(', ');
      
      final prompt = '''Analyze this image and provide a detailed description.
      
Detected labels: $labelTexts
Detected objects: $objectTexts
OCR text found: ${text.isNotEmpty ? text : 'None'}

Provide a comprehensive description of what's in the image.''';  

      final response = await _groqService.analyzeImage(
        imageBase64: base64Image,
        prompt: prompt,
      );
      
      return response.content;
    } catch (e) {
      print('Scene description error: $e');
      return 'Image contains: ${labels.map((l) => l.label).join(', ')}';
    }
  }

  Future<String> extractTextFromImage(File imageFile) async {
    return await _performOCR(imageFile);
  }

  Future<List<String>> getImageLabels(File imageFile) async {
    final labels = await _detectLabels(imageFile);
    return labels.map((l) => l.label).toList();
  }

  Future<List<String>> getDetectedObjects(File imageFile) async {
    final objects = await _detectObjects(imageFile);
    return objects.expand((o) => o.labels.map((l) => l.text)).toList();
  }

  Future<File?> captureImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      return null;
    } catch (e) {
      print('Capture error: $e');
      return null;
    }
  }

  Future<File?> pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      return null;
    } catch (e) {
      print('Pick image error: $e');
      return null;
    }
  }

  Future<String> describeWorkshopScene(File imageFile) async {
    try {
      final result = await analyzeImage(imageFile);
      
      final response = await _groqService.chatCompletion(
        messages: [
          GroqMessage.system('''You are a workshop assistant. Analyze the image and provide specific details about tools, components, and any technical elements you can identify. Be practical and helpful.'''),
          GroqMessage.user('''Analyze this workshop/technical image:
Scene: ${result.sceneDescription}
Objects detected: ${result.detectedObjects.map((o) => o.labels.map((l) => l.text).join(', ')).join('; ')}
Text visible: ${result.ocrText}'''),
        ],
        temperature: 0.5,
        maxTokens: 500,
      );
      
      return response.content;
    } catch (e) {
      return 'Workshop scene analysis failed: $e';
    }
  }

  void dispose() {
    _textRecognizer.close();
    _imageLabeler.close();
    _objectDetector.close();
  }
}

class ImageAnalysisResult {
  final String imagePath;
  final String ocrText;
  final List<ImageLabel> labels;
  final List<DetectedObject> detectedObjects;
  final String sceneDescription;
  final DateTime timestamp;
  final String? error;

  ImageAnalysisResult({
    required this.imagePath,
    required this.ocrText,
    required this.labels,
    required this.detectedObjects,
    required this.sceneDescription,
    required this.timestamp,
    this.error,
  });

  bool get hasError => error != null;
  bool get hasText => ocrText.isNotEmpty;
  bool get hasObjects => detectedObjects.isNotEmpty || labels.isNotEmpty;

  List<String> get topLabels => labels
      .where((l) => l.confidence > 0.7)
      .map((l) => l.label)
      .take(5)
      .toList();

  Map<String, dynamic> toJson() {
    return {
      'imagePath': imagePath,
      'ocrText': ocrText,
      'labels': labels.map((l) => {
        'label': l.label,
        'confidence': l.confidence,
        'index': l.index,
      }).toList(),
      'detectedObjects': detectedObjects.map((o) => {
        'boundingBox': {
          'left': o.boundingBox.left,
          'top': o.boundingBox.top,
          'right': o.boundingBox.right,
          'bottom': o.boundingBox.bottom,
        },
        'labels': o.labels.map((l) => {
          'text': l.text,
          'confidence': l.confidence,
          'index': l.index,
        }).toList(),
      }).toList(),
      'sceneDescription': sceneDescription,
      'timestamp': timestamp.toIso8601String(),
      'error': error,
    };
  }
}
