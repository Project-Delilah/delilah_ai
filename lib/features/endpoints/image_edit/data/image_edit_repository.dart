import 'package:dio/dio.dart';

class ImageEditRepository {
  final Dio _dio;
  final String _token;

  ImageEditRepository(this._dio, this._token);

  Future<String> editImage(String imageUrl, String editPrompt) async {
    final response = await _dio.post(
      '/edit',
      data: {
        'image_url': imageUrl,
        'edit_prompt': editPrompt,
      },
      options: Options(headers: {'Authorization': 'Bearer $_token'}),
    );
    return response.data['secure_url'];
  }
}