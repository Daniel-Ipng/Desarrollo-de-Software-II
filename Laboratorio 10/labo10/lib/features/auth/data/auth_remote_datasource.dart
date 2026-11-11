import 'package:dio/dio.dart';

import '../../../core/config/api_config.dart';
import 'user_model.dart';

class AuthResponse {
  final String accessToken;
  final String refreshToken;
  final UserModel user;

  const AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
        accessToken: json['accessToken'] as String,
        refreshToken: json['refreshToken'] as String,
        user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
      );
}

/// Endpoints de autenticación.
class AuthRemoteDataSource {
  AuthRemoteDataSource(this._dio);

  final Dio _dio;

  // Endpoints públicos: el interceptor no adjunta ni renueva tokens.
  static final _public = Options(extra: {ApiConfig.skipAuthKey: true});

  Future<AuthResponse> login(String email, String password) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/auth/login',
      data: {'email': email, 'password': password},
      options: _public,
    );
    return AuthResponse.fromJson(res.data!);
  }

  Future<AuthResponse> register(String name, String email, String password) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/auth/register',
      data: {'name': name, 'email': email, 'password': password},
      options: _public,
    );
    return AuthResponse.fromJson(res.data!);
  }

  /// Protegido: si el access token expiró, el interceptor lo renueva.
  Future<UserModel> me() async {
    final res = await _dio.get<Map<String, dynamic>>('/auth/me');
    return UserModel.fromJson(res.data!);
  }

  Future<void> logout(String refreshToken) async {
    await _dio.post<void>(
      '/auth/logout',
      data: {'refreshToken': refreshToken},
      options: _public,
    );
  }
}
