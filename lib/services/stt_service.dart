import 'dart:async';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final sttServiceProvider = Provider<STTService>((ref) {
  return STTService();
});

class STTService {
  static const MethodChannel _channel = MethodChannel('com.ac.ai/stt');
  
  final SpeechToText _speech = SpeechToText();
  
  final StreamController<String> _partialResultsController = StreamController<String>.broadcast();
  final StreamController<String> _finalResultController = StreamController<String>.broadcast();
  final StreamController<bool> _listeningController = StreamController<bool>.broadcast();
  
  Stream<String> get onPartialResult => _partialResultsController.stream;
  Stream<String> get onFinalResult => _finalResultController.stream;
  Stream<bool> get onListeningStateChanged => _listeningController.stream;

  bool _isListening = false;
  bool get isListening => _isListening;
  
  bool _isAvailable = false;
  bool get isAvailable => _isAvailable;
  
  String _currentLocale = 'en-US';
  String get currentLocale => _currentLocale;

  Future<void> initialize() async {
    _isAvailable = await _speech.initialize(
      onError: (error) {
        print('STT Error: $error');
        _listeningController.add(false);
        _isListening = false;
      },
      onStatus: (status) {
        if (status == 'listening') {
          _listeningController.add(true);
          _isListening = true;
        } else if (status == 'notListening') {
          _listeningController.add(false);
          _isListening = false;
        }
      },
    );
  }

  Future<bool> startListening({
    String language = 'en-US',
    Duration listenFor = const Duration(seconds: 30),
    Duration pauseFor = const Duration(seconds: 3),
    bool partialResults = true,
  }) async {
    if (!_isAvailable) {
      await initialize();
    }

    if (!_isAvailable) {
      return false;
    }

    if (_isListening) {
      await stopListening();
    }

    _currentLocale = language;

    try {
      await _speech.listen(
        onResult: (result) {
          if (result.finalResult) {
            _finalResultController.add(result.recognizedWords);
            _isListening = false;
            _listeningController.add(false);
          } else {
            _partialResultsController.add(result.recognizedWords);
          }
        },
        listenFor: listenFor,
        pauseFor: pauseFor,
        partialResults: partialResults,
        localeId: _getLocaleId(language),
        onSoundLevelChange: (level) {
        },
        cancelOnError: true,
        listenMode: ListenMode.confirmation,
      );
      
      _isListening = true;
      _listeningController.add(true);
      return true;
    } catch (e) {
      print('Failed to start listening: $e');
      return false;
    }
  }

  Future<bool> stopListening() async {
    if (!_isListening) {
      return true;
    }

    try {
      await _speech.stop();
      _isListening = false;
      _listeningController.add(false);
      return true;
    } catch (e) {
      print('Failed to stop listening: $e');
      return false;
    }
  }

  Future<bool> cancelListening() async {
    if (!_isListening) {
      return true;
    }

    try {
      await _speech.cancel();
      _isListening = false;
      _listeningController.add(false);
      return true;
    } catch (e) {
      print('Failed to cancel listening: $e');
      return false;
    }
  }

  String _getLocaleId(String language) {
    switch (language.toLowerCase()) {
      case 'en':
      case 'english':
      case 'en-us':
        return 'en_US';
      case 'hi':
      case 'hindi':
      case 'hi-in':
        return 'hi_IN';
      case 'en-in':
      case 'hinglish':
        return 'en_IN';
      default:
        return 'en_US';
    }
  }

  Future<List<String>> getAvailableLanguages() async {
    try {
      final locales = await _speech.locales();
      return locales.map((locale) => locale.localeId).toList();
    } catch (e) {
      return ['en_US', 'hi_IN', 'en_IN'];
    }
  }

  Future<bool> setLanguage(String language) async {
    _currentLocale = language;
    return true;
  }

  void dispose() {
    _speech.cancel();
    _partialResultsController.close();
    _finalResultController.close();
    _listeningController.close();
  }
}
