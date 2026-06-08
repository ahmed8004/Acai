import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final calendarServiceProvider = Provider<CalendarService>((ref) {
  return CalendarService();
});

class CalendarService {
  static const MethodChannel _channel = MethodChannel('com.ac.ai/calendar');

  Future<bool> addEvent({
    required String title,
    String description = '',
    String location = '',
    required DateTime startTime,
    DateTime? endTime,
    bool isAllDay = false,
  }) async {
    try {
      final result = await _channel.invokeMethod<bool>('addEvent', {
        'title': title,
        'description': description,
        'location': location,
        'startTime': startTime.millisecondsSinceEpoch,
        'endTime': (endTime ?? startTime.add(const Duration(hours: 1))).millisecondsSinceEpoch,
        'isAllDay': isAllDay,
      });
      return result ?? false;
    } catch (e) {
      print('Calendar add event error: $e');
      return false;
    }
  }

  Future<void> openCalendar() async {
    try {
      await _channel.invokeMethod('openCalendar');
    } catch (e) {
      print('Open calendar error: $e');
    }
  }
}

final telephonyServiceProvider = Provider<TelephonyService>((ref) {
  return TelephonyService();
});

class TelephonyService {
  static const MethodChannel _channel = MethodChannel('com.ac.ai/sms');

  Future<bool> sendSMS(String phoneNumber, String message) async {
    try {
      final result = await _channel.invokeMethod<bool>('sendSMS', {
        'phoneNumber': phoneNumber,
        'message': message,
      });
      return result ?? false;
    } catch (e) {
      print('SMS send error: $e');
      return false;
    }
  }

