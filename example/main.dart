import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_github_updater/firebase_github_updater.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: const HomePage());
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    _checkForUpdates();
  }

  Future<void> _checkForUpdates() async {
    // Simple one-liner - automatically shows bottom sheet if update available
    await FirebaseGithubUpdaterHelper.checkAndShowUpdate(
      context: context,
      collectionName: 'app_releases',
      currentVersion: '1.0.0',
      currentBuildNumber: 1,
      packageName: 'com.example.app',
      onUpdateComplete: () {
        print('Update completed!');
      },
      onNoUpdate: () {
        print('Already on latest version');
      },
      onError: (error) {
        print('Error checking update: $error');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My App')),
      body: Center(
        child: ElevatedButton(
          onPressed: _checkForUpdates,
          child: const Text('Check for Updates'),
        ),
      ),
    );
  }
}
