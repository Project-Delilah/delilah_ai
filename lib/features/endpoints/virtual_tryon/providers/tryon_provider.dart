import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../../core/services/cloudinary_service.dart';
import '../data/tryon_repository.dart';

final cloudinaryServiceProvider = Provider<CloudinaryService>((ref) => CloudinaryService());

class TryOnState {
  final File? personImage;
  final File? productImage;
  final String? personImageUrl;
  final String? productImageUrl;
  final String? resultUrl;
  final bool isUploading;
  final bool isGenerating;
  final String? error;

  TryOnState({
    this.personImage,
    this.productImage,
    this.personImageUrl,
    this.productImageUrl,
    this.resultUrl,
    this.isUploading = false,
    this.isGenerating = false,
    this.error,
  });

  TryOnState copyWith({
    File? personImage,
    File? productImage,
    String? personImageUrl,
    String? productImageUrl,
    String? resultUrl,
    bool? isUploading,
    bool? isGenerating,
    String? error,
  }) {
    return TryOnState(
      personImage: personImage ?? this.personImage,
      productImage: productImage ?? this.productImage,
      personImageUrl: personImageUrl ?? this.personImageUrl,
      productImageUrl: productImageUrl ?? this.productImageUrl,
      resultUrl: resultUrl ?? this.resultUrl,
      isUploading: isUploading ?? this.isUploading,
      isGenerating: isGenerating ?? this.isGenerating,
      error: error,
    );
  }
}

class TryOnNotifier extends Notifier<TryOnState> {
  @override
  TryOnState build() => TryOnState();

  Future<void> setPersonImage(File file) async {
    final cloudinary = ref.read(cloudinaryServiceProvider);
    final cachedUrl = cloudinary.getCachedUrl(file.path);
    
    if (cachedUrl != null) {
      state = state.copyWith(personImage: file, personImageUrl: cachedUrl);
      return;
    }

    state = state.copyWith(personImage: file, personImageUrl: null, isUploading: true, error: null);
    
    try {
      final url = await cloudinary.uploadImage(file);
      state = state.copyWith(personImageUrl: url, isUploading: false);
    } catch (e) {
      state = state.copyWith(isUploading: false, error: e.toString());
    }
  }

  Future<void> setProductImage(File file) async {
    final cloudinary = ref.read(cloudinaryServiceProvider);
    final cachedUrl = cloudinary.getCachedUrl(file.path);
    
    if (cachedUrl != null) {
      state = state.copyWith(productImage: file, productImageUrl: cachedUrl);
      return;
    }

    state = state.copyWith(productImage: file, productImageUrl: null, isUploading: true, error: null);
    
    try {
      final url = await cloudinary.uploadImage(file);
      state = state.copyWith(productImageUrl: url, isUploading: false);
    } catch (e) {
      state = state.copyWith(isUploading: false, error: e.toString());
    }
  }

  Future<void> generate() async {
    if (state.personImageUrl == null || state.productImageUrl == null) return;
    
    final token = ref.read(authNotifierProvider);
    if (token is! AuthAuthenticated) return;

    state = state.copyWith(isGenerating: true, error: null);
    
    try {
      final repo = TryOnRepository(ref.read(dioProvider), token.token);
      final result = await repo.tryOn(state.personImageUrl!, state.productImageUrl!);
      state = state.copyWith(resultUrl: result, isGenerating: false);
    } catch (e) {
      state = state.copyWith(isGenerating: false, error: e.toString());
    }
  }

  void reset() {
    state = TryOnState();
  }
}

final tryOnNotifierProvider = NotifierProvider<TryOnNotifier, TryOnState>(() => TryOnNotifier());