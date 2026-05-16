import 'package:dio/dio.dart';

class ProductMakeoverRepository {
  final Dio _dio;
  final String _token;

  ProductMakeoverRepository(this._dio, this._token);

  Future<String> makeover(String productImageUrl, String backgroundContext) async {
    final response = await _dio.post(
      '/product-makeover',
      data: {'product_image_url': productImageUrl, 'background_context': backgroundContext},
      options: Options(headers: {'Authorization': 'Bearer $_token'}),
    );
    return response.data['secure_url'];
  }
}