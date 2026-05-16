import 'package:dio/dio.dart';
import '../../../auth/providers/auth_provider.dart';

class TryOnRepository {
  final Dio _dio;
  final String _token;

  TryOnRepository(this._dio, this._token);

  Future<String> tryOn(String personImageUrl, String productImageUrl) async {
    final response = await _dio.post(
      '/tryon',
      data: {
        'person_image_url': personImageUrl,
        'product_image_url': productImageUrl,
      },
      options: Options(headers: {'Authorization': 'Bearer $_token'}),
    );
    return response.data['secure_url'];
  }
}