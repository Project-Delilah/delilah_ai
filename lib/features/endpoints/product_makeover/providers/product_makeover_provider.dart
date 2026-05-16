import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/cloudinary_service.dart';
import '../../../auth/providers/auth_provider.dart';
import '../data/product_makeover_repository.dart';

final productMakeoverCloudinaryServiceProvider = Provider<CloudinaryService>((ref) => CloudinaryService());

class ProductMakeoverState {
  final File? imageFile;
  final String? imageUrl;
  final String? resultUrl;
  final bool isUploading;
  final bool isProcessing;
  final String? error;

  const ProductMakeoverState({
    this.imageFile,
    this.imageUrl,
    this.resultUrl,
    this.isUploading = false,
    this.isProcessing = false,
    this.error,
  });

  ProductMakeoverState copyWith({
    File? imageFile,
    String? imageUrl,
    String? resultUrl,
    bool? isUploading,
    bool? isProcessing,
    String? error,
  }) {
    return ProductMakeoverState(
      imageFile: imageFile ?? this.imageFile,
      imageUrl: imageUrl ?? this.imageUrl,
      resultUrl: resultUrl ?? this.resultUrl,
      isUploading: isUploading ?? this.isUploading,
      isProcessing: isProcessing ?? this.isProcessing,
      error: error,
    );
  }
}

class ProductMakeoverNotifier extends Notifier<ProductMakeoverState> {
  @override
  ProductMakeoverState build() => const ProductMakeoverState();

  Future<void> setImage(File file) async {
    final cloudinary = ref.read(productMakeoverCloudinaryServiceProvider);
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

  Future<void> makeover(String backgroundContext) async {
    if (state.imageUrl == null) return;
    final token = ref.read(authNotifierProvider);
    if (token is! AuthAuthenticated) { state = state.copyWith(error: 'Not authenticated'); return; }

    try {
      state = state.copyWith(isProcessing: true, error: null);
      final repo = ProductMakeoverRepository(ref.read(dioProvider), token.token);
      final result = await repo.makeover(state.imageUrl!, backgroundContext);
      state = state.copyWith(resultUrl: result, isProcessing: false);
    } catch (e) {
      state = state.copyWith(isProcessing: false, error: e.toString());
    }
  }

  void reset() => state = const ProductMakeoverState();
}

final productMakeoverNotifierProvider = NotifierProvider<ProductMakeoverNotifier, ProductMakeoverState>(() => ProductMakeoverNotifier());