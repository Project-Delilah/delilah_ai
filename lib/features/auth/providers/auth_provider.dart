import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/config.dart';
import '../../../core/services/secure_storage.dart';

sealed class AuthState {}

class AuthAuthenticated extends AuthState {
  final String token;
  AuthAuthenticated(this.token);
}

class AuthUnauthenticated extends AuthState {}

final dioProvider = Provider<Dio>((ref) {
  return Dio(BaseOptions(
    baseUrl: AppConfig.apiBaseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 90),
  ));
});

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    _loadPersistedToken();
    return AuthUnauthenticated();
  }

  Future<void> _loadPersistedToken() async {
    final token = await SecureStorage.getToken();
    if (token != null && token.isNotEmpty) {
      state = AuthAuthenticated(token);
    }
  }

  String? get token {
    final currentState = state;
    if (currentState is AuthAuthenticated) {
      return currentState.token;
    }
    return null;
  }

  Future<void> signIn(String email, String password) async {
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.post(
        AppConfig.loginUrl,
        data: {'email': email, 'password': password},
      );

      final token = response.data['token'];
      await SecureStorage.saveToken(token);
      state = AuthAuthenticated(token);
    } catch (e) {
      state = AuthUnauthenticated();
      rethrow;
    }
  }

  Future<void> signUp(String email, String password, String passwordConfirm) async {
    try {
      final dio = ref.read(dioProvider);
      await dio.post(
        AppConfig.registerUrl,
        data: {'email': email, 'password': password, 'passwordConfirm': passwordConfirm},
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    await SecureStorage.deleteToken();
    state = AuthUnauthenticated();
  }
}

final authNotifierProvider = NotifierProvider<AuthNotifier, AuthState>(() => AuthNotifier());