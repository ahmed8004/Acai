import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/constants/app_constants.dart';

final settingsServiceProvider = Provider<SettingsService>((ref) {
  return SettingsService();
});

class SettingsService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  static const String _keyGroqApiKey = 'groq_api_key';
  static const String _keySttLanguage = 'stt_language';
  static const String _keyTtsEngine = 'tts_engine';
  static const String _keyTtsRate = 'tts_rate';
  static const String _keyTtsPitch = 'tts_pitch';
  static const String _keyTtsVolume = 'tts_volume';
  static const String _keyWakeWordEnabled = 'wake_word_enabled';
  static const String _keyDarkMode = 'dark_mode';
  static const String _keyNotificationsEnabled = 'notifications_enabled';
  static const String _keyAccessibilityEnabled = 'accessibility_enabled';
  static const String _keyTermuxEnabled = 'termux_enabled';
  static const String _keyAutoStart = 'auto_start';
  static const String _keyAllSettings = 'all_settings';

  Future<void> saveGroqApiKey(String apiKey) async {
    await _secureStorage.write(key: _keyGroqApiKey, value: apiKey);
  }

  Future<String?> getGroqApiKey() async {
    return await _secureStorage.read(key: _keyGroqApiKey);
  }

  Future<void> deleteGroqApiKey() async {
    await _secureStorage.delete(key: _keyGroqApiKey);
  }

  Future<bool> hasGroqApiKey() async {
    final apiKey = await getGroqApiKey();
    return apiKey != null && apiKey.isNotEmpty;
  }

  Future<void> saveSetting(String key, dynamic value) async {
    final String stringValue;
    if (value is bool) {
      stringValue = value.toString();
    } else if (value is num) {
      stringValue = value.toString();
    } else {
      stringValue = value.toString();
    }
    await _secureStorage.write(key: key, value: stringValue);
  }

  Future<T?> getSetting<T>(String key, {T? defaultValue}) async {
    final value = await _secureStorage.read(key: key);
    if (value == null) {
      return defaultValue;
    }

    try {
      if (T == bool) {
        return (value.toLowerCase() == 'true') as T;
      } else if (T == int) {
        return int.parse(value) as T;
      } else if (T == double) {
        return double.parse(value) as T;
      } else if (T == String) {
        return value as T;
      }
    } catch (e) {
      return defaultValue;
    }
    return defaultValue;
  }

  Future<void> deleteSetting(String key) async {
    await _secureStorage.delete(key: key);
  }

  Future<void> deleteAllSettings() async {
    await _secureStorage.deleteAll();
  }

  Future<Map<String, dynamic>> getAllSettings() async {
    final all = await _secureStorage.readAll();
    final settings = <String, dynamic>{};

    for (final entry in all.entries) {
      final key = entry.key;
      final value = entry.value;

      if (key == _keyGroqApiKey) {
        settings[key] = value.isNotEmpty ? '***' : '';
      } else {
        settings[key] = value;
      }
    }

    return settings;
  }

  Future<AppSettings> loadSettings() async {
    return AppSettings(
      groqApiKey: await getGroqApiKey() ?? '',
      sttLanguage: await getSetting<String>(_keySttLanguage) ?? 'en-US',
      ttsEngine: await getSetting<String>(_keyTtsEngine) ?? 'system',
      ttsRate: await getSetting<double>(_keyTtsRate) ?? 1.0,
      ttsPitch: await getSetting<double>(_keyTtsPitch) ?? 1.0,
      ttsVolume: await getSetting<double>(_keyTtsVolume) ?? 1.0,
      wakeWordEnabled: await getSetting<bool>(_keyWakeWordEnabled) ?? true,
      darkMode: await getSetting<bool>(_keyDarkMode) ?? false,
      notificationsEnabled: await getSetting<bool>(_keyNotificationsEnabled) ?? true,
      accessibilityEnabled: await getSetting<bool>(_keyAccessibilityEnabled) ?? false,
      termuxEnabled: await getSetting<bool>(_keyTermuxEnabled) ?? false,
      autoStart: await getSetting<bool>(_keyAutoStart) ?? false,
    );
  }

  Future<void> saveSettings(AppSettings settings) async {
    await saveGroqApiKey(settings.groqApiKey);
    await saveSetting(_keySttLanguage, settings.sttLanguage);
    await saveSetting(_keyTtsEngine, settings.ttsEngine);
    await saveSetting(_keyTtsRate, settings.ttsRate);
    await saveSetting(_keyTtsPitch, settings.ttsPitch);
    await saveSetting(_keyTtsVolume, settings.ttsVolume);
    await saveSetting(_keyWakeWordEnabled, settings.wakeWordEnabled);
    await saveSetting(_keyDarkMode, settings.darkMode);
    await saveSetting(_keyNotificationsEnabled, settings.notificationsEnabled);
    await saveSetting(_keyAccessibilityEnabled, settings.accessibilityEnabled);
    await saveSetting(_keyTermuxEnabled, settings.termuxEnabled);
    await saveSetting(_keyAutoStart, settings.autoStart);
  }

  Future<void> resetToDefaults() async {
    await deleteAllSettings();
    await saveSettings(AppSettings.defaultSettings());
  }
}

