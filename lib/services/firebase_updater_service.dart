import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/app_release.dart';

class FirebaseUpdaterService {
  final String collectionName;
  final String currentVersion;
  final int currentBuildNumber;
  final String packageName;
  final FirebaseFirestore _firestore;

  FirebaseUpdaterService({
    required this.collectionName,
    required this.currentVersion,
    required this.currentBuildNumber,
    required this.packageName,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Check if update is available from Firestore
  Future<AppRelease?> checkForUpdate() async {
    try {
      debugPrint('🔍 Checking for updates...');
      debugPrint('📦 Current: v$currentVersion ($currentBuildNumber)');
      debugPrint('📦 Package: $packageName');

      // Query Firestore for this app's latest release
      final querySnapshot = await _firestore
          .collection(collectionName)
          .where('package_name', isEqualTo: packageName)
          .orderBy('build_number', descending: true)
          .limit(1)
          .get()
          .timeout(const Duration(seconds: 30));

      if (querySnapshot.docs.isEmpty) {
        debugPrint('❌ No release found for: $packageName');
        return null;
      }

      final doc = querySnapshot.docs.first;
      final data = doc.data();

      // Add document ID to data
      data['id'] = doc.id;

      final release = AppRelease.fromJson(data);
      debugPrint('📦 Latest: v${release.version} (${release.buildNumber})');

      // Check if update available
      if (release.buildNumber > currentBuildNumber) {
        debugPrint('✅ Update available!');
        return release;
      }

      debugPrint('✅ Already on latest version');
      return null;
    } catch (e) {
      debugPrint('❌ Error checking update: $e');
      return null;
    }
  }

  /// Get all releases for this app
  Future<List<AppRelease>> getAllReleases() async {
    try {
      final querySnapshot = await _firestore
          .collection(collectionName)
          .where('package_name', isEqualTo: packageName)
          .orderBy('build_number', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return AppRelease.fromJson(data);
      }).toList();
    } catch (e) {
      debugPrint('❌ Error fetching releases: $e');
      return [];
    }
  }
}
