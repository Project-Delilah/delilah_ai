import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class UpdateInfo {
  final String version;
  final String downloadUrl;
  final String? releaseNotes;
  final bool isForced;
  final String tagName;
  final int sizeBytes;

  UpdateInfo({
    required this.version,
    required this.downloadUrl,
    this.releaseNotes,
    this.isForced = false,
    this.tagName = '',
    this.sizeBytes = 0,
  });

  String get sizeFormatted {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class OtaUpdateService {
  final Dio _dio = Dio();
  static const String _githubRepo = 'Project-Delilah/delilah_ai';
  static const String _githubApiUrl = 'https://api.github.com/repos/$_githubRepo/releases/latest';

  static const String _currentVersion = '1.0.18';

  String get currentVersion => _currentVersion;

  Future<UpdateInfo?> checkForUpdate() async {
    try {
      debugPrint('OTA: Checking for updates...');
      debugPrint('OTA: Current version: $_currentVersion');

      final response = await _dio.get(
        _githubApiUrl,
        options: Options(
          headers: {
            'Accept': 'application/vnd.github+json',
            'X-GitHub-Api-Version': '2022-11-28',
          },
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        final latestVersion = _extractVersion(data['tag_name'] ?? '');
        debugPrint('OTA: Latest release: ${data['tag_name']} ($latestVersion)');

        if (_compareVersions(latestVersion, _currentVersion) > 0) {
          debugPrint('OTA: Update available!');
          final assets = data['assets'] as List? ?? [];
          String? downloadUrl;
          int sizeBytes = 0;

          for (final asset in assets) {
            final name = asset['name']?.toString() ?? '';
            debugPrint('OTA: Asset: $name');
            if (name.contains('armeabi-v7a') || name.contains('arm64-v8a')) {
              downloadUrl = asset['browser_download_url'];
              sizeBytes = asset['size'] ?? 0;
              debugPrint('OTA: Found matching APK: $downloadUrl');
              break;
            }
          }

          if (downloadUrl != null) {
            return UpdateInfo(
              version: latestVersion,
              downloadUrl: downloadUrl,
              releaseNotes: data['body'],
              isForced: false,
              tagName: data['tag_name'] ?? '',
              sizeBytes: sizeBytes,
            );
          }
        } else {
          debugPrint('OTA: No update needed');
        }
      }
      return null;
    } catch (e) {
      debugPrint('OTA: Update check failed: $e');
      return null;
    }
  }

  Future<String?> downloadUpdate(UpdateInfo info, {
    void Function(int received, int total)? onProgress,
  }) async {
    try {
      final response = await _dio.download(
        info.downloadUrl,
        '/data/local/tmp/delilah_update.apk',
        onReceiveProgress: onProgress,
      );

      if (response.statusCode == 200) {
        return '/data/local/tmp/delilah_update.apk';
      }
      return null;
    } catch (e) {
      debugPrint('Download failed: $e');
      return null;
    }
  }

  Future<bool> installUpdate(String apkPath) async {
    try {
      final result = await Process.run('su', ['-c', 'pm install -r -d $apkPath']);
      if (result.exitCode != 0) {
        final fallback = await Process.run('pm', ['install', '-r', '-d', apkPath]);
        return fallback.exitCode == 0;
      }
      return result.exitCode == 0;
    } catch (e) {
      debugPrint('Install failed: $e');
      try {
        final fallback = await Process.run('pm', ['install', '-r', '-d', apkPath]);
        return fallback.exitCode == 0;
      } catch (_) {
        return false;
      }
    }
  }

  String _extractVersion(String tagName) {
    return tagName.replaceAll(RegExp(r'^v'), '');
  }

  int _compareVersions(String a, String b) {
    final partsA = a.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final partsB = b.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    for (var i = 0; i < 3; i++) {
      final vA = i < partsA.length ? partsA[i] : 0;
      final vB = i < partsB.length ? partsB[i] : 0;
      if (vA > vB) return 1;
      if (vA < vB) return -1;
    }
    return 0;
  }
}

final otaUpdateService = OtaUpdateService();