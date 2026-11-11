import '../../../core/exceptions/api_exceptions.dart';
import '../../../core/network/api_guard.dart';
import '../../../core/storage/token_storage.dart';
import '../domain/auth_repository.dart';
import '../domain/user.dart';
import 'auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required AuthRemoteDataSource remote,
    required TokenStorage tokenStorage,
  })  : _remote = remote,
        _tokens = tokenStorage;

  final AuthRemoteDataSource _remote;
  final TokenStorage _tokens;

  @override
  Future<User> login({required String email, required String password}) {
    return guardApi(() async {
      final res = await _remote.login(email.trim(), password);
      await _tokens.saveTokens(access: res.accessToken, refresh: res.refreshToken);
      return res.user;
    });
  }

  @override
  Future<User> register({
    required String name,
    required String email,
    required String password,
  }) {
    return guardApi(() async {
      final res = await _remote.register(name.trim(), email.trim(), password);
      await _tokens.saveTokens(access: res.accessToken, refresh: res.refreshToken);
      return res.user;
    });
  }

  @override
  Future<User?> restoreSession() async {
    if (!await _tokens.hasSession()) return null;
    try {
      return await guardApi(_remote.me);
    } on UnauthorizedException {
      await _tokens.clear();
      return null;
    }
  }

  @override
  Future<void> logout() async {
    try {
      final refresh = await _tokens.getRefreshToken();
      if (refresh != null) await guardApi(() => _remote.logout(refresh));
    } on ApiException {
      // Aunque falle el servidor, la sesión local se cierra igual.
    } finally {
      await _tokens.clear(); // logout limpia las credenciales
    }
  }
}
