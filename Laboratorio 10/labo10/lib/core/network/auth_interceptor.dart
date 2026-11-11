import 'package:dio/dio.dart';

import '../config/api_config.dart';
import '../storage/token_storage.dart';

/// 1) Agrega `Authorization: Bearer <token>` a cada petición.
/// 2) Si la API responde 401, renueva el token con el refresh token y
///    reintenta la petición original automáticamente.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required Dio dio,
    required Dio refreshDio,
    required TokenStorage tokenStorage,
    required void Function() onSessionExpired,
  })  : _dio = dio,
        _refreshDio = refreshDio,
        _tokens = tokenStorage,
        _onSessionExpired = onSessionExpired;

  final Dio _dio;
  final Dio _refreshDio;
  final TokenStorage _tokens;
  final void Function() _onSessionExpired;

  /// Si varias peticiones fallan con 401 a la vez, solo se renueva una vez.
  Future<String?>? _refreshing;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    if (options.extra[ApiConfig.skipAuthKey] != true) {
      final token = await _tokens.getAccessToken();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final request = err.requestOptions;
    final shouldRefresh = err.response?.statusCode == 401 &&
        request.extra[ApiConfig.skipAuthKey] != true &&
        request.extra[ApiConfig.retriedKey] != true;

    if (!shouldRefresh) {
      handler.next(err);
      return;
    }

    String? newToken;
    try {
      newToken = await _refreshAccessToken();
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 400 || status == 401 || status == 403) {
        newToken = null; // el refresh token ya no sirve
      } else {
        handler.next(err); // fallo de red al renovar: no cerramos la sesión
        return;
      }
    } catch (_) {
      handler.next(err);
      return;
    }

    if (newToken == null) {
      await _tokens.clear();
      _onSessionExpired();
      handler.next(err);
      return;
    }

    // Reintenta la petición original con el nuevo token.
    request.extra[ApiConfig.retriedKey] = true;
    request.headers['Authorization'] = 'Bearer $newToken';
    try {
      final response = await _dio.fetch<dynamic>(request);
      handler.resolve(response);
    } on DioException catch (e) {
      handler.reject(e);
    }
  }

  Future<String?> _refreshAccessToken() {
    return _refreshing ??=
        _performRefresh().whenComplete(() => _refreshing = null);
  }

  Future<String?> _performRefresh() async {
    final refreshToken = await _tokens.getRefreshToken();
    if (refreshToken == null) return null;

    final response = await _refreshDio.post<Map<String, dynamic>>(
      '/auth/refresh',
      data: {'refreshToken': refreshToken},
    );
    final data = response.data!;
    final access = data['accessToken'] as String;
    final refresh = data['refreshToken'] as String;
    await _tokens.saveTokens(access: access, refresh: refresh);
    return access;
  }
}
