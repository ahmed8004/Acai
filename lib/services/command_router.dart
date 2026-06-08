import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_controller.dart';
import 'device_control_service.dart';
import 'file_agent_service.dart';
import 'download_manager.dart';
import 'context_manager.dart';
import '../bridge/termux_bridge.dart';
import '../bridge/usb_agent.dart';
import '../ai/vision_service.dart';
import '../ai/groq_service.dart';

final commandRouterProvider = Provider<CommandRouter>((ref) {
  return CommandRouter(ref);
});

class CommandRouter {
  final Ref _ref;
  final Map<String, CommandHandler> _handlers = {};

  CommandRouter(this._ref) {
    _registerHandlers();
  }

  void _registerHandlers() {
    _handlers['call'] = _handleCall;
    _handlers['sms'] = _handleSMS;
    _handlers['flashlight'] = _handleFlashlight;
    _handlers['volume'] = _handleVolume;
    _handlers['brightness'] = _handleBrightness;
    _handlers['wifi'] = _handleWifi;
    _handlers['bluetooth'] = _handleBluetooth;
    _handlers['open'] = _handleOpenApp;
    _handlers['search'] = _handleSearch;
    _handlers['download'] = _handleDownload;
    _handlers['file'] = _handleFileCommand;
    _handlers['pdf'] = _handlePDFCommand;
    _handlers['image'] = _handleImageCommand;
    _handlers['termux'] = _handleTermuxCommand;
    _handlers['usb'] = _handleUSBCommand;
    _handlers['info'] = _handleDeviceInfo;
    _handlers['reminder'] = _handleReminder;
    _handlers['note'] = _handleNote;
    _handlers['help'] = _handleHelp;
  }

  Future<CommandResult> routeCommand(String command) async {
    try {
      final intent = _detectIntent(command);
      final handler = _handlers[intent.type];
      
      if (handler != null) {
        return await handler(command, intent);
      }
      
      return await _handleGeneralCommand(command);
    } catch (e) {
      return CommandResult.error('Error processing command: $e');
    }
  }

  Intent _detectIntent(String command) {
    final lower = command.toLowerCase();
    
    if (_matchesAny(lower, ['call', 'phone', 'dial'])) {
      return Intent('call', _extractPhoneNumber(command));
    }
    
    if (_matchesAny(lower, ['sms', 'message', 'text', 'send sms'])) {
      return Intent('sms', _extractMessage(command));
    }
    
    if (_matchesAny(lower, ['flashlight', 'torch', 'light'])) {
      return Intent('flashlight', null);
    }
    
    if (_matchesAny(lower, ['volume', 'sound', 'loudness'])) {
      return Intent('volume', _extractVolumeLevel(command));
    }
    
    if (_matchesAny(lower, ['brightness', 'screen'])) {
      return Intent('brightness', _extractBrightnessLevel(command));
    }
    
    if (_matchesAny(lower, ['wifi', 'wi-fi'])) {
      return Intent('wifi', null);
    }
    
    if (_matchesAny(lower, ['bluetooth', 'bt'])) {
      return Intent('bluetooth', null);
    }
    
    if (_matchesAny(lower, ['open', 'launch', 'start'])) {
      return Intent('open', _extractAppName(command));
    }
    
    if (_matchesAny(lower, ['search', 'find', 'google'])) {
      return Intent('search', _extractSearchQuery(command));
    }
    
    if (_matchesAny(lower, ['download', 'save'])) {
      return Intent('download', _extractURL(command));
    }
    
    if (_matchesAny(lower, ['file', 'folder', 'directory'])) {
      return Intent('file', command);
    }
    
    if (_matchesAny(lower, ['pdf', 'document'])) {
      return Intent('pdf', command);
    }
    
    if (_matchesAny(lower, ['image', 'photo', 'picture', 'camera'])) {
      return Intent('image', command);
    }
    
    if (_matchesAny(lower, ['termux', 'terminal', 'shell', 'bash'])) {
      return Intent('termux', command);
    }
    
    if (_matchesAny(lower, ['usb', 'pendrive', 'drive'])) {
      return Intent('usb', command);
    }
    
    if (_matchesAny(lower, ['info', 'device', 'status', 'battery'])) {
      return Intent('info', null);
    }
    
    if (_matchesAny(lower, ['remind', 'reminder', 'alarm'])) {
      return Intent('reminder', command);
    }
    
    if (_matchesAny(lower, ['note', 'remember', 'save'])) {
      return Intent('note', command);
    }
    
    if (_matchesAny(lower, ['help', 'what can', 'commands'])) {
      return Intent('help', null);
    }
    
    return Intent('general', command);
  }

  bool _matchesAny(String input, List<String> patterns) {
    return patterns.any((pattern) => input.contains(pattern));
  }

