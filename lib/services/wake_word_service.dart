import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final wakeWordServiceProvider = Provider<WakeWordService>((ref) {
  return WakeWordService();
});

class WakeWordService {
  static const MethodChannel _channel = MethodChannel('com.ac.ai/wakeword');
  static const EventChannel _eventChannel = EventChannel('com.ac.ai/wakeword_events');

  final StreamController<String> _wakeWordController = StreamController<String>.broadcast();
  Stream<String> get onWakeWordDetected => _wakeWordController.stream;

  bool _isListening = false;
  bool get isListening => _isListening;

  WakeWordService() {
    _setupEventListener();
  }

  void _setupEventListener() {
    _eventChannel.receiveBroadcastStream().listen(
      (dynamic event) {
        if (event is String) {
          _wakeWordController.add(event);
        }
      },
      onError: (dynamic error) {
        print('Wake word event error: $error');
      },
    );
  }

  Future<bool> startListening() async {
    try {
      final result = await _channel.invokeMethod<bool>('startWakeWord');
      _isListening = result ?? false;
      return _isListening;
    } on PlatformException catch (e) {
      print('Failed to start wake word: ${e.message}');
      return false;
    }
  }

  Future<bool> stopListening() async {
    try {
      final result = await _channel.invokeMethod<bool>('stopWakeWord');
      _isListening = !(result ?? false);
      return !_isListening;
    } on PlatformException catch (e) {
      print('Failed to stop wake word: ${e.message}');
      return false;
    }
  }

  Future<bool> isWakeWordListening() async {
    try {
      final result = await _channel.invokeMethod<bool>('isListening');
      _isListening = result ?? false;
      return _isListening;
    } on PlatformException catch (e) {
      print('Failed to check wake word status: ${e.message}');
      return false;
    }
  }

  void dispose() {
    _wakeWordController.close();
  }
}
