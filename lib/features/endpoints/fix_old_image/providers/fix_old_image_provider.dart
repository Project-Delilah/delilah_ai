import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/providers/auth_provider.dart';
import '../data/fix_old_image_repository.dart';

class FixOldImageState {
  final String? imageUrl;
  final String? resultUrl;
  final bool isLoading;
  final String? error;

  const FixOldImageState({this.imageUrl, this.resultUrl, this.isLoading = false, this.error});

  FixOldImageState copyWith({String? imageUrl, String? resultUrl, bool? isLoading, String? error}) {
    return FixOldImageState(imageUrl: imageUrl ?? this.imageUrl, resultUrl: resultUrl ?? this.resultUrl, isLoading: isLoading ?? this.isLoading, error: error);
  }
}

class FixOldImageNotifier extends Notifier<FixOldImageState> {
  @override
  FixOldImageState build() => const FixOldImageState();

  void setImageUrl(String url) => state = state.copyWith(imageUrl: url);

  Future<void> fixImage(String repairInstructions) async {
    if (state.imageUrl == null) return;
    final token = ref.read(authNotifierProvider);
    if (token is! AuthAuthenticated) { state = state.copyWith(error: 'Not authenticated'); return; }

    try {
      state = state.copyWith(isLoading: true, error: null);
      final repo = FixOldImageRepository(ref.read(dioProvider), token.token);
      final result = await repo.fixImage(state.imageUrl!, repairInstructions);
      state = state.copyWith(resultUrl: result, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void reset() => state = const FixOldImageState();
}

final fixOldImageNotifierProvider = NotifierProvider<FixOldImageNotifier, FixOldImageState>(() => FixOldImageNotifier());