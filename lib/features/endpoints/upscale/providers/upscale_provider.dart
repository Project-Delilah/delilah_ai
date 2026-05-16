import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/cloudinary_service.dart';
import '../../../auth/providers/auth_provider.dart';
import '../data/upscale_repository.dart';

final upscaleCloudinaryServiceProvider = Provider<CloudinaryService>((ref) => CloudinaryService());

class UpscaleState {
  final File? imageFile;
  final String? imageUrl;
  final String? resultUrl;
  final bool isUploading;
  final bool isProcessing;
  final String? error;

  const UpscaleState({
    this.imageFile,
    this.imageUrl,
    this.resultUrl,
    this.isUploading = false,
    this.isProcessing = false,
    this.error,
  });

  UpscaleState copyWith({
    File? imageFile,
    String? imageUrl,
    String? resultUrl,
    bool? isUploading,
    bool? isProcessing,
    String? error,
  }) {
    return UpscaleState(
      imageFile: imageFile ?? this.imageFile,
      imageUrl: imageUrl ?? this.imageUrl,
      resultUrl: resultUrl ?? this.resultUrl,
      isUploading: isUploading ?? this.isUploading,
      isProcessing: isProcessing ?? this.isProcessing,
      error: error,
    );
  }
}

class UpscaleNotifier extends Notifier<UpscaleState> {
  @override
  UpscaleState build() => const UpscaleState();

  Future<void> setImage(File file) async {
    final cloudinary = ref.read(upscaleCloudinaryServiceProvider);
    final cachedUrl = cloudinary.getCachedUrl(file.path);
    
    if (cachedUrl != null) {
      state = state.copyWith(imageFile: file, imageUrl: cachedUrl);
      return;
    }

    state = state.copyWith(imageFile: file, imageUrl: null, isUploading: true, error: null);
    
    try {
      final url = await cloudinary.uploadImage(file);
      state = state.copyWith(imageUrl: url, isUploading: false);
    } catch (e) {
      state = state.copyWith(isUploading: false, error: e.toString());
    }
  }

  Future<void> upscale(String enhancementFocus) async {
    if (state.imageUrl == null) return;
    final token = ref.read(authNotifierProvider);
    if (token is! AuthAuthenticated) { state = state.copyWith(error: 'Not authenticated'); return; }

    try {
      state = state.copyWith(isProcessing: true, error: null);
      final repo = UpscaleRepository(ref.read(dioProvider), token.token);
      final result = await repo.upscale(state.imageUrl!, enhancementFocus);
      state = state.copyWith(resultUrl: result, isProcessing: false);
    } catch (e) {
      state = state.copyWith(isProcessing: false, error: e.toString());
    }
  }

  void reset() => state = const UpscaleState();
}

final upscaleNotifierProvider = NotifierProvider<UpscaleNotifier, UpscaleState>(() => UpscaleNotifier());