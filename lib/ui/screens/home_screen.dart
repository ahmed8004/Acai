import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../services/wake_word_service.dart';
import '../../services/stt_service.dart';
import '../../services/tts_service.dart';
import '../../services/app_controller.dart';
import '../widgets/orb_widget.dart';
import '../widgets/command_log_widget.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _initializeServices();
  }

  Future<void> _initializeServices() async {
    await ref.read(sttServiceProvider).initialize();
    await ref.read(ttsServiceProvider).initialize();
    await ref.read(wakeWordServiceProvider).startListening();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appControllerProvider);
    final appNotifier = ref.read(appControllerProvider.notifier);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            _buildBackground(),
            _buildMainContent(appState, appNotifier),
            _buildStatusBar(appState),
            _buildControlButtons(appState, appNotifier),
          ],
        ),
      ),
    );
  }

  Widget _buildBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0, -0.3),
          radius: 1.5,
          colors: [
            AppTheme.primaryColor.withOpacity(0.15),
            Colors.transparent,
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent(AppState appState, AppController appNotifier) {
    return Column(
      children: [
        const SizedBox(height: 80),
        Expanded(
          flex: 3,
          child: Center(
            child: GestureDetector(
              onTap: () => _onOrbTap(appState, appNotifier),
              child: OrbWidget(
                state: _mapAppStateToOrbState(appState.state),
                size: 200,
                isListening: appState.isListening,
              ),
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                _buildStatusText(appState),
                const SizedBox(height: 16),
                CommandLogWidget(
                  commands: appState.recentCommands,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusText(AppState appState) {
    String statusText;
    Color statusColor;

    switch (appState.state) {
      case ACAIState.idle:
        statusText = 'Say "Hey AC" or tap the orb';
        statusColor = AppTheme.orbIdle;
      case ACAIState.listening:
        statusText = 'Listening...';
        statusColor = AppTheme.orbListening;
      case ACAIState.processing:
        statusText = 'Thinking...';
        statusColor = AppTheme.orbThinking;
      case ACAIState.speaking:
        statusText = 'Speaking...';
        statusColor = AppTheme.orbSpeaking;
      case ACAIState.executing:
        statusText = 'Executing...';
        statusColor = AppTheme.orbExecuting;
      case ACAIState.error:
        statusText = 'Error occurred';
        statusColor = AppTheme.orbError;
      case ACAIState.paused:
        statusText = 'Paused';
        statusColor = AppTheme.orbPaused;
      case ACAIState.stopped:
        statusText = 'Stopped';
        statusColor = AppTheme.orbStopped;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      child: Text(
        statusText,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: statusColor,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildStatusBar(AppState appState) {
    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStatusIndicator(
            'Wake Word',
            ref.watch(wakeWordServiceProvider).isListening,
          ),
          _buildStatusIndicator(
            'STT',
            ref.watch(sttServiceProvider).isListening,
          ),
          _buildStatusIndicator(
            'TTS',
            ref.watch(ttsServiceProvider).isSpeaking,
          ),
          IconButton(
            onPressed: () => _showSettings(),
            icon: const Icon(Icons.settings_outlined),
            color: Colors.white70,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(String label, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isActive 
            ? AppTheme.successColor.withOpacity(0.2) 
            : Colors.white10,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive 
              ? AppTheme.successColor.withOpacity(0.5) 
              : Colors.white24,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isActive ? AppTheme.successColor : Colors.white24,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isActive ? Colors.white : Colors.white54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButtons(AppState appState, AppController appNotifier) {
    return Positioned(
      bottom: 32,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildControlButton(
            icon: appState.state == ACAIState.paused 
                ? Icons.play_arrow 
                : Icons.pause,
            label: appState.state == ACAIState.paused ? 'Resume' : 'Pause',
            onTap: () => _togglePause(appNotifier),
          ),
          const SizedBox(width: 32),
          _buildControlButton(
            icon: Icons.mic,
            label: 'Listen',
            onTap: () => _startListening(appNotifier),
            isPrimary: true,
          ),
          const SizedBox(width: 32),
          _buildControlButton(
            icon: Icons.stop,
            label: 'Stop',
            onTap: () => _stopService(appNotifier),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: isPrimary ? 72 : 56,
            height: isPrimary ? 72 : 56,
            decoration: BoxDecoration(
              gradient: isPrimary 
                  ? const LinearGradient(
                      colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                    )
                  : null,
              color: isPrimary ? null : Colors.white10,
              shape: BoxShape.circle,
              border: Border.all(
                color: isPrimary 
                    ? Colors.transparent 
                    : Colors.white24,
              ),
              boxShadow: isPrimary 
                  ? [
                      BoxShadow(
                        color: AppTheme.primaryColor.withOpacity(0.4),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: isPrimary ? 32 : 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  void _onOrbTap(AppState state, AppController notifier) {
    if (state.state == ACAIState.idle || state.state == ACAIState.paused) {
      _startListening(notifier);
    } else if (state.state == ACAIState.listening) {
      notifier.stopListening();
    }
  }

  Future<void> _startListening(AppController notifier) async {
    await notifier.startListening();
  }

  void _togglePause(AppController notifier) {
    notifier.togglePause();
  }

  void _stopService(AppController notifier) {
    notifier.stopService();
  }

  void _showSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const Placeholder(),
      ),
    );
  }

  OrbState _mapAppStateToOrbState(ACAIState state) {
    switch (state) {
      case ACAIState.idle:
        return OrbState.idle;
      case ACAIState.listening:
        return OrbState.listening;
      case ACAIState.processing:
        return OrbState.thinking;
      case ACAIState.speaking:
        return OrbState.speaking;
      case ACAIState.executing:
        return OrbState.executing;
      case ACAIState.error:
        return OrbState.error;
      case ACAIState.paused:
        return OrbState.paused;
      case ACAIState.stopped:
        return OrbState.stopped;
    }
  }
}