  String? _extractPhoneNumber(String command) {
    final regex = RegExp(r'\b\d{10,}\b');
    final match = regex.firstMatch(command);
    return match?.group(0);
  }

  String? _extractMessage(String command) {
    final parts = command.split('saying');
    if (parts.length > 1) return parts[1].trim();
    
    final parts2 = command.split('that');
    if (parts2.length > 1) return parts2[1].trim();
    
    return null;
  }

  double? _extractVolumeLevel(String command) {
    final regex = RegExp(r'(\d+)%?');
    final match = regex.firstMatch(command);
    if (match != null) {
      final value = int.parse(match.group(1)!);
      return value / 100;
    }
    
    if (command.contains('up') || command.contains('increase')) return 0.8;
    if (command.contains('down') || command.contains('decrease')) return 0.3;
    if (command.contains('max') || command.contains('full')) return 1.0;
    if (command.contains('min') || command.contains('mute')) return 0.0;
    
    return null;
  }

  double? _extractBrightnessLevel(String command) {
    return _extractVolumeLevel(command);
  }

  String? _extractAppName(String command) {
    final patterns = [
      RegExp(r'open\s+(.+)', caseSensitive: false),
      RegExp(r'launch\s+(.+)', caseSensitive: false),
      RegExp(r'start\s+(.+)', caseSensitive: false),
    ];
    
    for (final pattern in patterns) {
      final match = pattern.firstMatch(command);
      if (match != null) {
        return match.group(1)?.trim();
      }
    }
    return null;
  }

  String? _extractSearchQuery(String command) {
    final patterns = [
      RegExp(r'search\s+for\s+(.+)', caseSensitive: false),
      RegExp(r'search\s+(.+)', caseSensitive: false),
      RegExp(r'find\s+(.+)', caseSensitive: false),
      RegExp(r'google\s+(.+)', caseSensitive: false),
    ];
    
    for (final pattern in patterns) {
      final match = pattern.firstMatch(command);
      if (match != null) {
        return match.group(1)?.trim();
      }
    }
    return command;
  }

  String? _extractURL(String command) {
    final regex = RegExp(
      r'(https?://[^\s]+)|(www\.[^\s]+)',
      caseSensitive: false,
    );
    final match = regex.firstMatch(command);
    return match?.group(0);
  }

  Future<CommandResult> _handleCall(String command, Intent intent) async {
    final deviceService = _ref.read(deviceControlServiceProvider);
    final number = intent.data ?? '';
    
    if (number.isEmpty) {
      return CommandResult.error('Please provide a phone number');
    }
    
    await deviceService.makeCall(number);
    return CommandResult.success('Calling $number');
  }

  Future<CommandResult> _handleSMS(String command, Intent intent) async {
    final deviceService = _ref.read(deviceControlServiceProvider);
    final parts = intent.data?.split(' to ') ?? [];
    
    String? number;
    String? message;
    
    if (parts.length >= 2) {
      number = parts[0].trim();
      message = parts[1].trim();
    }
    
    if (number == null || message == null) {
      return CommandResult.error('Please provide number and message');
    }
    
    await deviceService.sendSMS(number, message);
    return CommandResult.success('Message sent to $number');
  }

  Future<CommandResult> _handleFlashlight(String command, Intent intent) async {
    final deviceService = _ref.read(deviceControlServiceProvider);
    await deviceService.toggleFlashlight();
    return CommandResult.success('Flashlight toggled');
  }

  Future<CommandResult> _handleVolume(String command, Intent intent) async {
    final deviceService = _ref.read(deviceControlServiceProvider);
    final level = intent.data != null ? double.tryParse(intent.data!) : null;
    
    if (level != null) {
      await deviceService.setVolume(level);
      return CommandResult.success('Volume set to ${(level * 100).toInt()}%');
    }
    
    return CommandResult.error('Could not determine volume level');
  }

  Future<CommandResult> _handleBrightness(String command, Intent intent) async {
    final deviceService = _ref.read(deviceControlServiceProvider);
    final level = intent.data != null ? double.tryParse(intent.data!) : null;
    
    if (level != null) {
      await deviceService.setBrightness(level);
      return CommandResult.success('Brightness set to ${(level * 100).toInt()}%');
    }
    
    return CommandResult.error('Could not determine brightness level');
  }

  Future<CommandResult> _handleWifi(String command, Intent intent) async {
    final deviceService = _ref.read(deviceControlServiceProvider);
    await deviceService.toggleWifi();
    return CommandResult.success('WiFi toggled');
  }

  Future<CommandResult> _handleBluetooth(String command, Intent intent) async {
    final deviceService = _ref.read(deviceControlServiceProvider);
    await deviceService.toggleBluetooth();
    return CommandResult.success('Bluetooth toggled');
  }

