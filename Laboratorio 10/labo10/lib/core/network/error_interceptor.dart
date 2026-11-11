import 'dart:io' show SocketException;

import 'package:dio/dio.dart';

import '../config/api_config.dart';
import '../exceptions/api_exceptions.dart';

/// Convierte cualquier `DioException` en una `ApiException` tipada
/// (queda en `DioException.error`).
class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.error is ApiException) {
      handler.next(err);
      return;
    }
    handler.next(DioException(
      requestOptions: err.requestOptions,
      response: err.response,
      type: err.type,
      error: _map(err),
      stackTrace: err.stackTrace,
      message: err.message,
    ));
  }

  ApiException _map(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return const TimeoutException();
      case DioExceptionType.connectionError:
        return const NetworkException();
      case DioExceptionType.badResponse:
        return _fromResponse(e);
      case DioExceptionType.cancel:
        return const UnknownException('Petición cancelada');
      case DioExceptionType.badCertificate:
        return const UnknownException('Certificado inválido');
      case DioExceptionType.unknown:
        if (e.error is SocketException) return const NetworkException();
        return UnknownException(e.message ?? e.error.toString());
    }
  }

  ApiException _fromResponse(DioException e) {
    final status = e.response?.statusCode ?? 0;
    final serverMessage = _extractMessage(e.response?.data);
    final isPublicCall = e.requestOptions.extra[ApiConfig.skipAuthKey] == true;

    if (status == 401 || status == 403) {
      // En login/register mostramos el mensaje del servidor ("Credenciales incorrectas").
      return UnauthorizedException(isPublicCall ? serverMessage : null);
    }
    if (status == 404) return ServerException(404, serverMessage ?? 'Recurso no encontrado.');
    if (status == 429) {
      return ServerException(429, 'Límite de peticiones alcanzado. Intenta más tarde.');
    }
    if (status >= 400 && status < 500) {
      return ValidationException(serverMessage ?? 'Solicitud inválida.', status);
    }
    return ServerException(status, serverMessage ?? 'Error del servidor.');
  }

  String? _extractMessage(dynamic data) {
    if (data is Map) {
      final msg = data['message'] ?? data['error'];
      if (msg != null) return msg.toString();
    }
    return null;
  }
}
