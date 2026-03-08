import 'package:flutter/material.dart';

/// Represents a downloadable asset (APK, EXE, etc.)
class DownloadAsset {
  final String platform;
  final String type;
  final String? arch;
  final String url;
  final String filename;
  final int size;

  DownloadAsset({
    required this.platform,
    required this.type,
    this.arch,
    required this.url,
    required this.filename,
    required this.size,
  });

  factory DownloadAsset.fromJson(Map<String, dynamic> json) {
    final filename = json['filename'] ?? '';

    // Extract arch from JSON or parse from filename
    String? arch = json['arch'];
    if (arch == null && filename.isNotEmpty) {
      arch = _extractArchFromFilename(filename);
    }

    return DownloadAsset(
      platform: json['platform'] ?? 'unknown',
      type: json['type'] ?? '',
      arch: arch,
      url: json['url'] ?? '',
      filename: filename,
      size: json['size'] ?? 0,
    );
  }

  /// Extract architecture from filename patterns
  static String? _extractArchFromFilename(String filename) {
    final lower = filename.toLowerCase();

    // Check for common arch patterns in filename
    if (lower.contains('universal')) {
      return 'universal';
    }
    if (lower.contains('arm64') ||
        lower.contains('arm64-v8a') ||
        lower.contains('v8a')) {
      return 'arm64';
    }
    if (lower.contains('arm32') ||
        lower.contains('armeabi-v7a') ||
        lower.contains('v7a') ||
        lower.contains('armeabi')) {
      return 'arm32';
    }
    if (lower.contains('x86_64') || lower.contains('x86-64')) return 'x86_64';
    if (lower.contains('x86') && !lower.contains('x86_64')) return 'x86';

    return null;
  }

  String get formattedSize {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String get displayName {
    final archLabel = arch != null ? ' ($arch)' : '';
    return '${platform.toUpperCase()} ${type.toUpperCase()}$archLabel';
  }

  IconData get platformIcon {
    switch (platform.toLowerCase()) {
      case 'android':
        return Icons.android;
      case 'windows':
        return Icons.desktop_windows;
      case 'linux':
        return Icons.computer;
      case 'macos':
        return Icons.laptop_mac;
      case 'ios':
        return Icons.phone_iphone;
      default:
        return Icons.download;
    }
  }
}

class AppRelease {
  final String id;
  final String packageName;
  final String appName;
  final String repository;
  final String repositoryUrl;
  final String tag;
  final String version;
  final int buildNumber;
  final String? description;
  final String? releaseNotes;
  final String? apkUrl;
  final int? apkSize;
  final DateTime publishedAt;
  final String? iconUrl;
  final String channel;
  final bool isBeta;
  final List<DownloadAsset> downloads;
  final List<String> screenshots;

  AppRelease({
    required this.id,
    required this.packageName,
    required this.appName,
    this.repository = '',
    this.repositoryUrl = '',
    this.tag = '',
    required this.version,
    required this.buildNumber,
    this.description,
    this.releaseNotes,
    this.apkUrl,
    this.apkSize,
    required this.publishedAt,
    this.iconUrl,
    this.channel = 'official',
    this.isBeta = false,
    this.downloads = const [],
    this.screenshots = const [],
  });

  factory AppRelease.fromJson(Map<String, dynamic> json) {
    final downloadsList =
        (json['downloads'] as List<dynamic>?)
            ?.map((d) => DownloadAsset.fromJson(d as Map<String, dynamic>))
            .toList() ??
        [];

    // Parse screenshots - filter out empty strings
    final screenshotsList =
        (json['screenshots'] as List<dynamic>?)
            ?.map((s) => s.toString())
            .where((s) => s.isNotEmpty)
            .toList() ??
        [];

    return AppRelease(
      id: json['id']?.toString() ?? '',
      packageName: json['package_name'] ?? '',
      appName: json['app_name'] ?? 'Unknown App',
      repository: json['repository'] ?? '',
      repositoryUrl: json['repository_url'] ?? '',
      tag: json['tag'] ?? '',
      version: json['version'] ?? '1.0.0',
      buildNumber: json['build_number'] ?? 1,
      description: json['description'],
      releaseNotes: json['release_notes'],
      apkUrl: json['apk_url'],
      apkSize: json['apk_size'],
      publishedAt: json['release_date'] != null
          ? DateTime.parse(json['release_date'])
          : DateTime.now(),
      iconUrl: json['icon_url'],
      channel: json['channel'] ?? 'official',
      isBeta: json['is_beta'] ?? false,
      downloads: downloadsList,
      screenshots: screenshotsList,
    );
  }

  String get formattedSize {
    if (apkSize == null) return 'Unknown';
    if (apkSize! < 1024) return '$apkSize B';
    if (apkSize! < 1024 * 1024) {
      return '${(apkSize! / 1024).toStringAsFixed(1)} KB';
    }
    return '${(apkSize! / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String get shortDescription {
    if (description == null || description!.isEmpty) {
      return 'No description available';
    }
    final desc = description!.trim();
    if (desc.length <= 80) return desc;
    return '${desc.substring(0, 80)}...';
  }

  String get channelLabel => isBeta ? 'Beta' : 'Stable';

  Map<String, List<DownloadAsset>> get downloadsByPlatform {
    final grouped = <String, List<DownloadAsset>>{};
    for (final asset in downloads) {
      grouped.putIfAbsent(asset.platform, () => []).add(asset);
    }
    return grouped;
  }

  List<String> get availablePlatforms {
    return downloads.map((d) => d.platform).toSet().toList();
  }

  bool get hasAndroid => downloads.any((d) => d.platform == 'android');
  bool get hasWindows => downloads.any((d) => d.platform == 'windows');
  bool get hasLinux => downloads.any((d) => d.platform == 'linux');
  bool get hasMacOS => downloads.any((d) => d.platform == 'macos');
}
