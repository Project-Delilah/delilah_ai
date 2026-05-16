import 'package:pocketbase/pocketbase.dart';

class AuthRepository {
  final PocketBase _pb;

  AuthRepository(this._pb);

  Future<RecordAuth> signIn(String email, String password) =>
      _pb.collection('users').authWithPassword(email, password);

  Future<RecordModel> register(String email, String password, String name) =>
      _pb.collection('users').create(body: {
        'email': email,
        'password': password,
        'passwordConfirm': password,
        'name': name,
      });

  void signOut() => _pb.authStore.clear();

  bool get isLoggedIn => _pb.authStore.isValid;

  RecordModel? get currentUser => _pb.authStore.record;
}