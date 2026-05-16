import 'package:dio/dio.dart';

class FixOldImageRepository {
  final Dio _dio;
  final String _token;

  FixOldImageRepository(this._dio, this._token);

  Future<String> fixImage(String imageUrl, String repairInstructions) async {
    final response = await _dio.post(
      '/fixoldimage',
      data: {'image_url': imageUrl, 'repair_instructions': repairInstructions},
      options: Options(headers: {'Authorization': 'Bearer $_token'}),
    );
    return response.data['secure_url'];
  }
}