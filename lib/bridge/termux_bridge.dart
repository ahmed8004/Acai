import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final termuxBridgeProvider = Provider<TermuxBridge>((ref) {
  return TermuxBridge();
});

class TermuxBridge {
  static const MethodChannel _channel = MethodChannel('com.ac.ai/termux');

  Future<bool> isTermuxInstalled() async {
    try {
      final result = await _channel.invokeMethod<bool>('isTermuxInstalled');
      return result ?? false;
    } catch (e) {
      print('Termux check error: $e');
      return false;
    }
  }

  Future<bool> isTermuxApiInstalled() async {
    try {
      final result = await _channel.invokeMethod<bool>('isTermuxApiInstalled');
      return result ?? false;
    } catch (e) {
      print('Termux API check error: $e');
      return false;
    }
  }

  Future<TermuxResult> executeCommand(
    String command, {
    String? workingDirectory,
  }) async {
    try {
      final result = await _channel.invokeMethod<Map>('executeCommand', {
        'command': command,
        'workingDirectory': workingDirectory,
      });
      
      return TermuxResult.fromMap(Map<String, dynamic>.from(result ?? {}));
    } catch (e) {
      print('Command execution error: $e');
      return TermuxResult.error(e.toString());
    }
  }

  Future<TermuxResult> executePython(
    String script, {
    List<String>? arguments,
  }) async {
    try {
      final result = await _channel.invokeMethod<Map>('executePython', {
        'script': script,
        'arguments': arguments,
      });
      
      return TermuxResult.fromMap(Map<String, dynamic>.from(result ?? {}));
    } catch (e) {
      print('Python execution error: $e');
      return TermuxResult.error(e.toString());
    }
  }

  Future<TermuxResult> executeWithRoot(String command) async {
    try {
      final result = await _channel.invokeMethod<Map>('executeWithRoot', {
        'command': command,
      });
      
      return TermuxResult.fromMap(Map<String, dynamic>.from(result ?? {}));
    } catch (e) {
      print('Root execution error: $e');
      return TermuxResult.error(e.toString());
    }
  }

  Future<TermuxResult> installPackage(String packageName) async {
    try {
      final result = await _channel.invokeMethod<Map>('installPackage', {
        'packageName': packageName,
      });
      
      return TermuxResult.fromMap(Map<String, dynamic>.from(result ?? {}));
    } catch (e) {
      print('Package install error: $e');
      return TermuxResult.error(e.toString());
    }
  }

  Future<TermuxResult> updatePackages() async {
    try {
      final result = await _channel.invokeMethod<Map>('updatePackages');
      return TermuxResult.fromMap(Map<String, dynamic>.from(result ?? {}));
    } catch (e) {
      print('Package update error: $e');
      return TermuxResult.error(e.toString());
    }
  }

  Future<List<String>> getInstalledPackages() async {
    try {
      final result = await _channel.invokeMethod<List>('getInstalledPackages');
      return List<String>.from(result ?? []);
    } catch (e) {
      print('Get packages error: $e');
      return [];
    }
  }

  Future<TermuxResult> runScript(
    String scriptPath, {
    List<String>? arguments,
  }) async {
    try {
      final result = await _channel.invokeMethod<Map>('runScript', {
        'scriptPath': scriptPath,
        'arguments': arguments,
      });
      
      return TermuxResult.fromMap(Map<String, dynamic>.from(result ?? {}));
    } catch (e) {
      print('Script run error: $e');
      return TermuxResult.error(e.toString());
    }
  }

  Future<Map<String, dynamic>> getTermuxInfo() async {
    try {
      final result = await _channel.invokeMethod<Map>('getTermuxInfo');
      return Map<String, dynamic>.from(result ?? {});
    } catch (e) {
      print('Termux info error: $e');
      return {};
    }
  }

  Future<String> getSetupGuide() async {
    return '''
Termux Setup Guide:

1. Install Termux from F-Droid (not Play Store)
2. Install Termux:API from F-Droid
3. Run: pkg update && pkg upgrade
4. Run: pkg install termux-api
5. Grant necessary permissions
6. Test with: termux-battery-status

Python Setup:
- Run: pkg install python
- Verify: python --version

Common Commands:
- pkg search <package>
- pkg install <package>
- termux-setup-storage
- termux-notification
''';  
  }
}

class TermuxResult {
  final String stdout;
  final String stderr;
  final int exitCode;
  final bool success;

  TermuxResult({
    required this.stdout,
    required this.stderr,
    required this.exitCode,
    required this.success,
  });

  factory TermuxResult.fromMap(Map<String, dynamic> map) {
    return TermuxResult(
      stdout: map['stdout'] as String? ?? '',
      stderr: map['stderr'] as String? ?? '',
      exitCode: map['exitCode'] as int? ?? -1,
      success: (map['exitCode'] as int? ?? -1) == 0,
    );
  }

  factory TermuxResult.error(String message) {
    return TermuxResult(
      stdout: '',
      stderr: message,
      exitCode: -1,
      success: false,
    );
  }

  @override
  String toString() {
    return 'Exit: $exitCode\nOutput: $stdout\nError: $stderr';
  }
}
