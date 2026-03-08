import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

enum DownloadState { idle, downloading, completed, failed, installing }

class DownloadProgress {
  final DownloadState state;
  final double progress;
  final String? filePath;
  final String? error;

  DownloadProgress({
    required this.state,
    this.progress = 0,
    this.filePath,
    this.error,
  });

  DownloadProgress copyWith({
    DownloadState? state,
    double? progress,
    String? filePath,
    String? error,
  }) {
    return DownloadProgress(
      state: state ?? this.state,
      progress: progress ?? this.progress,
      filePath: filePath ?? this.filePath,
      error: error ?? this.error,
    );
  }
}

class DownloadService {
  final Dio _dio = Dio();
  final Map<String, CancelToken> _cancelTokens = {};

  Future<String> _getDownloadPath(String filename) async {
    // Try to save in public Downloads folder (user visible)
    if (Platform.isAndroid) {
      final downloadDir = Directory('/storage/emulated/0/Download/DevStudio');
      if (!await downloadDir.exists()) {
        await downloadDir.create(recursive: true);
      }
      return '${downloadDir.path}/$filename';
    }

    // Fallback to app documents directory
    final dir = await getApplicationDocumentsDirectory();
    final downloadDir = Directory('${dir.path}/downloads');
    if (!await downloadDir.exists()) {
      await downloadDir.create(recursive: true);
    }
    return '${downloadDir.path}/$filename';
  }

  Stream<DownloadProgress> downloadFile({
    required String url,
    required String filename,
  }) async* {
    final cancelToken = CancelToken();
    _cancelTokens[url] = cancelToken;

    yield DownloadProgress(state: DownloadState.downloading, progress: 0);

    try {
      final filePath = await _getDownloadPath(filename);
      debugPrint('📥 Downloading to: $filePath');

      await _dio.download(
        url,
        filePath,
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = received / total;
            debugPrint('📥 Progress: ${(progress * 100).toStringAsFixed(1)}%');
          }
        },
      );

      yield DownloadProgress(
        state: DownloadState.completed,
        progress: 1.0,
        filePath: filePath,
      );
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        yield DownloadProgress(
          state: DownloadState.idle,
          error: 'Download cancelled',
        );
      } else {
        yield DownloadProgress(
          state: DownloadState.failed,
          error: e.message ?? 'Download failed',
        );
      }
    } catch (e) {
      yield DownloadProgress(state: DownloadState.failed, error: e.toString());
    } finally {
      _cancelTokens.remove(url);
    }
  }

  Future<DownloadProgress> downloadWithProgress({
    required String url,
    required String filename,
    required Function(double) onProgress,
    Function(int)? onSpeed,
    Function(int)? onComplete,
  }) async {
    final cancelToken = CancelToken();
    _cancelTokens[url] = cancelToken;

    try {
      final filePath = await _getDownloadPath(filename);
      debugPrint('📥 Downloading: $url');
      debugPrint('📥 To: $filePath');

      int lastReceived = 0;
      DateTime lastTime = DateTime.now();
      final startTime = DateTime.now();

      await _dio.download(
        url,
        filePath,
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = received / total;
            onProgress(progress);

            // Calculate speed
            final now = DateTime.now();
            final timeDiff = now.difference(lastTime).inMilliseconds;
            if (timeDiff >= 500 && onSpeed != null) {
              final bytesDiff = received - lastReceived;
              final speed = (bytesDiff * 1000 / timeDiff)
                  .round(); // bytes per second
              onSpeed(speed);
              lastReceived = received;
              lastTime = now;
            }
          }
        },
      );

      // Calculate total download time
      final totalTime = DateTime.now().difference(startTime).inSeconds;
      if (onComplete != null) {
        onComplete(totalTime);
      }

      return DownloadProgress(
        state: DownloadState.completed,
        progress: 1.0,
        filePath: filePath,
      );
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        return DownloadProgress(
          state: DownloadState.idle,
          error: 'Download cancelled',
        );
      }
      return DownloadProgress(
        state: DownloadState.failed,
        error: e.message ?? 'Download failed',
      );
    } catch (e) {
      return DownloadProgress(state: DownloadState.failed, error: e.toString());
    } finally {
      _cancelTokens.remove(url);
    }
  }

  void cancelDownload(String url) {
    _cancelTokens[url]?.cancel();
    _cancelTokens.remove(url);
  }

  void cancelAll() {
    for (final token in _cancelTokens.values) {
      token.cancel();
    }
    _cancelTokens.clear();
  }
}
