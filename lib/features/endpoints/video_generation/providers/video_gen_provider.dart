import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../../core/services/cloudinary_service.dart';
import '../data/video_gen_repository.dart';

final cloudinaryServiceProvider = Provider<CloudinaryService>((ref) => CloudinaryService());

class VideoGenState {
  final File? selectedImage;
  final String? selectedImageUrl;
  final bool isUploading;
  final bool isGenerating;
  final String? statusMessage;
  final String? resultUrl;
  final String? error;
  final String? prompt;

  const VideoGenState({
    this.selectedImage,
    this.selectedImageUrl,
    this.isUploading = false,
    this.isGenerating = false,
    this.statusMessage,
    this.resultUrl,
    this.error,
    this.prompt,
  });

  VideoGenState copyWith({
    File? selectedImage,
    String? selectedImageUrl,
    bool? isUploading,
    bool? isGenerating,
    String? statusMessage,
    String? resultUrl,
    String? error,
    String? prompt,
  }) {
    return VideoGenState(
      selectedImage: selectedImage ?? this.selectedImage,
      selectedImageUrl: selectedImageUrl ?? this.selectedImageUrl,
      isUploading: isUploading ?? this.isUploading,
      isGenerating: isGenerating ?? this.isGenerating,
      statusMessage: statusMessage ?? this.statusMessage,
      resultUrl: resultUrl ?? this.resultUrl,
      error: error,
      prompt: prompt ?? this.prompt,
    );
  }

  VideoGenState clearImage() {
    return VideoGenState(
      isUploading: isUploading,
      isGenerating: isGenerating,
      statusMessage: statusMessage,
      resultUrl: resultUrl,
      error: error,
      prompt: prompt,
    );
  }

  VideoGenState clearResult() {
    return const VideoGenState();
  }
}

class VideoGenNotifier extends Notifier<VideoGenState> {
  @override
  VideoGenState build() => const VideoGenState();

  Future<void> setImage(File file) async {
    final cloudinary = ref.read(cloudinaryServiceProvider);
    final cachedUrl = cloudinary.getCachedUrl(file.path);
    
    if (cachedUrl != null) {
      state = state.copyWith(selectedImage: file, selectedImageUrl: cachedUrl);
      return;
    }

    state = state.copyWith(selectedImage: file, selectedImageUrl: null, isUploading: true, error: null);
    
    try {
      final url = await cloudinary.uploadImage(file);
      state = state.copyWith(selectedImageUrl: url, isUploading: false);
    } catch (e) {
      state = state.copyWith(isUploading: false, error: e.toString());
    }
  }

  void clearImage() {
    state = state.clearImage();
  }

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
    required VeoAspectRatio aspectRatio,
    required Resolution resolution,
    required int durationSeconds,
  }) async {
    if (state.selectedImageUrl == null) {
      state = state.copyWith(error: 'Please upload an image first');
      return;
    }

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
    );

    try {
      final repo = VideoGenRepository(ref.read(dioProvider), token.token);

      await for (final status in repo.veoImageToVideo(
        prompt: prompt,
        imageUrl: state.selectedImageUrl!,
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