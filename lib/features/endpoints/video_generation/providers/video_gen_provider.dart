import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/providers/auth_provider.dart';
import '../data/video_gen_repository.dart';

class VideoGenState {
  final bool isGenerating;
  final String? statusMessage;
  final String? resultUrl;
  final String? error;
  final String? prompt;
  final String? imageUrl;

  const VideoGenState({
    this.isGenerating = false,
    this.statusMessage,
    this.resultUrl,
    this.error,
    this.prompt,
    this.imageUrl,
  });

  VideoGenState copyWith({
    bool? isGenerating,
    String? statusMessage,
    String? resultUrl,
    String? error,
    String? prompt,
    String? imageUrl,
  }) {
    return VideoGenState(
      isGenerating: isGenerating ?? this.isGenerating,
      statusMessage: statusMessage ?? this.statusMessage,
      resultUrl: resultUrl ?? this.resultUrl,
      error: error ?? this.error,
      prompt: prompt ?? this.prompt,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  VideoGenState clearResult() {
    return const VideoGenState();
  }
}

class VideoGenNotifier extends Notifier<VideoGenState> {
  @override
  VideoGenState build() => const VideoGenState();

  Future<void> generateTextToVideo({
    required String prompt,
    required VeoAspectRatio aspectRatio,
    required Resolution resolution,
    required int durationSeconds,
  }) async {
    final token = ref.read(authNotifierProvider);
    if (token is! AuthAuthenticated) {
      state = state.copyWith(error: 'Not authenticated');
      return;
    }

    state = state.copyWith(
      isGenerating: true,
      statusMessage: 'Initializing...',
      resultUrl: null,
      error: null,
      prompt: prompt,
      imageUrl: null,
    );

    try {
      final repo = VideoGenRepository(ref.read(dioProvider), token.token);

      await for (final status in repo.veoTextToVideo(
        prompt: prompt,
        aspectRatio: aspectRatio,
        resolution: resolution,
        durationSeconds: durationSeconds,
      )) {
        if (status.status == 'processing') {
          state = state.copyWith(statusMessage: status.message);
        } else if (status.status == 'success') {
          state = state.copyWith(
            isGenerating: false,
            statusMessage: 'Complete!',
            resultUrl: status.secureUrl,
          );
          break;
        } else if (status.status == 'error') {
          state = state.copyWith(
            isGenerating: false,
            error: status.error,
          );
          break;
        }
      }
    } catch (e) {
      state = state.copyWith(isGenerating: false, error: e.toString());
    }
  }

  Future<void> generateImageToVideo({
    required String prompt,
    required String imageUrl,
    required VeoAspectRatio aspectRatio,
    required Resolution resolution,
    required int durationSeconds,
  }) async {
    final token = ref.read(authNotifierProvider);
    if (token is! AuthAuthenticated) {
      state = state.copyWith(error: 'Not authenticated');
      return;
    }

    state = state.copyWith(
      isGenerating: true,
      statusMessage: 'Initializing...',
      resultUrl: null,
      error: null,
      prompt: prompt,
      imageUrl: imageUrl,
    );

    try {
      final repo = VideoGenRepository(ref.read(dioProvider), token.token);

      await for (final status in repo.veoImageToVideo(
        prompt: prompt,
        imageUrl: imageUrl,
        aspectRatio: aspectRatio,
        resolution: resolution,
        durationSeconds: durationSeconds,
      )) {
        if (status.status == 'processing') {
          state = state.copyWith(statusMessage: status.message);
        } else if (status.status == 'success') {
          state = state.copyWith(
            isGenerating: false,
            statusMessage: 'Complete!',
            resultUrl: status.secureUrl,
          );
          break;
        } else if (status.status == 'error') {
          state = state.copyWith(
            isGenerating: false,
            error: status.error,
          );
          break;
        }
      }
    } catch (e) {
      state = state.copyWith(isGenerating: false, error: e.toString());
    }
  }

  void reset() {
    state = const VideoGenState();
  }
}

final videoGenNotifierProvider = NotifierProvider<VideoGenNotifier, VideoGenState>(() => VideoGenNotifier());