import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final deviceControlServiceProvider = Provider<DeviceControlService>((ref) {
  return DeviceControlService();
});

class DeviceControlService {
  static const MethodChannel _channel = MethodChannel('com.ac.ai/device');

  Future<bool> toggleFlashlight() async {
    try {
      final result = await _channel.invokeMethod<bool>('toggleFlashlight');
      return result ?? false;
    } catch (e) {
      print('Flashlight error: $e');
      return false;
    }
  }

  Future<bool> setVolume(double volume) async {
    try {
      final result = await _channel.invokeMethod<bool>('setVolume', {'volume': volume});
      return result ?? false;
    } catch (e) {
      print('Volume error: $e');
      return false;
    }
  }

  Future<bool> setBrightness(double brightness) async {
    try {
      final result = await _channel.invokeMethod<bool>('setBrightness', {'brightness': brightness});
      return result ?? false;
    } catch (e) {
      print('Brightness error: $e');
      return false;
    }
  }

  Future<bool> toggleWifi() async {
    try {
      final result = await _channel.invokeMethod<bool>('toggleWifi');
      return result ?? false;
    } catch (e) {
      print('WiFi error: $e');
      return false;
    }
  }

  Future<bool> toggleBluetooth() async {
    try {
      final result = await _channel.invokeMethod<bool>('toggleBluetooth');
      return result ?? false;
    } catch (e) {
      print('Bluetooth error: $e');
      return false;
    }
  }

  Future<bool> openApp(String packageName) async {
    try {
      final result = await _channel.invokeMethod<bool>('openApp', {'packageName': packageName});
      return result ?? false;
    } catch (e) {
      print('Open app error: $e');
      return false;
    }
  }

  Future<void> makeCall(String phoneNumber) async {
    try {
      await _channel.invokeMethod('makeCall', {'number': phoneNumber});
    } catch (e) {
      print('Call error: $e');
    }
  }

  Future<void> sendSMS(String phoneNumber, String message) async {
    try {
      await _channel.invokeMethod('sendSMS', {
        'number': phoneNumber,
        'message': message,
      });
    } catch (e) {
      print('SMS error: $e');
    }
  }

  Future<Map<String, dynamic>> getDeviceInfo() async {
    try {
      final result = await _channel.invokeMethod<Map>('getDeviceInfo');
      return Map<String, dynamic>.from(result ?? {});
    } catch (e) {
      print('Device info error: $e');
      return {};
    }
  }

  Future<int> getBatteryLevel() async {
    try {
      final result = await _channel.invokeMethod<int>('getBatteryLevel');
      return result ?? -1;
    } catch (e) {
      print('Battery error: $e');
      return -1;
    }
  }

  Future<List<String>> getInstalledApps() async {
    try {
      final result = await _channel.invokeMethod<List>('getInstalledApps');
      return List<String>.from(result ?? []);
    } catch (e) {
      print('Apps error: $e');
      return [];
    }
  }
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

class NotificationService {
  static const MethodChannel _channel = MethodChannel('com.ac.ai/notifications');

  Future<List<Map<String, dynamic>>> getActiveNotifications() async {
    try {
      final result = await _channel.invokeMethod<String>('getActiveNotifications');
      if (result != null) {
        final List<dynamic> decoded = jsonDecode(result);
        return List<Map<String, dynamic>>.from(decoded);
      }
      return [];
    } catch (e) {
      print('Notifications error: $e');
      return [];
    }
  }

  Future<bool> clearNotification(String key) async {
    try {
      final result = await _channel.invokeMethod<bool>('clearNotification', {'key': key});
      return result ?? false;
    } catch (e) {
      print('Clear notification error: $e');
      return false;
    }
  }

  Future<bool> clearAllNotifications() async {
    try {
      final result = await _channel.invokeMethod<bool>('clearAllNotifications');
      return result ?? false;
    } catch (e) {
      print('Clear all notifications error: $e');
      return false;
    }
  }

  Future<bool> replyToNotification(String key, String message) async {
    try {
      final result = await _channel.invokeMethod<bool>('replyToNotification', {
        'key': key,
        'message': message,
      });
      return result ?? false;
    } catch (e) {
      print('Reply notification error: $e');
      return false;
    }
  }

  Future<String> getOTPFromSMS() async {
    try {
      final notifications = await getActiveNotifications();
      for (final notification in notifications) {
        final text = notification['text'] as String? ?? '';
        final bigText = notification['bigText'] as String? ?? '';
        final combined = '$text $bigText';
        
        final otpRegex = RegExp(r'\b\d{4,6}\b');
        final match = otpRegex.firstMatch(combined);
        if (match != null) {
          return match.group(0) ?? '';
        }
      }
      return '';
    } catch (e) {
      print('OTP error: $e');
      return '';
    }
  }
}
