import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/providers/auth_provider.dart';
import '../data/upscale_repository.dart';

class UpscaleState {
  final String? imageUrl;
  final String? resultUrl;
  final bool isLoading;
  final String? error;

  const UpscaleState({this.imageUrl, this.resultUrl, this.isLoading = false, this.error});

  UpscaleState copyWith({String? imageUrl, String? resultUrl, bool? isLoading, String? error}) {
    return UpscaleState(
      imageUrl: imageUrl ?? this.imageUrl,
      resultUrl: resultUrl ?? this.resultUrl,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class UpscaleNotifier extends Notifier<UpscaleState> {
  @override
  UpscaleState build() => const UpscaleState();

  void setImageUrl(String url) => state = state.copyWith(imageUrl: url);

  Future<void> upscale(String enhancementFocus) async {
    if (state.imageUrl == null) return;
    final token = ref.read(authNotifierProvider);
    if (token is! AuthAuthenticated) { state = state.copyWith(error: 'Not authenticated'); return; }

    try {
      state = state.copyWith(isLoading: true, error: null);
      final repo = UpscaleRepository(ref.read(dioProvider), token.token);
      final result = await repo.upscale(state.imageUrl!, enhancementFocus);
      state = state.copyWith(resultUrl: result, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void reset() => state = const UpscaleState();
}

final upscaleNotifierProvider = NotifierProvider<UpscaleNotifier, UpscaleState>(() => UpscaleNotifier());