import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/providers/auth_provider.dart';
import '../data/image_edit_repository.dart';

class ImageEditState {
  final String? imageUrl;
  final String? resultUrl;
  final bool isLoading;
  final String? error;

  const ImageEditState({
    this.imageUrl,
    this.resultUrl,
    this.isLoading = false,
    this.error,
  });

  ImageEditState copyWith({
    String? imageUrl,
    String? resultUrl,
    bool? isLoading,
    String? error,
  }) {
    return ImageEditState(
      imageUrl: imageUrl ?? this.imageUrl,
      resultUrl: resultUrl ?? this.resultUrl,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class ImageEditNotifier extends Notifier<ImageEditState> {
  @override
  ImageEditState build() => const ImageEditState();

  Future<void> pickImage(String url) async {
    state = state.copyWith(imageUrl: url);
  }

  Future<void> editImage(String editPrompt) async {
    if (state.imageUrl == null) return;

    final token = ref.read(authNotifierProvider);
    if (token is! AuthAuthenticated) {
      state = state.copyWith(error: 'Not authenticated');
      return;
    }

    try {
      state = state.copyWith(isLoading: true, error: null);
      final repo = ImageEditRepository(ref.read(dioProvider), token.token);
      final result = await repo.editImage(state.imageUrl!, editPrompt);
      state = state.copyWith(resultUrl: result, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void reset() => state = const ImageEditState();
}

final imageEditNotifierProvider = NotifierProvider<ImageEditNotifier, ImageEditState>(() => ImageEditNotifier());