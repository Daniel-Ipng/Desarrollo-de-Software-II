import 'package:dio/dio.dart';

import '../exceptions/api_exceptions.dart';

extension DioExceptionX on DioException {
  /// La `ApiException` que dejó el `ErrorInterceptor`.
  ApiException get apiException {
    final e = error;
    if (e is ApiException) return e;
    return UnknownException(message ?? toString());
  }
}

/// Ejecuta una llamada y garantiza que solo salgan `ApiException` hacia las capas superiores.
Future<T> guardApi<T>(Future<T> Function() body) async {
  try {
    return await body();
  } on ApiException {
    rethrow;
  } on DioException catch (e) {
    throw e.apiException;
  } on FormatException catch (e) {
    throw ParseException(e.message);
  } on TypeError catch (e) {
    throw ParseException(e.toString());
  }
}
