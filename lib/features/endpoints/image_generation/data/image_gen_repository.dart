import 'package:dio/dio.dart';
import '../../../auth/providers/auth_provider.dart';

class ImageGenRepository {
  final Dio _dio;
  final String _token;

  ImageGenRepository(this._dio, this._token);

  Future<String> generate(String prompt) async {
    final response = await _dio.post(
      '/generate',
      data: {'prompt': prompt},
      options: Options(headers: {'Authorization': 'Bearer $_token'}),
    );
    return response.data['secure_url'];
  }
}