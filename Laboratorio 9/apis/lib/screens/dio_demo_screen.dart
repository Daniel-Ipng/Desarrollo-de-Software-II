import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../services/dio_api_service.dart';
import '../widgets/liquid_glass.dart';

/// Ejercicio 1: demo de Dio con interceptores, reintentos y cancelación.
class DioDemoScreen extends StatefulWidget {
  const DioDemoScreen({super.key});

  @override
  State<DioDemoScreen> createState() => _DioDemoScreenState();
}

class _DioDemoScreenState extends State<DioDemoScreen> {
  final List<String> _log = [];
  late final DioApiService _api;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _api = DioApiService(onLog: _add, token: 'token-de-ejemplo');
  }

  @override
  void dispose() {
    _api.close();
    super.dispose();
  }

  void _add(String m) {
    if (mounted) setState(() => _log.add(m));
  }

  Future<void> _run(String title, Future<void> Function() action) async {
    setState(() => _busy = true);
    _add('── $title ──');
    try {
      await action();
    } on DioException catch (e) {
      _add(
        '⚠️ DioException: ${e.type.name}'
        '${e.response != null ? ' (HTTP ${e.response!.statusCode})' : ''}',
      );
    } catch (e) {
      _add('⚠️ $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LiquidGlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Dio'),
          flexibleSpace: const LiquidGlassAppBar(),
          actions: [
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: 'Limpiar log',
              onPressed: () => setState(_log.clear),
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ElevatedButton(
                    onPressed: _busy
                        ? null
                        : () => _run('GET /posts', () async {
                            final posts = await _api.getPosts();
                            _add('✅ ${posts.length} posts recibidos');
                          }),
                    child: const Text('GET'),
                  ),
                  ElevatedButton(
                    onPressed: _busy
                        ? null
                        : () => _run('POST /posts', () async {
                            final p = await _api.createPost(
                              title: 'Título Dio',
                              body: 'Contenido',
                              userId: 1,
                            );
                            _add('✅ Creado con id ${p.id}');
                          }),
                    child: const Text('POST'),
                  ),
                  ElevatedButton(
                    onPressed: _busy
                        ? null
                        : () => _run('GET /posts/9999 (404)', () async {
                            await _api.getPostById(9999);
                          }),
                    child: const Text('Error 404'),
                  ),
                  ElevatedButton(
                    onPressed: _busy
                        ? null
                        : () =>
                              _run('Sin red: reintentos automáticos', () async {
                                final bad = DioApiService(
                                  onLog: _add,
                                  baseUrl: 'https://no-existe.invalid',
                                );
                                try {
                                  await bad.getPosts();
                                } finally {
                                  bad.close();
                                }
                              }),
                    child: const Text('Sin red (reintentos)'),
                  ),
                  ElevatedButton(
                    onPressed: _busy
                        ? null
                        : () => _run('Cancelación de petición', () async {
                            final token = CancelToken();
                            final f = _api.getPosts(cancelToken: token);
                            token.cancel('Cancelado por el usuario');
                            await f;
                          }),
                    child: const Text('Cancelar'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                padding: const EdgeInsets.all(8),
                child: GlassPanel(
                  padding: const EdgeInsets.all(10),
                  child: ListView.builder(
                    itemCount: _log.length,
                    itemBuilder: (_, i) => Text(
                      _log[i],
                      style: const TextStyle(
                        color: Color(0xFF8BE9E5),
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
