import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/mockito.dart';

import '../lib/models/post.dart';
import '../lib/services/api_service.dart';

/// Mock manual de http.Client (no requiere build_runner).
class MockHttpClient extends Mock implements http.Client {
  @override
  Future<http.Response> get(Uri url, {Map<String, String>? headers}) =>
      super.noSuchMethod(
        Invocation.method(#get, [url], {#headers: headers}),
        returnValue: Future.value(http.Response('', 200)),
        returnValueForMissingStub: Future.value(http.Response('', 200)),
      ) as Future<http.Response>;

  @override
  Future<http.Response> post(Uri url,
          {Map<String, String>? headers, Object? body, Encoding? encoding}) =>
      super.noSuchMethod(
        Invocation.method(
            #post, [url], {#headers: headers, #body: body, #encoding: encoding}),
        returnValue: Future.value(http.Response('', 200)),
        returnValueForMissingStub: Future.value(http.Response('', 200)),
      ) as Future<http.Response>;

  @override
  Future<http.Response> put(Uri url,
          {Map<String, String>? headers, Object? body, Encoding? encoding}) =>
      super.noSuchMethod(
        Invocation.method(
            #put, [url], {#headers: headers, #body: body, #encoding: encoding}),
        returnValue: Future.value(http.Response('', 200)),
        returnValueForMissingStub: Future.value(http.Response('', 200)),
      ) as Future<http.Response>;

  @override
  Future<http.Response> delete(Uri url,
          {Map<String, String>? headers, Object? body, Encoding? encoding}) =>
      super.noSuchMethod(
        Invocation.method(#delete, [url],
            {#headers: headers, #body: body, #encoding: encoding}),
        returnValue: Future.value(http.Response('', 200)),
        returnValueForMissingStub: Future.value(http.Response('', 200)),
      ) as Future<http.Response>;
}

void main() {
  const base = 'https://jsonplaceholder.typicode.com';
  late MockHttpClient client;
  late ApiService api;

  final postJson = {'userId': 1, 'id': 1, 'title': 'titulo', 'body': 'cuerpo'};

  setUp(() {
    client = MockHttpClient();
    api = ApiService(client: client);
  });

  group('getPosts', () {
    test('devuelve lista de Post cuando el status es 200', () async {
      when(client.get(Uri.parse('$base/posts'), headers: anyNamed('headers')))
          .thenAnswer((_) async => http.Response(json.encode([postJson]), 200));

      final posts = await api.getPosts();

      expect(posts, hasLength(1));
      expect(posts.first.title, 'titulo');
    });

    test('lanza ApiException cuando el status es 500', () async {
      when(client.get(Uri.parse('$base/posts'), headers: anyNamed('headers')))
          .thenAnswer((_) async => http.Response('error', 500));

      expect(
        api.getPosts(),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 500)),
      );
    });

    test('lanza ApiException(0) cuando no hay conexión', () async {
      when(client.get(Uri.parse('$base/posts'), headers: anyNamed('headers')))
          .thenThrow(const SocketException('sin red'));

      expect(
        api.getPosts(),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 0)),
      );
    });
  });

  group('getPostById', () {
    test('devuelve el Post con status 200', () async {
      when(client.get(Uri.parse('$base/posts/1'), headers: anyNamed('headers')))
          .thenAnswer((_) async => http.Response(json.encode(postJson), 200));

      final post = await api.getPostById(1);
      expect(post.id, 1);
    });

    test('lanza ApiException 404 si no existe', () async {
      when(client.get(Uri.parse('$base/posts/999'), headers: anyNamed('headers')))
          .thenAnswer((_) async => http.Response('{}', 404));

      expect(
        api.getPostById(999),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 404)),
      );
    });
  });

  group('createPost', () {
    test('devuelve el Post creado con status 201', () async {
      when(client.post(
        Uri.parse('$base/posts'),
        headers: anyNamed('headers'),
        body: anyNamed('body'),
        encoding: anyNamed('encoding'),
      )).thenAnswer((_) async =>
          http.Response(json.encode({...postJson, 'id': 101}), 201));

      final post = await api.createPost(title: 't', body: 'b', userId: 1);
      expect(post.id, 101);
    });
  });

  group('updatePost', () {
    test('devuelve el Post actualizado con status 200', () async {
      when(client.put(
        Uri.parse('$base/posts/1'),
        headers: anyNamed('headers'),
        body: anyNamed('body'),
        encoding: anyNamed('encoding'),
      )).thenAnswer((_) async =>
          http.Response(json.encode({...postJson, 'title': 'nuevo'}), 200));

      final updated = await api.updatePost(Post.fromJson(postJson));
      expect(updated.title, 'nuevo');
    });
  });

  group('deletePost', () {
    test('completa sin error con status 200', () async {
      when(client.delete(
        Uri.parse('$base/posts/1'),
        headers: anyNamed('headers'),
        body: anyNamed('body'),
        encoding: anyNamed('encoding'),
      )).thenAnswer((_) async => http.Response('{}', 200));

      await expectLater(api.deletePost(1), completes);
    });

    test('lanza ApiException si el servidor responde 500', () async {
      when(client.delete(
        Uri.parse('$base/posts/1'),
        headers: anyNamed('headers'),
        body: anyNamed('body'),
        encoding: anyNamed('encoding'),
      )).thenAnswer((_) async => http.Response('', 500));

      expect(api.deletePost(1), throwsA(isA<ApiException>()));
    });
  });

  group('getPostsPage (paginación)', () {
    test('lee x-total-count y calcula el total de páginas', () async {
      when(client.get(
        Uri.parse('$base/posts?_page=2&_limit=10'),
        headers: anyNamed('headers'),
      )).thenAnswer((_) async => http.Response(
            json.encode([postJson]),
            200,
            headers: {'x-total-count': '100'},
          ));

      final result = await api.getPostsPage(page: 2, limit: 10);

      expect(result.page, 2);
      expect(result.totalItems, 100);
      expect(result.totalPages, 10);
      expect(result.items, hasLength(1));
    });
  });
}
