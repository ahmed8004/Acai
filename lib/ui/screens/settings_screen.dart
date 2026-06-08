import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import '../services/settings_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _groqApiKeyController = TextEditingController();
  bool _isTestingConnection = false;
  String _connectionStatus = '';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await ref.read(settingsServiceProvider).loadSettings();
    _groqApiKeyController.text = settings.groqApiKey;
    setState(() {});
  }

  @override
  void dispose() {
    _groqApiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: settingsAsync.when(
        data: (settings) => _buildSettingsList(settings),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildSettingsList(AppSettings settings) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionTitle('Voice'),
        _buildGroqApiKeySection(),
        const SizedBox(height: 8),
        _buildVoiceLanguageTile(settings),
        _buildTTSEngineTile(settings),
        
        _buildSectionTitle('Appearance'),
        _buildDarkModeTile(settings),
        
        _buildSectionTitle('Automation'),
        _buildWakeWordTile(settings),
        _buildAccessibilityTile(settings),
        _buildTermuxTile(settings),
        
        _buildSectionTitle('Advanced'),
        _buildAutoStartTile(settings),
        _buildNotificationsTile(settings),
        
        const SizedBox(height: 32),
        _buildResetButton(),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppTheme.primaryColor,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildGroqApiKeySection() {
    return Card(
      color: AppTheme.darkCard,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Groq API Key',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _groqApiKeyController,
              obscureText: true,
              decoration: InputDecoration(
                hintText: 'Enter your Groq API key',
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.save),
                      onPressed: _saveGroqApiKey,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: _deleteGroqApiKey,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _isTestingConnection ? null : _testConnection,
                  child: _isTestingConnection
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Test Connection'),
                ),
                const SizedBox(width: 16),
                Text(
                  _connectionStatus,
                  style: TextStyle(
                    color: _connectionStatus.contains('Success')
                        ? AppTheme.successColor
                        : _connectionStatus.contains('Failed')
                            ? AppTheme.errorColor
                            : Colors.white70,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoiceLanguageTile(AppSettings settings) {
    return ListTile(
      leading: const Icon(Icons.language, color: AppTheme.primaryColor),
      title: const Text('Speech Language'),
      subtitle: Text(settings.sttLanguage),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showLanguagePicker(settings),
    );
  }

  Widget _buildTTSEngineTile(AppSettings settings) {
    return ListTile(
      leading: const Icon(Icons.record_voice_over, color: AppTheme.primaryColor),
      title: const Text('TTS Engine'),
      subtitle: Text(settings.ttsEngine),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showTTSEnginePicker(settings),
    );
  }

  Widget _buildDarkModeTile(AppSettings settings) {
    return SwitchListTile(
      secondary: const Icon(Icons.dark_mode, color: AppTheme.primaryColor),
      title: const Text('Dark Mode'),
      subtitle: const Text('Use dark theme throughout the app'),
      value: settings.darkMode,
      onChanged: (value) => _updateSetting(
        settings.copyWith(darkMode: value),
      ),
    );
  }

  Widget _buildWakeWordTile(AppSettings settings) {
    return SwitchListTile(
      secondary: const Icon(Icons.mic, color: AppTheme.primaryColor),
      title: const Text('Wake Word'),
      subtitle: const Text('Listen for "Hey AC"'),
      value: settings.wakeWordEnabled,
      onChanged: (value) => _updateSetting(
        settings.copyWith(wakeWordEnabled: value),
      ),
    );
  }

  Widget _buildAccessibilityTile(AppSettings settings) {
    return SwitchListTile(
      secondary: const Icon(Icons.accessibility, color: AppTheme.primaryColor),
      title: const Text('Accessibility'),
      subtitle: const Text('Enable app automation'),
      value: settings.accessibilityEnabled,
      onChanged: (value) => _updateSetting(
        settings.copyWith(accessibilityEnabled: value),
      ),
    );
  }

  Widget _buildTermuxTile(AppSettings settings) {
    return SwitchListTile(
      secondary: const Icon(Icons.terminal, color: AppTheme.primaryColor),
      title: const Text('Termux'),
      subtitle: const Text('Enable Termux integration'),
      value: settings.termuxEnabled,
      onChanged: (value) => _updateSetting(
        settings.copyWith(termuxEnabled: value),
      ),
    );
  }

  Widget _buildAutoStartTile(AppSettings settings) {
    return SwitchListTile(
      secondary: const Icon(Icons.play_arrow, color: AppTheme.primaryColor),
      title: const Text('Auto Start'),
      subtitle: const Text('Start AC AI on boot'),
      value: settings.autoStart,
      onChanged: (value) => _updateSetting(
        settings.copyWith(autoStart: value),
      ),
    );
  }

  Widget _buildNotificationsTile(AppSettings settings) {
    return SwitchListTile(
      secondary: const Icon(Icons.notifications, color: AppTheme.primaryColor),
      title: const Text('Notifications'),
      subtitle: const Text('Read and reply to notifications'),
      value: settings.notificationsEnabled,
      onChanged: (value) => _updateSetting(
        settings.copyWith(notificationsEnabled: value),
      ),
    );
  }

  Widget _buildResetButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ElevatedButton.icon(
        onPressed: _resetSettings,
        icon: const Icon(Icons.restore),
        label: const Text('Reset to Defaults'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.errorColor.withOpacity(0.2),
          foregroundColor: AppTheme.errorColor,
        ),
      ),
    );
  }

  Future<void> _saveGroqApiKey() async {
    final apiKey = _groqApiKeyController.text.trim();
    if (apiKey.isNotEmpty) {
      await ref.read(settingsServiceProvider).saveGroqApiKey(apiKey);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('API Key saved')),
        );
      }
    }
  }

  Future<void> _deleteGroqApiKey() async {
    await ref.read(settingsServiceProvider).deleteGroqApiKey();
    _groqApiKeyController.clear();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('API Key deleted')),
      );
    }
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTestingConnection = true;
      _connectionStatus = '';
    });

    final apiKey = _groqApiKeyController.text.trim();
    if (apiKey.isEmpty) {
      setState(() {
        _isTestingConnection = false;
        _connectionStatus = 'Please enter API key';
      });
      return;
    }

    final groqService = ref.read(groqServiceProvider);
    final success = await groqService.testConnection(apiKey);

    setState(() {
      _isTestingConnection = false;
      _connectionStatus = success ? 'Success!' : 'Failed';
    });
  }

  Future<void> _updateSetting(AppSettings newSettings) async {
    await ref.read(settingsServiceProvider).saveSettings(newSettings);
    ref.invalidate(settingsProvider);
  }

  Future<void> _resetSettings() async {
    await ref.read(settingsServiceProvider).resetToDefaults();
    ref.invalidate(settingsProvider);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings reset to defaults')),
      );
    }
  }

  void _showLanguagePicker(AppSettings settings) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('English (US)'),
              trailing: settings.sttLanguage == 'en-US'
                  ? const Icon(Icons.check, color: AppTheme.primaryColor)
                  : null,
              onTap: () {
                _updateSetting(settings.copyWith(sttLanguage: 'en-US'));
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Hindi'),
              trailing: settings.sttLanguage == 'hi-IN'
                  ? const Icon(Icons.check, color: AppTheme.primaryColor)
                  : null,
              onTap: () {
                _updateSetting(settings.copyWith(sttLanguage: 'hi-IN'));
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('English (India)'),
              trailing: settings.sttLanguage == 'en-IN'
                  ? const Icon(Icons.check, color: AppTheme.primaryColor)
                  : null,
              onTap: () {
                _updateSetting(settings.copyWith(sttLanguage: 'en-IN'));
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showTTSEnginePicker(AppSettings settings) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('System Default'),
              trailing: settings.ttsEngine == 'system'
                  ? const Icon(Icons.check, color: AppTheme.primaryColor)
                  : null,
              onTap: () {
                _updateSetting(settings.copyWith(ttsEngine: 'system'));
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Piper TTS'),
              trailing: settings.ttsEngine == 'piper'
                  ? const Icon(Icons.check, color: AppTheme.primaryColor)
                  : null,
              onTap: () {
                _updateSetting(settings.copyWith(ttsEngine: 'piper'));
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

final settingsProvider = FutureProvider<AppSettings>((ref) async {
  return await ref.read(settingsServiceProvider).loadSettings();
});
