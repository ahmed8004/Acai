import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_constants.dart';
import 'stt_service.dart';
import 'tts_service.dart';
import 'wake_word_service.dart';
import 'settings_service.dart';

final appControllerProvider = StateNotifierProvider<AppController, AppState>(
  (ref) => AppController(ref),
);

class AppController extends StateNotifier<AppState> {
  final Ref _ref;
  StreamSubscription<String>? _sttSubscription;
  StreamSubscription<String>? _wakeWordSubscription;

  AppController(this._ref) : super(AppState.initial()) {
    _initialize();
  }

  Future<void> _initialize() async {
    await _setupListeners();
  }

  Future<void> _setupListeners() async {
    final sttService = _ref.read(sttServiceProvider);
    final wakeWordService = _ref.read(wakeWordServiceProvider);

    _sttSubscription = sttService.onFinalResult.listen(_onSpeechResult);
    _wakeWordSubscription = wakeWordService.onWakeWordDetected.listen(
      (wakeWord) => _onWakeWordDetected(wakeWord),
    );
  }

  void _onWakeWordDetected(String wakeWord) {
    if (state.state == ACAIState.idle || state.state == ACAIState.paused) {
      _ref.read(ttsServiceProvider).speak('Yes?');
      startListening();
    }
  }

  void _onSpeechResult(String text) {
    if (text.isNotEmpty) {
      _processCommand(text);
    }
  }

  Future<void> _processCommand(String command) async {
    state = state.copyWith(
      state: ACAIState.processing,
      currentCommand: command,
    );

    await _ref.read(ttsServiceProvider).stop();

    if (_isEmergencyStop(command)) {
      await _handleEmergencyStop();
      return;
    }

    if (_isStopCommand(command)) {
      await _handleStopCommand();
      return;
    }

    if (_isPauseCommand(command)) {
      await _handlePauseCommand();
      return;
    }

    if (_isDangerousCommand(command)) {
      await _handleDangerousCommand(command);
      return;
    }

    state = state.copyWith(
      state: ACAIState.executing,
      recentCommands: [...state.recentCommands, command],
    );

    final response = await _generateResponse(command);

    state = state.copyWith(
      state: ACAIState.speaking,
      lastResponse: response,
    );

    await _ref.read(ttsServiceProvider).speak(response);

    state = state.copyWith(state: ACAIState.idle);
  }

  bool _isEmergencyStop(String command) {
    final lower = command.toLowerCase();
    return lower.contains('emergency stop') || 
           lower.contains('ac emergency stop') ||
           lower.contains('abort');
  }

  bool _isStopCommand(String command) {
    final lower = command.toLowerCase();
    return lower == 'stop' || 
           lower == 'ac stop' ||
           lower == 'hey ac stop' ||
           lower == 'okay ac stop';
  }

  bool _isPauseCommand(String command) {
    final lower = command.toLowerCase();
    return lower == 'pause' || 
           lower == 'ac pause' ||
           lower == 'wait';
  }

  bool _isDangerousCommand(String command) {
    final lower = command.toLowerCase();
    return AppConstants.dangerousCommands.any((dangerous) => 
      lower.contains(dangerous.toLowerCase()));
  }

  Future<void> _handleEmergencyStop() async {
    await _ref.read(ttsServiceProvider).speak('Emergency stop triggered');
    await stopService();
  }

  Future<void> _handleStopCommand() async {
    await _ref.read(ttsServiceProvider).speak('Stopping AC AI');
    await stopService();
  }

  Future<void> _handlePauseCommand() async {
    await _ref.read(ttsServiceProvider).speak('Pausing AC AI');
    await togglePause();
  }

  Future<void> _handleDangerousCommand(String command) async {
    state = state.copyWith(state: ACAIState.executing);
    
    await _ref.read(ttsServiceProvider).speak(
      'This command involves dangerous operation: $command. '
      'Please confirm by saying "yes confirm" to proceed.'
    );
    
    state = state.copyWith(
      state: ACAIState.listening,
      pendingConfirmation: command,
    );
  }

  Future<String> _generateResponse(String command) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    return 'I heard: "$command". I am processing your request.';
  }

  Future<void> startListening() async {
    final sttService = _ref.read(sttServiceProvider);
    
    if (await sttService.startListening()) {
      state = state.copyWith(
        state: ACAIState.listening,
        isListening: true,
      );
    }
  }

  Future<void> stopListening() async {
    final sttService = _ref.read(sttServiceProvider);
    await sttService.stopListening();
    
    state = state.copyWith(
      state: ACAIState.idle,
      isListening: false,
    );
  }

  Future<void> togglePause() async {
    final sttService = _ref.read(sttServiceProvider);
    final wakeWordService = _ref.read(wakeWordServiceProvider);
    
    if (state.state == ACAIState.paused) {
      await wakeWordService.startListening();
      state = state.copyWith(
        state: ACAIState.idle,
        isPaused: false,
      );
    } else {
      await sttService.stopListening();
      await wakeWordService.stopListening();
      state = state.copyWith(
        state: ACAIState.paused,
        isPaused: true,
        isListening: false,
      );
    }
  }

  Future<void> stopService() async {
    final sttService = _ref.read(sttServiceProvider);
    final wakeWordService = _ref.read(wakeWordServiceProvider);
    
    await sttService.stopListening();
    await wakeWordService.stopListening();
    
    state = state.copyWith(
      state: ACAIState.stopped,
      isListening: false,
      isPaused: false,
    );
  }

  Future<void> startService() async {
    final wakeWordService = _ref.read(wakeWordServiceProvider);
    await wakeWordService.startListening();
    
    state = state.copyWith(
      state: ACAIState.idle,
      isListening: false,
      isPaused: false,
    );
  }

  void addToCommandHistory(String command) {
    state = state.copyWith(
      recentCommands: [...state.recentCommands, command],
    );
  }

  void clearCommandHistory() {
    state = state.copyWith(recentCommands: []);
  }

  @override
  void dispose() {
    _sttSubscription?.cancel();
    _wakeWordSubscription?.cancel();
    super.dispose();
  }
}

class AppState {
  final ACAIState state;
  final bool isListening;
  final bool isPaused;
  final String? currentCommand;
  final String? lastResponse;
  final List<String> recentCommands;
  final String? pendingConfirmation;

  AppState({
    required this.state,
    required this.isListening,
    required this.isPaused,
    this.currentCommand,
    this.lastResponse,
    required this.recentCommands,
    this.pendingConfirmation,
  });

  factory AppState.initial() {
    return AppState(
      state: ACAIState.idle,
      isListening: false,
      isPaused: false,
      recentCommands: [],
    );
  }

  AppState copyWith({
    ACAIState? state,
    bool? isListening,
    bool? isPaused,
    String? currentCommand,
    String? lastResponse,
    List<String>? recentCommands,
    String? pendingConfirmation,
  }) {
    return AppState(
      state: state ?? this.state,
      isListening: isListening ?? this.isListening,
      isPaused: isPaused ?? this.isPaused,
      currentCommand: currentCommand ?? this.currentCommand,
      lastResponse: lastResponse ?? this.lastResponse,
      recentCommands: recentCommands ?? this.recentCommands,
      pendingConfirmation: pendingConfirmation ?? this.pendingConfirmation,
    );
  }
}

enum ACAIState {
  idle,
  listening,
  processing,
  speaking,
  executing,
  error,
  paused,
  stopped,
}
