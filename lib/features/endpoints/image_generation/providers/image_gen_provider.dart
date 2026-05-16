import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/providers/auth_provider.dart';
import '../data/image_gen_repository.dart';

class ImageGenNotifier extends AsyncNotifier<String?> {
  @override
  FutureOr<String?> build() => null;

  Future<void> generate(String prompt) async {
    final token = ref.read(authNotifierProvider);
    if (token is! AuthAuthenticated) {
      state = AsyncData(null);
      return;
    }

    try {
      state = const AsyncLoading();
      final repo = ImageGenRepository(ref.read(dioProvider), token.token);
      final result = await repo.generate(prompt);
      state = AsyncData(result);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  void reset() => state = const AsyncData(null);
}

final imageGenNotifierProvider = AsyncNotifierProvider<ImageGenNotifier, String?>(() => ImageGenNotifier());