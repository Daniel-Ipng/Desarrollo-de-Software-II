import 'user.dart';

/// Contrato de autenticación (la capa de dominio no conoce Dio ni el almacenamiento).
abstract class AuthRepository {
  Future<User> login({required String email, required String password});
  Future<User> register({required String name, required String email, required String password});

  /// Si hay tokens guardados devuelve el usuario; si no, `null`.
  Future<User?> restoreSession();

  Future<void> logout();
}
