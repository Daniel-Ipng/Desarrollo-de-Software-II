import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../data/auth_remote_datasource.dart';
import '../data/auth_repository_impl.dart';
import '../domain/auth_repository.dart';
import '../domain/user.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    remote: AuthRemoteDataSource(ref.watch(dioProvider)),
    tokenStorage: ref.watch(tokenStorageProvider),
  );
});

/// Estado de sesión: `AsyncData(null)` = sin sesión, `AsyncData(user)` = autenticado.
class AuthController extends AsyncNotifier<User?> {
  AuthRepository get _repo => ref.read(authRepositoryProvider);

  @override
  Future<User?> build() {
    // Si el refresh token falla en cualquier parte de la app -> volver al login.
    ref.listen<int>(sessionExpiredProvider, (_, __) {
      state = const AsyncData(null);
    });
    return _repo.restoreSession();
  }

  /// Lanza `ApiException` si falla (la pantalla muestra el mensaje).
  Future<void> login(String email, String password) async {
    final user = await _repo.login(email: email, password: password);
    state = AsyncData(user);
  }

  Future<void> register(String name, String email, String password) async {
    final user = await _repo.register(name: name, email: email, password: password);
    state = AsyncData(user);
  }

  Future<void> logout() async {
    await _repo.logout();
    state = const AsyncData(null);
  }
}

final authControllerProvider =
    AsyncNotifierProvider<AuthController, User?>(AuthController.new);
