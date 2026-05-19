import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import '../../../core/config.dart';
import '../../../core/services/secure_storage.dart';
import '../../../shared/widgets/video_player_widget.dart';

enum MediaType { image, video }

class GalleryImage {
  final String url;
  final String? prompt;
  final DateTime createdAt;
  final String? publicId;
  final MediaType type;
  final VideoAspectRatio aspectRatio;

  GalleryImage({
    required this.url, 
    this.prompt, 
    required this.createdAt, 
    this.publicId,
    this.type = MediaType.image,
    this.aspectRatio = VideoAspectRatio.portrait9x16,
  });

  factory GalleryImage.fromJson(Map<String, dynamic> json) {
    final url = json['secure_url'] ?? json['url'] ?? '';
    final type = _detectMediaType(url);
    final aspectRatio = _detectAspectRatio(json);
    
    return GalleryImage(
      url: url,
      prompt: json['prompt'],
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      publicId: json['public_id'],
      type: type,
      aspectRatio: aspectRatio,
    );
  }

  Map<String, dynamic> toJson() => {
    'url': url,
    'prompt': prompt,
    'created_at': createdAt.toIso8601String(),
    'public_id': publicId,
    'type': type.name,
    'aspect_ratio': aspectRatio.name,
  };

  static MediaType _detectMediaType(String url) {
    final lowerUrl = url.toLowerCase();
    if (lowerUrl.contains('/video/') || 
        lowerUrl.endsWith('.mp4') || 
        lowerUrl.endsWith('.mov') ||
        lowerUrl.endsWith('.webm') ||
        lowerUrl.contains('veo_studio')) {
      return MediaType.video;
    }
    return MediaType.image;
  }

  static VideoAspectRatio _detectAspectRatio(Map<String, dynamic> json) {
    if (json['aspect_ratio'] != null) {
      final ratio = json['aspect_ratio'].toString();
      if (ratio == '16:9') return VideoAspectRatio.landscape16x9;
      if (ratio == '9:16') return VideoAspectRatio.portrait9x16;
    }
    
    final publicId = json['public_id']?.toString().toLowerCase() ?? '';
    if (publicId.contains('16x9') || publicId.contains('landscape')) {
      return VideoAspectRatio.landscape16x9;
    }
    
    return VideoAspectRatio.portrait9x16;
  }

  bool get isVideo => type == MediaType.video;
  bool get isImage => type == MediaType.image;

  String? get publicIdFromUrl {
    if (!url.contains('cloudinary.com')) return null;
    try {
      final parts = url.split('/upload/');
      if (parts.length < 2) return null;
      String path = parts[1];
      path = path.replaceAll(RegExp(r'\.(mp4|jpg|jpeg|png|webp|mov)$'), '');
      return path;
    } catch (_) {
      return null;
    }
  }
}

class GalleryNotifier extends AsyncNotifier<List<GalleryImage>> {
  bool _hasLoadedOnce = false;
  static const String _boxName = 'gallery_cache';
  static const String _key = 'cached_images';

  @override
  Future<List<GalleryImage>> build() async {
    if (!_hasLoadedOnce) {
      _hasLoadedOnce = true;
      await _loadFromCache();
    }
    return [];
  }

  Future<void> _loadFromCache() async {
    try {
      await Hive.initFlutter();
      final box = await Hive.openBox(_boxName);
      final cached = box.get(_key);
      if (cached != null) {
        final List<dynamic> jsonList = jsonDecode(cached as String);
        final images = jsonList.map((e) => GalleryImage.fromJson(e as Map<String, dynamic>)).toList();
        state = AsyncData(images);
      }
    } catch (_) {}
  }

  Future<void> _saveToCache(List<GalleryImage> images) async {
    try {
      final box = await Hive.openBox(_boxName);
      final jsonList = images.map((e) => e.toJson()).toList();
      await box.put(_key, jsonEncode(jsonList));
    } catch (_) {}
  }

  Future<void> fetchGallery() async {
    state = const AsyncLoading();
    
    try {
      final token = await SecureStorage.getToken();
      if (token == null || token.isEmpty) {
        state = const AsyncData([]);
        return;
      }

      final dio = Dio(BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        headers: {
          'Authorization': 'Bearer $token',
        },
      ));

      final response = await dio.get('/gallery');
      
      List<GalleryImage> images = [];
      if (response.data != null) {
        if (response.data is List) {
          images = (response.data as List)
              .map((e) => GalleryImage.fromJson(e))
              .toList();
        } else if (response.data['images'] != null) {
          images = (response.data['images'] as List)
              .map((e) => GalleryImage.fromJson(e))
              .toList();
        }
      }
      
      state = AsyncData(images);
      await _saveToCache(images);
    } catch (e, st) {
      final cached = state.valueOrNull;
      if (cached != null && cached.isNotEmpty) {
        state = AsyncData(cached);
      } else {
        state = AsyncError(e, st);
      }
    }
  }

  Future<bool> deleteImage(String? publicId, {String? url}) async {
    try {
      final token = await SecureStorage.getToken();
      if (token == null || token.isEmpty) return false;

      final effectivePublicId = publicId ?? (url != null ? _extractPublicIdFromUrl(url) : null);
      debugPrint('Delete: publicId=$publicId, url=$url, effective=$effectivePublicId');
      if (effectivePublicId == null) return false;

      final dio = Dio(BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        headers: {
          'Authorization': 'Bearer $token',
        },
      ));

      debugPrint('Delete request to /gallery with public_id: $effectivePublicId');
      await dio.delete('/gallery', data: {
        'public_id': effectivePublicId,
        'resource_type': 'image',
      });
      debugPrint('Delete request completed');
      
      final currentImages = state.valueOrNull ?? [];
      final updatedImages = currentImages.where((img) => 
        img.publicId != effectivePublicId && img.publicIdFromUrl != effectivePublicId
      ).toList();
      state = AsyncData(updatedImages);
      await _saveToCache(updatedImages);
      
      return true;
    } catch (e, st) {
      debugPrint('Delete failed: $e $st');
      return false;
    }
  }

  String? _extractPublicIdFromUrl(String url) {
    try {
      final parts = url.split('/upload/');
      if (parts.length < 2) return null;
      String path = parts[1];
      path = path.replaceAll(RegExp(r'\.(mp4|jpg|jpeg|png|webp|mov)$'), '');
      return path;
    } catch (_) {
      return null;
    }
  }

  Future<void> clearCache() async {
    try {
      final box = await Hive.openBox(_boxName);
      await box.delete(_key);
    } catch (_) {}
  }
}

final galleryNotifierProvider = AsyncNotifierProvider<GalleryNotifier, List<GalleryImage>>(() => GalleryNotifier());