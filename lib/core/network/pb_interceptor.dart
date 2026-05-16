import 'package:dio/dio.dart';
import 'package:pocketbase/pocketbase.dart';

class PocketBaseAuthInterceptor extends Interceptor {
  final PocketBase _pb;

  PocketBaseAuthInterceptor(this._pb);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (_pb.authStore.isValid) {
      options.headers['Authorization'] = 'Bearer ${_pb.authStore.token}';
    }
    options.headers['Content-Type'] = 'application/json';
    options.headers['Accept'] = 'application/json';
    super.onRequest(options, handler);
  }
}