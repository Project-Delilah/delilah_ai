import 'package:dio/dio.dart';

class UpscaleRepository {
  final Dio _dio;
  final String _token;

  UpscaleRepository(this._dio, this._token);

  Future<String> upscale(String imageUrl, String enhancementFocus) async {
    final response = await _dio.post(
      '/upscale',
      data: {
        'image_url': imageUrl,
        'enhancement_focus': enhancementFocus,
      },
      options: Options(headers: {'Authorization': 'Bearer $_token'}),
    );
    return response.data['secure_url'];
  }
}