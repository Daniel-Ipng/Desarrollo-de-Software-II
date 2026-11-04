import 'package:dio/dio.dart';
import '../models/post.dart';

/// Ejercicio 1: mismo consumo de la API pero con Dio.
/// Muestra: interceptores (log + token), reintentos automáticos,
/// timeouts separados, cancelación y errores tipados (DioException).
class DioApiService {
  static const String _defaultBaseUrl = 'https://jsonplaceholder.typicode.com';
  static const int _maxRetries = 3;

  final Dio dio;
  final void Function(String message)? onLog;

  DioApiService({
    this.onLog,
    String? token,
    String baseUrl = _defaultBaseUrl,
  }) : dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 15),
          headers: {'Accept': 'application/json'},
        )) {
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        _log('➡️ ${options.method} ${options.uri}');
        if (token != null) options.headers['Authorization'] = 'Bearer $token';
        handler.next(options);
      },
      onResponse: (response, handler) {
        _log('⬅️ ${response.statusCode} ${response.requestOptions.uri}');
        handler.next(response);
      },
      onError: (e, handler) async {
        final retries = (e.requestOptions.extra['retries'] as int?) ?? 0;
        if (_shouldRetry(e) && retries < _maxRetries) {
          final next = retries + 1;
          _log('🔁 Reintento $next/$_maxRetries (${e.type.name})');
          await Future.delayed(Duration(seconds: next));
          e.requestOptions.extra['retries'] = next;
          try {
            final response = await dio.fetch(e.requestOptions);
            return handler.resolve(response);
          } on DioException catch (err) {
            return handler.next(err);
          }
        }
        _log('❌ ${e.type.name} ${e.response?.statusCode ?? ''}');
        handler.next(e);
      },
    ));
  }

  void _log(String m) => onLog?.call(m);

  bool _shouldRetry(DioException e) =>
      e.type == DioExceptionType.connectionTimeout ||
      e.type == DioExceptionType.sendTimeout ||
      e.type == DioExceptionType.receiveTimeout ||
      e.type == DioExceptionType.connectionError ||
      (e.response?.statusCode ?? 0) >= 500;

  Future<List<Post>> getPosts({CancelToken? cancelToken}) async {
    final r = await dio.get<List<dynamic>>('/posts', cancelToken: cancelToken);
    return r.data!
        .map((j) => Post.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<Post> getPostById(int id) async {
    final r = await dio.get<Map<String, dynamic>>('/posts/$id');
    return Post.fromJson(r.data!);
  }

  // Dio convierte el Map a JSON automáticamente.
  Future<Post> createPost({
    required String title,
    required String body,
    required int userId,
  }) async {
    final r = await dio.post<Map<String, dynamic>>('/posts',
        data: {'title': title, 'body': body, 'userId': userId});
    return Post.fromJson(r.data!);
  }

  Future<void> deletePost(int id) => dio.delete('/posts/$id');

  void close() => dio.close();
}
