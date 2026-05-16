import 'dart:io';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class WallpaperEngine {
  static const _channel = MethodChannel('delilah/wallpaper');

  static Future<bool> applyFromUrl(String imageUrl) async {
    try {
      final response = await http.get(Uri.parse(imageUrl));
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/delilah_wallpaper.jpg');
      await file.writeAsBytes(response.bodyBytes);

      final result = await _channel.invokeMethod<bool>('setWallpaper', {
        'filePath': file.path,
      });
      return result ?? false;
    } catch (_) {
      return false;
    }
  }
}