import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Logging solo en modo debug. No imprime headers ni cuerpos (hay tokens y contraseñas).
class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) debugPrint('>>> ${options.method} ${options.uri}');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('<<< ${response.statusCode} ${response.requestOptions.path}');
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('!!! ${err.requestOptions.method} ${err.requestOptions.path} '
          '[${err.type.name}] ${err.response?.statusCode ?? ''}');
    }
    handler.next(err);
  }
}
