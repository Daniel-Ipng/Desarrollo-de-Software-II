import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/post.dart';
import '../models/comment.dart';
import '../models/paged_result.dart';

class ApiService {
  static const String _baseUrl = 'https://jsonplaceholder.typicode.com';
  static const Duration _timeout = Duration(seconds: 15);
  static const _headers = {'Content-Type': 'application/json'};

  final http.Client _client;

  ApiService({http.Client? client}) : _client = client ?? http.Client();

  /// Envuelve cualquier petición con timeout y manejo de errores de red.
  Future<http.Response> _send(Future<http.Response> Function() request) async {
    try {
      return await request().timeout(_timeout);
    } on TimeoutException {
      throw const ApiException(
          statusCode: 408,
          message: 'La petición tardó demasiado. Verifica tu conexión.');
    } on SocketException {
      throw const ApiException(statusCode: 0, message: 'Sin conexión a internet.');
    } on http.ClientException {
      throw const ApiException(statusCode: 0, message: 'Error de conexión.');
    }
  }

  // GET: todos los posts
  Future<List<Post>> getPosts() async {
    final response = await _send(
        () => _client.get(Uri.parse('$_baseUrl/posts'), headers: _headers));
    if (response.statusCode == 200) {
      final List<dynamic> list = json.decode(response.body);
      return list.map((j) => Post.fromJson(j)).toList();
    }
    throw ApiException(
        statusCode: response.statusCode, message: 'Error al obtener posts');
  }

  // GET paginado: usa ?_page=N&_limit=M y el header x-total-count
  Future<PagedResult<Post>> getPostsPage({int page = 1, int limit = 10}) async {
    final uri = Uri.parse('$_baseUrl/posts')
        .replace(queryParameters: {'_page': '$page', '_limit': '$limit'});
    final response = await _send(() => _client.get(uri, headers: _headers));
    if (response.statusCode == 200) {
      final List<dynamic> list = json.decode(response.body);
      final total =
          int.tryParse(response.headers['x-total-count'] ?? '') ?? list.length;
      return PagedResult<Post>(
        items: list.map((j) => Post.fromJson(j)).toList(),
        totalItems: total,
        page: page,
        limit: limit,
      );
    }
    throw ApiException(
        statusCode: response.statusCode, message: 'Error al obtener la página');
  }

  // GET: post por ID
  Future<Post> getPostById(int id) async {
    final response = await _send(() => _client.get(Uri.parse('$_baseUrl/posts/$id')));
    if (response.statusCode == 200) {
      return Post.fromJson(json.decode(response.body));
    } else if (response.statusCode == 404) {
      throw const ApiException(statusCode: 404, message: 'Post no encontrado');
    }
    throw ApiException(statusCode: response.statusCode, message: 'Error inesperado');
  }

  // POST: crear
  Future<Post> createPost({
    required String title,
    required String body,
    required int userId,
  }) async {
    final response = await _send(() => _client.post(
          Uri.parse('$_baseUrl/posts'),
          headers: _headers,
          body: json.encode({'title': title, 'body': body, 'userId': userId}),
        ));
    if (response.statusCode == 201) {
      return Post.fromJson(json.decode(response.body));
    }
    throw ApiException(
        statusCode: response.statusCode, message: 'Error al crear el post');
  }

  // PUT: actualizar
  Future<Post> updatePost(Post post) async {
    final response = await _send(() => _client.put(
          Uri.parse('$_baseUrl/posts/${post.id}'),
          headers: _headers,
          body: json.encode(post.toJson()),
        ));
    if (response.statusCode == 200) {
      return Post.fromJson(json.decode(response.body));
    }
    throw ApiException(
        statusCode: response.statusCode, message: 'Error al actualizar el post');
  }

  // DELETE: eliminar
  Future<void> deletePost(int id) async {
    final response =
        await _send(() => _client.delete(Uri.parse('$_baseUrl/posts/$id')));
    if (response.statusCode != 200) {
      throw ApiException(
          statusCode: response.statusCode, message: 'Error al eliminar el post');
    }
  }

  // GET: comentarios de un post
  Future<List<Comment>> getCommentsByPost(int postId) async {
    final response =
        await _send(() => _client.get(Uri.parse('$_baseUrl/posts/$postId/comments')));
    if (response.statusCode == 200) {
      final List<dynamic> list = json.decode(response.body);
      return list.map((j) => Comment.fromJson(j)).toList();
    }
    throw ApiException(
        statusCode: response.statusCode, message: 'Error al obtener comentarios');
  }

  void dispose() => _client.close();
}

class ApiException implements Exception {
  final int statusCode;
  final String message;
  const ApiException({required this.statusCode, required this.message});

  @override
  String toString() => message;
}
