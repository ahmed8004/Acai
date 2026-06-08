import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final ttsServiceProvider = Provider<TTSService>((ref) {
  return TTSService();
});

class TTSService {
  static const MethodChannel _channel = MethodChannel('com.ac.ai/tts');
  
  final FlutterTts _flutterTts = FlutterTts();
  
  final StreamController<bool> _speakingController = StreamController<bool>.broadcast();
  final StreamController<double> _progressController = StreamController<double>.broadcast();
  
  Stream<bool> get onSpeakingStateChanged => _speakingController.stream;
  Stream<double> get onProgress => _progressController.stream;

  bool _isSpeaking = false;
  bool get isSpeaking => _isSpeaking;
  
  bool _isInitialized = false;
  
  String _currentLanguage = 'en-US';
  String get currentLanguage => _currentLanguage;
  
  double _speechRate = 1.0;
  double get speechRate => _speechRate;
  
  double _pitch = 1.0;
  double get pitch => _pitch;
  
  double _volume = 1.0;
  double get volume => _volume;

  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }

    _flutterTts.setStartHandler(() {
      _isSpeaking = true;
      _speakingController.add(true);
    });

    _flutterTts.setCompletionHandler(() {
      _isSpeaking = false;
      _speakingController.add(false);
    });

    _flutterTts.setErrorHandler((message) {
      print('TTS Error: $message');
      _isSpeaking = false;
      _speakingController.add(false);
    });

    _flutterTts.setCancelHandler(() {
      _isSpeaking = false;
      _speakingController.add(false);
    });

    _flutterTts.setProgressHandler((text, start, end, word) {
      final progress = end / text.length;
      _progressController.add(progress);
    });

    await _flutterTts.setLanguage(_currentLanguage);
    await _flutterTts.setSpeechRate(_speechRate);
    await _flutterTts.setPitch(_pitch);
    await _flutterTts.setVolume(_volume);
    
    _isInitialized = true;
  }

  Future<bool> speak(String text) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (text.isEmpty) {
      return false;
    }

    try {
      await _flutterTts.speak(text);
      return true;
    } catch (e) {
      print('Failed to speak: $e');
      return false;
    }
  }

  Future<bool> stop() async {
    if (!_isInitialized) {
      return true;
    }

    try {
      await _flutterTts.stop();
      _isSpeaking = false;
      _speakingController.add(false);
      return true;
    } catch (e) {
      print('Failed to stop TTS: $e');
      return false;
    }
  }

  Future<bool> pause() async {
    if (!_isInitialized) {
      return false;
    }

    try {
      await _flutterTts.pause();
      return true;
    } catch (e) {
      print('Failed to pause TTS: $e');
      return false;
    }
  }

  Future<bool> setLanguage(String language) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final result = await _flutterTts.setLanguage(_mapLanguage(language));
      if (result == 1) {
        _currentLanguage = language;
        return true;
      }
      return false;
    } catch (e) {
      print('Failed to set language: $e');
      return false;
    }
  }

  Future<bool> setSpeechRate(double rate) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      _speechRate = rate.clamp(0.0, 2.0);
      await _flutterTts.setSpeechRate(_speechRate);
      return true;
    } catch (e) {
      print('Failed to set speech rate: $e');
      return false;
    }
  }

  Future<bool> setPitch(double pitch) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      _pitch = pitch.clamp(0.5, 2.0);
      await _flutterTts.setPitch(_pitch);
      return true;
    } catch (e) {
      print('Failed to set pitch: $e');
      return false;
    }
  }

  Future<bool> setVolume(double volume) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      _volume = volume.clamp(0.0, 1.0);
      await _flutterTts.setVolume(_volume);
      return true;
    } catch (e) {
      print('Failed to set volume: $e');
      return false;
    }
  }

  Future<List<dynamic>> getEngines() async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      return await _flutterTts.getEngines;
    } catch (e) {
      print('Failed to get engines: $e');
      return [];
    }
  }

  Future<bool> setEngine(String engine) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      await _flutterTts.setEngine(engine);
      return true;
    } catch (e) {
      print('Failed to set engine: $e');
      return false;
    }
  }

  Future<List<dynamic>> getLanguages() async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      return await _flutterTts.getLanguages;
    } catch (e) {
      print('Failed to get languages: $e');
      return ['en-US', 'hi-IN', 'en-IN'];
    }
  }

  Future<bool> isLanguageAvailable(String language) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final result = await _flutterTts.isLanguageAvailable(_mapLanguage(language));
      return result == 1;
    } catch (e) {
      print('Failed to check language availability: $e');
      return false;
    }
  }

  String _mapLanguage(String language) {
    switch (language.toLowerCase()) {
      case 'en':
      case 'english':
      case 'en-us':
        return 'en-US';
      case 'hi':
      case 'hindi':
      case 'hi-in':
        return 'hi-IN';
      case 'en-in':
      case 'hinglish':
        return 'en-IN';
      default:
        return 'en-US';
    }
  }

  void dispose() {
    _flutterTts.stop();
    _speakingController.close();
    _progressController.close();
  }
}
