class AppConstants {
  static const String appName = 'AC AI';
  static const String appVersion = '1.0.0';
  static const String appBuild = '1';
  
  static const String groqBaseUrl = 'https://api.groq.com/openai/v1';
  static const String groqApiKey = '';
  
  static const List<String> supportedLanguages = [
    'en-US',
    'en-IN',
    'hi-IN',
  ];
  
  static const String defaultWakeWord = 'hey_ac';
  static const List<String> wakeWords = [
    'hey_ac',
    'ac',
    'okay_ac',
  ];
  
  static const String databaseName = 'ac_ai.db';
  static const int databaseVersion = 1;
  
  static const String secureStorageKeyGroq = 'groq_api_key';
  static const String secureStorageKeySettings = 'ac_ai_settings';
  
  static const int maxConversationHistory = 100;
  static const int maxMemoryEntries = 1000;
  
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration sttTimeout = Duration(seconds: 60);
  static const Duration ttsTimeout = Duration(seconds: 30);
  
  static const List<String> dangerousCommands = [
    'format',
    'wipe',
    'delete',
    'factory reset',
    'hard reset',
    'erase',
    'rm -rf',
    'dd if',
    'mkfs',
  ];
  
  static const String foregroundServiceChannelId = 'ac_ai_foreground';
  static const int foregroundServiceNotificationId = 1001;
}
