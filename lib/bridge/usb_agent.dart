import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final usbAgentProvider = Provider<USBAgent>((ref) {
  return USBAgent();
});

class USBAgent {
  static const MethodChannel _channel = MethodChannel('com.ac.ai/usb');

  Future<List<USBDevice>> getConnectedDevices() async {
    try {
      final result = await _channel.invokeMethod<String>('getConnectedDevices');
      if (result != null) {
        final List<dynamic> decoded = jsonDecode(result);
        return decoded
            .map((d) => USBDevice.fromJson(Map<String, dynamic>.from(d)))
            .toList();
      }
      return [];
    } catch (e) {
      print('USB devices error: $e');
      return [];
    }
  }

  Future<bool> requestPermission(USBDevice device) async {
    try {
      final result = await _channel.invokeMethod<bool>('requestPermission', {
        'deviceName': device.deviceName,
      });
      return result ?? false;
    } catch (e) {
      print('USB permission error: $e');
      return false;
    }
  }

  Future<USBDeviceHealth> checkDeviceHealth(USBDevice device) async {
    try {
      final result = await _channel.invokeMethod<String>('checkDeviceHealth', {
        'deviceName': device.deviceName,
      });
      
      if (result != null) {
        return USBDeviceHealth.fromJson(jsonDecode(result) as Map<String, dynamic>);
      }
      
      return USBDeviceHealth(
        deviceName: device.deviceName,
        status: 'unknown',
        hasPermission: false,
        isMassStorage: false,
      );
    } catch (e) {
      print('USB health check error: $e');
      return USBDeviceHealth(
        deviceName: device.deviceName,
        status: 'error',
        hasPermission: false,
        isMassStorage: false,
      );
    }
  }

  Future<bool> formatDevice(USBDevice device, {bool requireConfirmation = true}) async {
    if (requireConfirmation) {
    }
    
    try {
      final result = await _channel.invokeMethod<bool>('formatDevice', {
        'deviceName': device.deviceName,
      });
      return result ?? false;
    } catch (e) {
      print('USB format error: $e');
      return false;
    }
  }

  String getDeviceType(USBDevice device) {
    if (device.isMassStorage) {
      return 'USB Mass Storage';
    }
    
    final vendor = device.vendorName?.toLowerCase() ?? '';
    if (vendor.contains('samsung') || vendor.contains('kingston') || 
        vendor.contains('sandisk')) {
      return 'USB Flash Drive';
    }
    
    if (device.interfaceCount > 0) {
      return 'USB Device';
    }
    
    return 'Unknown USB Device';
  }

  String getRepairSuggestion(USBDeviceHealth health) {
    switch (health.status) {
      case 'healthy':
        return 'Device is healthy. No repair needed.';
      case 'corrupted':
        return 'File system corruption detected. Consider formatting the device.';
      case 'no_permission':
        return 'No permission to access device. Grant USB permissions.';
      case 'unmounted':
        return 'Device is not mounted. Try reconnecting.';
      case 'readonly':
        return 'Device is read-only. Check for write protection.';
      default:
        return 'Unknown issue. Try reconnecting the device.';
    }
  }
}

class USBDevice {
  final String deviceName;
  final int vendorId;
  final int productId;
  final String? vendorName;
  final String? productName;
  final String? manufacturerName;
  final String? serialNumber;
  final int deviceClass;
  final int deviceSubclass;
  final int deviceProtocol;
  final int interfaceCount;
  final bool isMassStorage;

  USBDevice({
    required this.deviceName,
    required this.vendorId,
    required this.productId,
    this.vendorName,
    this.productName,
    this.manufacturerName,
    this.serialNumber,
    required this.deviceClass,
    required this.deviceSubclass,
    required this.deviceProtocol,
    required this.interfaceCount,
    required this.isMassStorage,
  });

  factory USBDevice.fromJson(Map<String, dynamic> json) {
    return USBDevice(
      deviceName: json['deviceName'] as String,
      vendorId: json['vendorId'] as int,
      productId: json['productId'] as int,
      vendorName: json['vendorName'] as String?,
      productName: json['productName'] as String?,
      manufacturerName: json['manufacturerName'] as String?,
      serialNumber: json['serialNumber'] as String?,
      deviceClass: json['deviceClass'] as int,
      deviceSubclass: json['deviceSubclass'] as int,
      deviceProtocol: json['deviceProtocol'] as int,
      interfaceCount: json['interfaceCount'] as int,
      isMassStorage: json['isMassStorage'] as bool? ?? false,
    );
  }

  String get displayName {
    return productName ?? manufacturerName ?? vendorName ?? 'Unknown Device';
  }

  String get identifier {
    return '$vendorId:$productId';
  }
}

class USBDeviceHealth {
  final String deviceName;
  final String status;
  final bool hasPermission;
  final bool isMassStorage;
  final int? interfaceCount;
  final String? errorMessage;

  USBDeviceHealth({
    required this.deviceName,
    required this.status,
    required this.hasPermission,
    required this.isMassStorage,
    this.interfaceCount,
    this.errorMessage,
  });

  factory USBDeviceHealth.fromJson(Map<String, dynamic> json) {
    return USBDeviceHealth(
      deviceName: json['deviceName'] as String,
      status: json['status'] as String,
      hasPermission: json['hasPermission'] as bool,
      isMassStorage: json['isMassStorage'] as bool,
      interfaceCount: json['interfaceCount'] as int?,
      errorMessage: json['errorMessage'] as String?,
    );
  }

  bool get isHealthy => status == 'healthy';
  bool get needsAttention => status != 'healthy' && status != 'unknown';
}
