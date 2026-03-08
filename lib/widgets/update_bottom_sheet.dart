import 'dart:io';
import 'package:flutter/material.dart';
import '../models/app_release.dart';
import '../services/download_service.dart';
import '../services/install_service.dart';

class UpdateBottomSheet extends StatefulWidget {
  final AppRelease release;
  final VoidCallback? onUpdateComplete;

  const UpdateBottomSheet({
    super.key,
    required this.release,
    this.onUpdateComplete,
  });

  static Future<void> show(
    BuildContext context,
    AppRelease release, {
    VoidCallback? onUpdateComplete,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      builder: (context) => UpdateBottomSheet(
        release: release,
        onUpdateComplete: onUpdateComplete,
      ),
    );
  }

  @override
  State<UpdateBottomSheet> createState() => _UpdateBottomSheetState();
}

class _UpdateBottomSheetState extends State<UpdateBottomSheet> {
  final _downloadService = DownloadService();
  final _installService = InstallService();

  DownloadState _state = DownloadState.idle;
  double _progress = 0;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.system_update, size: 64, color: Colors.blue),
          const SizedBox(height: 16),
          Text(
            'Update Available',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Version ${widget.release.version}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (widget.release.releaseNotes != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                widget.release.releaseNotes!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
          const SizedBox(height: 24),
          if (_state == DownloadState.downloading ||
              _state == DownloadState.installing) ...[
            LinearProgressIndicator(value: _progress),
            const SizedBox(height: 8),
            Text(
              _state == DownloadState.downloading
                  ? 'Downloading... ${(_progress * 100).toInt()}%'
                  : 'Installing...',
            ),
          ] else if (_state == DownloadState.failed) ...[
            Text('Error: $_error', style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _startUpdate, child: const Text('Retry')),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Later'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _startUpdate,
                    child: const Text('Update Now'),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Powered by ',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
              ),
              Text(
                'DevStudio',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _startUpdate() async {
    if (!Platform.isAndroid) {
      setState(() {
        _error = 'Updates only supported on Android';
        _state = DownloadState.failed;
      });
      return;
    }

    // Find Android APK
    final androidAsset = widget.release.downloads.firstWhere(
      (asset) => asset.platform == 'android' && asset.type == 'apk',
      orElse: () => throw Exception('No Android APK found'),
    );

    setState(() {
      _state = DownloadState.downloading;
      _progress = 0;
      _error = null;
    });

    try {
      // Download
      final result = await _downloadService.downloadWithProgress(
        url: androidAsset.url,
        filename: androidAsset.filename,
        onProgress: (progress) {
          setState(() => _progress = progress);
        },
      );

      if (result.state == DownloadState.completed && result.filePath != null) {
        setState(() => _state = DownloadState.installing);

        // Install
        final installed = await _installService.installApk(result.filePath!);

        if (installed) {
          widget.onUpdateComplete?.call();
          if (mounted) Navigator.pop(context);
        } else {
          setState(() {
            _error = 'Installation failed';
            _state = DownloadState.failed;
          });
        }
      } else {
        setState(() {
          _error = result.error ?? 'Download failed';
          _state = DownloadState.failed;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _state = DownloadState.failed;
      });
    }
  }
}