class AppSettings {
  final String groqApiKey;
  final String sttLanguage;
  final String ttsEngine;
  final double ttsRate;
  final double ttsPitch;
  final double ttsVolume;
  final bool wakeWordEnabled;
  final bool darkMode;
  final bool notificationsEnabled;
  final bool accessibilityEnabled;
  final bool termuxEnabled;
  final bool autoStart;

  AppSettings({
    required this.groqApiKey,
    required this.sttLanguage,
    required this.ttsEngine,
    required this.ttsRate,
    required this.ttsPitch,
    required this.ttsVolume,
    required this.wakeWordEnabled,
    required this.darkMode,
    required this.notificationsEnabled,
    required this.accessibilityEnabled,
    required this.termuxEnabled,
    required this.autoStart,
  });

  factory AppSettings.defaultSettings() {
    return AppSettings(
      groqApiKey: '',
      sttLanguage: 'en-US',
      ttsEngine: 'system',
      ttsRate: 1.0,
      ttsPitch: 1.0,
      ttsVolume: 1.0,
      wakeWordEnabled: true,
      darkMode: false,
      notificationsEnabled: true,
      accessibilityEnabled: false,
      termuxEnabled: false,
      autoStart: false,
    );
  }

  AppSettings copyWith({
    String? groqApiKey,
    String? sttLanguage,
    String? ttsEngine,
    double? ttsRate,
    double? ttsPitch,
    double? ttsVolume,
    bool? wakeWordEnabled,
    bool? darkMode,
    bool? notificationsEnabled,
    bool? accessibilityEnabled,
    bool? termuxEnabled,
    bool? autoStart,
  }) {
    return AppSettings(
      groqApiKey: groqApiKey ?? this.groqApiKey,
      sttLanguage: sttLanguage ?? this.sttLanguage,
      ttsEngine: ttsEngine ?? this.ttsEngine,
      ttsRate: ttsRate ?? this.ttsRate,
      ttsPitch: ttsPitch ?? this.ttsPitch,
      ttsVolume: ttsVolume ?? this.ttsVolume,
      wakeWordEnabled: wakeWordEnabled ?? this.wakeWordEnabled,
      darkMode: darkMode ?? this.darkMode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      accessibilityEnabled: accessibilityEnabled ?? this.accessibilityEnabled,
      termuxEnabled: termuxEnabled ?? this.termuxEnabled,
      autoStart: autoStart ?? this.autoStart,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'groqApiKey': groqApiKey.isNotEmpty ? '***' : '',
      'sttLanguage': sttLanguage,
      'ttsEngine': ttsEngine,
      'ttsRate': ttsRate,
      'ttsPitch': ttsPitch,
      'ttsVolume': ttsVolume,
      'wakeWordEnabled': wakeWordEnabled,
      'darkMode': darkMode,
      'notificationsEnabled': notificationsEnabled,
      'accessibilityEnabled': accessibilityEnabled,
      'termuxEnabled': termuxEnabled,
      'autoStart': autoStart,
    };
  }
}
