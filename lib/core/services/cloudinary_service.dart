import 'dart:io';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import '../config.dart';

class CloudinaryService {
  final Dio _dio;
  final Map<String, String> _urlCache = {};

  CloudinaryService() : _dio = Dio();

  Future<String> uploadImage(File file) async {
    final filePath = file.path;
    
    // Check cache first
    if (_urlCache.containsKey(filePath)) {
      return _urlCache[filePath]!;
    }

    final fileName = file.path.split('/').last;
    final extension = fileName.split('.').last.toLowerCase();
    final mimeType = _getMimeType(extension);

    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        await file.readAsBytes(),
        filename: fileName,
        contentType: MediaType.parse(mimeType),
      ),
      'upload_preset': AppConfig.cloudinaryPreset,
      'cloud_name': AppConfig.cloudinaryCloud,
    });

    final response = await _dio.post(
      'https://api.cloudinary.com/v1_1/${AppConfig.cloudinaryCloud}/image/upload',
      data: formData,
    );

    final url = response.data['secure_url'];
    _urlCache[filePath] = url;
    return url;
  }

  void clearCache() {
    _urlCache.clear();
  }

  String? getCachedUrl(String filePath) {
    return _urlCache[filePath];
  }

  String _getMimeType(String extension) {
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      default:
        return 'image/jpeg';
    }
  }
}