  Future<bool> sendSilentSMS(String phoneNumber, String message) async {
    try {
      final result = await _channel.invokeMethod<bool>('sendSilentSMS', {
        'phoneNumber': phoneNumber,
        'message': message,
      });
      return result ?? false;
    } catch (e) {
      print('Silent SMS send error: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getInboxMessages({int limit = 10}) async {
    try {
      final result = await _channel.invokeMethod<String>('getInboxMessages', {
        'limit': limit,
      });
      if (result != null) {
        final List<dynamic> decoded = jsonDecode(result);
        return List<Map<String, dynamic>>.from(decoded);
      }
      return [];
    } catch (e) {
      print('Get inbox messages error: $e');
      return [];
    }
  }
}

final torchServiceProvider = Provider<TorchService>((ref) {
  return TorchService();
});

class TorchService {
  static const MethodChannel _channel = MethodChannel('com.ac.ai/torch');

  Future<bool> toggleTorch() async {
    try {
      final result = await _channel.invokeMethod<bool>('toggleTorch');
      return result ?? false;
    } catch (e) {
      print('Toggle torch error: $e');
      return false;
    }
  }

  Future<bool> turnOnTorch() async {
    try {
      final result = await _channel.invokeMethod<bool>('turnOnTorch');
      return result ?? false;
    } catch (e) {
      print('Turn on torch error: $e');
      return false;
    }
  }

  Future<bool> turnOffTorch() async {
    try {
      final result = await _channel.invokeMethod<bool>('turnOffTorch');
      return result ?? false;
    } catch (e) {
      print('Turn off torch error: $e');
      return false;
    }
  }

  Future<bool> isTorchAvailable() async {
    try {
      final result = await _channel.invokeMethod<bool>('isTorchAvailable');
      return result ?? false;
    } catch (e) {
      print('Check torch availability error: $e');
      return false;
    }
  }

  Future<bool> isTorchOn() async {
    try {
      final result = await _channel.invokeMethod<bool>('isTorchOn');
      return result ?? false;
    } catch (e) {
      print('Check torch status error: $e');
      return false;
    }
  }
}

final bluetoothServiceProvider = Provider<BluetoothService>((ref) {
  return BluetoothService();
});

class BluetoothService {
  static const MethodChannel _channel = MethodChannel('com.ac.ai/bluetooth');

  Future<bool> isBluetoothAvailable() async {
    try {
      final result = await _channel.invokeMethod<bool>('isBluetoothAvailable');
      return result ?? false;
    } catch (e) {
      print('Check Bluetooth availability error: $e');
      return false;
    }
  }

  Future<bool> isBluetoothEnabled() async {
    try {
      final result = await _channel.invokeMethod<bool>('isBluetoothEnabled');
      return result ?? false;
    } catch (e) {
      print('Check Bluetooth status error: $e');
      return false;
    }
  }

  Future<bool> enableBluetooth() async {
    try {
      final result = await _channel.invokeMethod<bool>('enableBluetooth');
      return result ?? false;
    } catch (e) {
      print('Enable Bluetooth error: $e');
      return false;
    }
  }

  Future<bool> disableBluetooth() async {
    try {
      final result = await _channel.invokeMethod<bool>('disableBluetooth');
      return result ?? false;
    } catch (e) {
      print('Disable Bluetooth error: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getPairedDevices() async {
    try {
      final result = await _channel.invokeMethod<String>('getPairedDevices');
      if (result != null) {
        final List<dynamic> decoded = jsonDecode(result);
        return List<Map<String, dynamic>>.from(decoded);
      }
      return [];
    } catch (e) {
      print('Get paired devices error: $e');
      return [];
    }
  }

  Future<bool> startDiscovery() async {
    try {
      final result = await _channel.invokeMethod<bool>('startDiscovery');
      return result ?? false;
    } catch (e) {
      print('Start discovery error: $e');
      return false;
    }
  }

  Future<bool> cancelDiscovery() async {
    try {
      final result = await _channel.invokeMethod<bool>('cancelDiscovery');
      return result ?? false;
    } catch (e) {
      print('Cancel discovery error: $e');
      return false;
    }
  }
}

final wifiServiceProvider = Provider<WiFiService>((ref) {
  return WiFiService();
});

class WiFiService {
  static const MethodChannel _channel = MethodChannel('com.ac.ai/wifi');

  Future<bool> isWiFiEnabled() async {
    try {
      final result = await _channel.invokeMethod<bool>('isWiFiEnabled');
      return result ?? false;
    } catch (e) {
      print('Check WiFi status error: $e');
      return false;
    }
  }

  Future<bool> enableWiFi() async {
    try {
      final result = await _channel.invokeMethod<bool>('enableWiFi');
      return result ?? false;
    } catch (e) {
      print('Enable WiFi error: $e');
      return false;
    }
  }

  Future<bool> disableWiFi() async {
    try {
      final result = await _channel.invokeMethod<bool>('disableWiFi');
      return result ?? false;
    } catch (e) {
      print('Disable WiFi error: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> getWiFiInfo() async {
    try {
      final result = await _channel.invokeMethod<String>('getWiFiInfo');
      if (result != null) {
        return Map<String, dynamic>.from(jsonDecode(result));
      }
      return {};
    } catch (e) {
      print('Get WiFi info error: $e');
      return {};
    }
  }

  Future<List<Map<String, dynamic>>> getConfiguredNetworks() async {
    try {
      final result = await _channel.invokeMethod<String>('getConfiguredNetworks');
      if (result != null) {
        final List<dynamic> decoded = jsonDecode(result);
        return List<Map<String, dynamic>>.from(decoded);
      }
      return [];
    } catch (e) {
      print('Get configured networks error: $e');
      return [];
    }
  }
}

final webViewServiceProvider = Provider<WebViewService>((ref) {
  return WebViewService();
});

class WebViewService {
  static const MethodChannel _channel = MethodChannel('com.ac.ai/webview');

  Future<bool> openWebView(String url, {String title = ''}) async {
    try {
      final result = await _channel.invokeMethod<bool>('openWebView', {
        'url': url,
        'title': title,
      });
      return result ?? false;
    } catch (e) {
      print('Open WebView error: $e');
      return false;
    }
  }

  Future<bool> openBrowser(String url) async {
    try {
      final result = await _channel.invokeMethod<bool>('openBrowser', {
        'url': url,
      });
      return result ?? false;
    } catch (e) {
      print('Open browser error: $e');
      return false;
    }
  }

  Future<bool> loadHTML(String html, {String baseUrl = ''}) async {
    try {
      final result = await _channel.invokeMethod<bool>('loadHTML', {
        'html': html,
        'baseUrl': baseUrl,
      });
      return result ?? false;
    } catch (e) {
      print('Load HTML error: $e');
      return false;
    }
  }
}

final docxServiceProvider = Provider<DOCXService>((ref) {
  return DOCXService();
});

class DOCXService {
  static const MethodChannel _channel = MethodChannel('com.ac.ai/docx');

  Future<String> extractTextFromDOCX(String filePath) async {
    try {
      final result = await _channel.invokeMethod<String>('extractTextFromDOCX', {
        'filePath': filePath,
      });
      return result ?? '';
    } catch (e) {
      print('Extract text from DOCX error: $e');
      return '';
    }
  }

  Future<Map<String, dynamic>> readDOCXMetadata(String filePath) async {
    try {
      final result = await _channel.invokeMethod<String>('readDOCXMetadata', {
        'filePath': filePath,
      });
      if (result != null) {
        return Map<String, dynamic>.from(jsonDecode(result));
      }
      return {};
    } catch (e) {
      print('Read DOCX metadata error: $e');
      return {};
    }
  }
}