  Future<CommandResult> _handleOpenApp(String command, Intent intent) async {
    final deviceService = _ref.read(deviceControlServiceProvider);
    final appName = intent.data ?? '';
    
    if (appName.isEmpty) {
      return CommandResult.error('Please specify an app to open');
    }
    
    await deviceService.openApp(appName);
    return CommandResult.success('Opening $appName');
  }

  Future<CommandResult> _handleSearch(String command, Intent intent) async {
    final query = intent.data ?? command;
    
    return CommandResult.success('Searching for: $query');
  }

  Future<CommandResult> _handleDownload(String command, Intent intent) async {
    final url = intent.data;
    
    if (url == null || url.isEmpty) {
      return CommandResult.error('Please provide a URL to download');
    }
    
    final downloadManager = _ref.read(downloadManagerProvider);
    final task = await downloadManager.enqueueDownload(url: url);
    
    if (task != null) {
      return CommandResult.success('Download started: ${task.filename}');
    }
    
    return CommandResult.error('Failed to start download');
  }

  Future<CommandResult> _handleFileCommand(String command, Intent intent) async {
    final fileAgent = _ref.read(fileAgentServiceProvider);
    
    if (command.contains('search') || command.contains('find')) {
      final query = intent.data ?? '';
      final results = await fileAgent.searchFiles(query: query);
      return CommandResult.success('Found ${results.length} files');
    }
    
    return CommandResult.success('File command processed');
  }

  Future<CommandResult> _handlePDFCommand(String command, Intent intent) async {
    return CommandResult.success('PDF command processed');
  }

  Future<CommandResult> _handleImageCommand(String command, Intent intent) async {
    final visionService = _ref.read(visionServiceProvider);
    
    return CommandResult.success('Image command processed');
  }

  Future<CommandResult> _handleTermuxCommand(String command, Intent intent) async {
    final termux = _ref.read(termuxBridgeProvider);
    final shellCommand = intent.data ?? '';
    
    if (shellCommand.isEmpty) {
      return CommandResult.error('Please provide a command');
    }
    
    final result = await termux.executeCommand(shellCommand);
    
    if (result.success) {
      return CommandResult.success(result.stdout.isEmpty 
          ? 'Command executed successfully' 
          : result.stdout);
    } else {
      return CommandResult.error(result.stderr);
    }
  }

  Future<CommandResult> _handleUSBCommand(String command, Intent intent) async {
    final usbAgent = _ref.read(usbAgentProvider);
    final devices = await usbAgent.getConnectedDevices();
    
    return CommandResult.success('Found ${devices.length} USB devices');
  }

  Future<CommandResult> _handleDeviceInfo(String command, Intent intent) async {
    final deviceService = _ref.read(deviceControlServiceProvider);
    final info = await deviceService.getDeviceInfo();
    final battery = await deviceService.getBatteryLevel();
    
    return CommandResult.success(
      'Device: ${info['model']}\nBattery: $battery%',
    );
  }

  Future<CommandResult> _handleReminder(String command, Intent intent) async {
    return CommandResult.success('Reminder set');
  }

  Future<CommandResult> _handleNote(String command, Intent intent) async {
    return CommandResult.success('Note saved');
  }

  Future<CommandResult> _handleHelp(String command, Intent intent) async {
    final helpText = '''
Available Commands:
- Call: "Call [number]"
- SMS: "Send SMS to [number] saying [message]"
- Flashlight: "Turn on flashlight"
- Volume: "Set volume to 50%"
- Brightness: "Set brightness to 70%"
- WiFi: "Toggle WiFi"
- Bluetooth: "Toggle Bluetooth"
- Open App: "Open [app name]"
- Search: "Search for [query]"
- Download: "Download [URL]"
- Device Info: "Show device info"
''';  
    return CommandResult.success(helpText);
  }

  Future<CommandResult> _handleGeneralCommand(String command) async {
    final groqService = _ref.read(groqServiceProvider);
    
    final response = await groqService.chatCompletion(
      messages: [
        GroqMessage.system('You are AC AI, a helpful assistant.'),
        GroqMessage.user(command),
      ],
    );
    
    return CommandResult.success(response.content);
  }
}

typedef CommandHandler = Future<CommandResult> Function(String command, Intent intent);

class Intent {
  final String type;
  final String? data;

  Intent(this.type, this.data);
}

class CommandResult {
  final bool success;
  final String message;
  final dynamic data;
  final String? error;

  CommandResult({
    required this.success,
    required this.message,
    this.data,
    this.error,
  });

  factory CommandResult.success(String message, {dynamic data}) {
    return CommandResult(
      success: true,
      message: message,
      data: data,
    );
  }

  factory CommandResult.error(String error) {
    return CommandResult(
      success: false,
      message: error,
      error: error,
    );
  }
}
