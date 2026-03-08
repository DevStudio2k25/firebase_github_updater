import 'package:flutter/material.dart';
import 'services/firebase_updater_service.dart';
import 'widgets/update_bottom_sheet.dart';

/// Helper class for easy app update integration
/// Just call FirebaseGithubUpdaterHelper.checkAndShowUpdate() in your app
class FirebaseGithubUpdaterHelper {
  /// Check for updates and automatically show bottom sheet if available
  ///
  /// Example:
  /// ```dart
  /// FirebaseGithubUpdaterHelper.checkAndShowUpdate(
  ///   context: context,
  ///   collectionName: 'app_releases',
  ///   packageName: 'com.example.app',
  ///   currentVersion: '1.0.0',
  ///   currentBuildNumber: 1,
  /// );
  /// ```
  static Future<void> checkAndShowUpdate({
    required BuildContext context,
    required String collectionName,
    required String packageName,
    required String currentVersion,
    required int currentBuildNumber,
    VoidCallback? onUpdateComplete,
    VoidCallback? onNoUpdate,
    Function(dynamic error)? onError,
  }) async {
    try {
      final updater = FirebaseUpdaterService(
        collectionName: collectionName,
        currentVersion: currentVersion,
        currentBuildNumber: currentBuildNumber,
        packageName: packageName,
      );

      final update = await updater.checkForUpdate();

      if (update != null) {
        if (context.mounted) {
          await UpdateBottomSheet.show(
            context,
            update,
            onUpdateComplete: onUpdateComplete,
          );
        }
      } else {
        onNoUpdate?.call();
      }
    } catch (e) {
      onError?.call(e);
    }
  }

  /// Silent check - only returns true/false if update available
  /// Useful for showing custom UI
  static Future<bool> hasUpdate({
    required String collectionName,
    required String packageName,
    required String currentVersion,
    required int currentBuildNumber,
  }) async {
    try {
      final updater = FirebaseUpdaterService(
        collectionName: collectionName,
        currentVersion: currentVersion,
        currentBuildNumber: currentBuildNumber,
        packageName: packageName,
      );

      final update = await updater.checkForUpdate();
      return update != null;
    } catch (e) {
      return false;
    }
  }
}
