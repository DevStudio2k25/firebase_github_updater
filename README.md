<!--
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/tools/pub/writing-package-pages).

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/to/develop-packages).
-->

# Firebase GitHub Updater

A Flutter package for automatic app updates via Firebase Firestore and GitHub releases.

## Features

- � Fetch updates from Firebase Firestore
- 📥 Download APK from GitHub releases
- 📲 Install updates automatically
- 🎨 Beautiful update bottom sheet UI
- ⚡ Progress tracking for downloads

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  firebase_github_updater: ^0.0.1
  firebase_core: ^3.0.0
  cloud_firestore: ^5.0.0
```

## Setup

1. Initialize Firebase in your app:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}
```

2. Create Firestore collection `app_releases` with documents:

```json
{
  "package_name": "com.example.app",
  "app_name": "My App",
  "version": "1.0.1",
  "build_number": 2,
  "release_notes": "Bug fixes and improvements",
  "downloads": [
    {
      "platform": "android",
      "type": "apk",
      "url": "https://github.com/user/repo/releases/download/v1.0.1/app.apk",
      "filename": "app.apk",
      "size": 25000000
    }
  ]
}
```

## Usage

### Simple - One Line Integration

```dart
import 'package:firebase_github_updater/firebase_github_updater.dart';

// Just call this - it handles everything automatically!
await FirebaseGithubUpdaterHelper.checkAndShowUpdate(
  context: context,
  collectionName: 'app_releases',
  packageName: 'com.example.app',
  currentVersion: '1.0.0',
  currentBuildNumber: 1,
  onUpdateComplete: () {
    print('Update completed!');
  },
);
```

### Advanced - Manual Control

```dart
import 'package:firebase_github_updater/firebase_github_updater.dart';

// Check for updates manually
final updater = FirebaseUpdaterService(
  collectionName: 'app_releases',
  currentVersion: '1.0.0',
  currentBuildNumber: 1,
  packageName: 'com.example.app',
);

final update = await updater.checkForUpdate();

if (update != null) {
  // Show bottom sheet
  UpdateBottomSheet.show(context, update);
  
  // Or use download/install services directly
  final downloadService = DownloadService();
  final installService = InstallService();
}
```

## Firestore Structure

Collection: `app_releases`

Required fields:

- `package_name` (String) - Your app's package name
- `app_name` (String) - Display name
- `version` (String) - Version like "1.0.1"
- `build_number` (int) - Build number for comparison
- `downloads` (Array) - Download assets

Optional fields:

- `release_notes` (String)
- `description` (String)
- `icon_url` (String)
- `screenshots` (Array)

## Android Setup

Add to `AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.REQUEST_INSTALL_PACKAGES" />
<uses-permission android:name="android.permission.INTERNET" />
```
