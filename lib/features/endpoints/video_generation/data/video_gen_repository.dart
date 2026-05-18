import 'dart:convert';
import 'package:dio/dio.dart';

enum VeoAspectRatio { ratio16x9, ratio9x16 }

enum Resolution { res720p, res1080p, res4k }

class VeoStatus {
  final String status;
  final String? message;
  final String? secureUrl;
  final String? error;

  VeoStatus({required this.status, this.message, this.secureUrl, this.error});

  factory VeoStatus.fromSSE(String data) {
    final trimmed = data.startsWith('data: ') ? data.substring(6) : data;
    final json = jsonDecode(trimmed);
    return VeoStatus(
      status: json['status'] ?? 'unknown',
      message: json['message'],
      secureUrl: json['secure_url'],
      error: json['error'],
    );
  }
}

class VideoGenRepository {
  final Dio _dio;
  final String _token;

  VideoGenRepository(this._dio, this._token);

  Stream<VeoStatus> veoTextToVideo({
    required String prompt,
    required VeoAspectRatio aspectRatio,
    required Resolution resolution,
    required int durationSeconds,
  }) async* {
    final aspectRatioStr = aspectRatio == VeoAspectRatio.ratio16x9 ? '16:9' : '9:16';
    final resolutionStr = _resolutionToString(resolution);

    final response = await _dio.post(
      '/veo',
      data: {
        'prompt': prompt,
        'aspect_ratio': aspectRatioStr,
        'resolution': resolutionStr,
        'duration_seconds': durationSeconds,
      },
      options: Options(
        headers: {'Authorization': 'Bearer $_token'},
        responseType: ResponseType.stream,
      ),
    );

    final stream = response.data.stream as Stream<List<int>>;
    String buffer = '';

    await for (final chunk in stream) {
      buffer += utf8.decode(chunk, allowMalformed: true);
      final lines = buffer.split('\n');
      buffer = lines.removeLast();

      for (final line in lines) {
        if (line.trim().startsWith('data: ')) {
          yield VeoStatus.fromSSE(line);
        }
      }
    }
  }

  Stream<VeoStatus> veoImageToVideo({
    required String prompt,
    required String imageUrl,
    required VeoAspectRatio aspectRatio,
    required Resolution resolution,
    required int durationSeconds,
  }) async* {
    final aspectRatioStr = aspectRatio == VeoAspectRatio.ratio16x9 ? '16:9' : '9:16';
    final resolutionStr = _resolutionToString(resolution);

    final response = await _dio.post(
      '/veo-image',
      data: {
        'prompt': prompt,
        'image_url': imageUrl,
        'aspect_ratio': aspectRatioStr,
        'resolution': resolutionStr,
        'duration_seconds': durationSeconds,
      },
      options: Options(
        headers: {'Authorization': 'Bearer $_token'},
        responseType: ResponseType.stream,
      ),
    );

    final stream = response.data.stream as Stream<List<int>>;
    String buffer = '';

    await for (final chunk in stream) {
      buffer += utf8.decode(chunk, allowMalformed: true);
      final lines = buffer.split('\n');
      buffer = lines.removeLast();

      for (final line in lines) {
        if (line.trim().startsWith('data: ')) {
          yield VeoStatus.fromSSE(line);
        }
      }
    }
  }

  String _resolutionToString(Resolution resolution) {
    switch (resolution) {
      case Resolution.res720p:
        return '720p';
      case Resolution.res1080p:
        return '1080p';
      case Resolution.res4k:
        return '4k';
    }
  }
}