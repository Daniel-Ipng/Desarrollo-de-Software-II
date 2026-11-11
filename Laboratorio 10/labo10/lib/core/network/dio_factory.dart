import 'package:dio/dio.dart';

import '../config/api_config.dart';
import '../storage/token_storage.dart';
import 'auth_interceptor.dart';
import 'error_interceptor.dart';
import 'logging_interceptor.dart';

class DioFactory {
  DioFactory._();

  static BaseOptions _options() => BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

  static Dio create({
    required TokenStorage tokenStorage,
    required void Function() onSessionExpired,
  }) {
    final dio = Dio(_options());

    // Dio limpio (sin interceptores) para renovar el token sin entrar en bucles.
    final refreshDio = Dio(_options());

    dio.interceptors.addAll([
      AuthInterceptor(
        dio: dio,
        refreshDio: refreshDio,
        tokenStorage: tokenStorage,
        onSessionExpired: onSessionExpired,
      ),
      LoggingInterceptor(),
      ErrorInterceptor(),
    ]);
    return dio;
  }
}
