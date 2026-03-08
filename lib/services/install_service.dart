import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class InstalledAppInfo {
  final String versionName;
  final int versionCode;

  InstalledAppInfo({required this.versionName, required this.versionCode});
}

class InstallService {
  static const _channel = MethodChannel('com.devstudio/installer');

  /// Check if app is installed (checks both release and debug variants)
  Future<bool> isAppInstalled(String packageName) async {
    if (!Platform.isAndroid) return false;

    try {
      // Check release package
      var result = await _channel.invokeMethod<bool>('isAppInstalled', {
        'packageName': packageName,
      });
      if (result == true) return true;

      // Check debug package
      result = await _channel.invokeMethod<bool>('isAppInstalled', {
        'packageName': '$packageName.debug',
      });
      return result ?? false;
    } catch (e) {
      debugPrint('❌ isAppInstalled error: $e');
      return false;
    }
  }

  /// Get installed app version (checks both release and debug variants)
  Future<InstalledAppInfo?> getInstalledVersion(String packageName) async {
    if (!Platform.isAndroid) return null;

    try {
      // Try release package first
      var result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'getInstalledVersion',
        {'packageName': packageName},
      );

      // If not found, try debug package
      result ??= await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'getInstalledVersion',
        {'packageName': '$packageName.debug'},
      );

      if (result != null) {
        return InstalledAppInfo(
          versionName: result['versionName'] as String? ?? '',
          versionCode: (result['versionCode'] as num?)?.toInt() ?? 0,
        );
      }
      return null;
    } catch (e) {
      debugPrint('❌ getInstalledVersion error: $e');
      return null;
    }
  }

  /// Open installed app
  Future<bool> openApp(String packageName) async {
    if (!Platform.isAndroid) return false;

    try {
      final result = await _channel.invokeMethod<bool>('openApp', {
        'packageName': packageName,
      });
      return result ?? false;
    } catch (e) {
      debugPrint('❌ openApp error: $e');
      return false;
    }
  }

  /// Install APK on Android
  Future<bool> installApk(String filePath) async {
    if (!Platform.isAndroid) {
      debugPrint('❌ APK install only supported on Android');
      return false;
    }

    try {
      debugPrint('📲 Installing APK: $filePath');

      final result = await _channel.invokeMethod<bool>('installApk', {
        'filePath': filePath,
      });

      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('❌ Install error: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('❌ Install error: $e');
      return false;
    }
  }

  /// Check if can install unknown apps
  Future<bool> canInstallApks() async {
    if (!Platform.isAndroid) return false;

    try {
      final result = await _channel.invokeMethod<bool>('canInstallApks');
      return result ?? false;
    } catch (e) {
      debugPrint('❌ Permission check error: $e');
      return false;
    }
  }

  /// Request install permission
  Future<bool> requestInstallPermission() async {
    if (!Platform.isAndroid) return false;

    try {
      final result = await _channel.invokeMethod<bool>(
        'requestInstallPermission',
      );
      return result ?? false;
    } catch (e) {
      debugPrint('❌ Permission request error: $e');
      return false;
    }
  }

  /// Open file with system handler (for non-APK files)
  Future<bool> openFile(String filePath) async {
    try {
      final result = await _channel.invokeMethod<bool>('openFile', {
        'filePath': filePath,
      });
      return result ?? false;
    } catch (e) {
      debugPrint('❌ Open file error: $e');
      return false;
    }
  }

  /// Get device CPU architecture
  Future<String?> getDeviceArch() async {
    if (!Platform.isAndroid) return null;

    try {
      final result = await _channel.invokeMethod<String>('getDeviceArch');
      return result;
    } catch (e) {
      debugPrint('❌ getDeviceArch error: $e');
      return null;
    }
  }
}
