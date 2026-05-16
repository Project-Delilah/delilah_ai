import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/config.dart';
import '../../../core/services/secure_storage.dart';

class GalleryImage {
  final String url;
  final String? prompt;
  final DateTime createdAt;
  final String? publicId;

  GalleryImage({required this.url, this.prompt, required this.createdAt, this.publicId});

  factory GalleryImage.fromJson(Map<String, dynamic> json) {
    return GalleryImage(
      url: json['secure_url'] ?? json['url'] ?? '',
      prompt: json['prompt'],
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      publicId: json['public_id'],
    );
  }
}

class GalleryNotifier extends AsyncNotifier<List<GalleryImage>> {
  bool _hasLoadedOnce = false;

  @override
  Future<List<GalleryImage>> build() async {
    if (!_hasLoadedOnce) {
      _hasLoadedOnce = true;
      Future.microtask(() => fetchGallery());
    }
    return [];
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
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<bool> deleteImage(String publicId) async {
    try {
      final token = await SecureStorage.getToken();
      if (token == null || token.isEmpty) return false;

      final dio = Dio(BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        headers: {
          'Authorization': 'Bearer $token',
        },
      ));

      await dio.delete('/gallery', data: {'public_id': publicId});
      
      final currentImages = state.valueOrNull ?? [];
      state = AsyncData(currentImages.where((img) => img.publicId != publicId).toList());
      
      return true;
    } catch (e) {
      return false;
    }
  }
}

final galleryNotifierProvider = AsyncNotifierProvider<GalleryNotifier, List<GalleryImage>>(() => GalleryNotifier());