import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_github_updater/firebase_github_updater.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';

void main() {
  test('FirebaseUpdaterService initialization', () {
    final service = FirebaseUpdaterService(
      collectionName: 'app_releases',
      currentVersion: '1.0.0',
      currentBuildNumber: 1,
      packageName: 'com.example.app',
    );

    expect(service.currentVersion, '1.0.0');
    expect(service.currentBuildNumber, 1);
    expect(service.packageName, 'com.example.app');
  });

  test('Check for update - no update available', () async {
    final fakeFirestore = FakeFirebaseFirestore();
    
    // Add current version to Firestore
    await fakeFirestore.collection('app_releases').add({
      'package_name': 'com.example.app',
      'app_name': 'Test App',
      'version': '1.0.0',
      'build_number': 1,
      'downloads': [],
    });

    final service = FirebaseUpdaterService(
      collectionName: 'app_releases',
      currentVersion: '1.0.0',
      currentBuildNumber: 1,
      packageName: 'com.example.app',
      firestore: fakeFirestore,
    );

    final update = await service.checkForUpdate();
    expect(update, isNull);
  });

  test('Check for update - update available', () async {
    final fakeFirestore = FakeFirebaseFirestore();
    
    // Add newer version to Firestore
    await fakeFirestore.collection('app_releases').add({
      'package_name': 'com.example.app',
      'app_name': 'Test App',
      'version': '1.0.1',
      'build_number': 2,
      'downloads': [],
    });

    final service = FirebaseUpdaterService(
      collectionName: 'app_releases',
      currentVersion: '1.0.0',
      currentBuildNumber: 1,
      packageName: 'com.example.app',
      firestore: fakeFirestore,
    );

    final update = await service.checkForUpdate();
    expect(update, isNotNull);
    expect(update?.version, '1.0.1');
    expect(update?.buildNumber, 2);
  });
}
