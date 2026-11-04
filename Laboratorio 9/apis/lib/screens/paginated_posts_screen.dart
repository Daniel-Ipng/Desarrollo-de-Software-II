import 'package:flutter/material.dart';

import '../models/paged_result.dart';
import '../models/post.dart';
import '../services/api_service.dart';
import '../widgets/liquid_glass.dart';

/// Ejercicio 4: paginación con páginas numéricas (REST).
class PaginatedPostsScreen extends StatefulWidget {
  const PaginatedPostsScreen({super.key});

  @override
  State<PaginatedPostsScreen> createState() => _PaginatedPostsScreenState();
}

class _PaginatedPostsScreenState extends State<PaginatedPostsScreen> {
  static const int _limit = 10;
  final _api = ApiService();
  int _page = 1;
  late Future<PagedResult<Post>> _future;

  @override
  void initState() {
    super.initState();
    _future = _api.getPostsPage(page: _page, limit: _limit);
  }

  @override
  void dispose() {
    _api.dispose();
    super.dispose();
  }

  void _goTo(int page) {
    setState(() {
      _page = page;
      _future = _api.getPostsPage(page: page, limit: _limit);
    });
  }

  @override
  Widget build(BuildContext context) {
    return LiquidGlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Paginación (REST)'),
          flexibleSpace: const LiquidGlassAppBar(),
        ),
        body: FutureBuilder<PagedResult<Post>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Error: ${snapshot.error}'),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => _goTo(_page),
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              );
            }
            final result = snapshot.data!;
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    'Página ${result.page} de ${result.totalPages} '
                    '(${result.totalItems} posts en total)',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: result.items.length,
                    itemBuilder: (context, i) {
                      final p = result.items[i];
                      return GlassPanel(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: ListTile(
                          leading: CircleAvatar(child: Text('${p.id}')),
                          title: Text(
                            p.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            p.body,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SafeArea(
                  child: SizedBox(
                    height: 56,
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left),
                          onPressed: _page > 1 ? () => _goTo(_page - 1) : null,
                        ),
                        Expanded(
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: result.totalPages,
                            itemBuilder: (context, i) {
                              final n = i + 1;
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 10,
                                ),
                                child: ChoiceChip(
                                  label: Text('$n'),
                                  selected: n == _page,
                                  onSelected: (_) => _goTo(n),
                                ),
                              );
                            },
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right),
                          onPressed: _page < result.totalPages
                              ? () => _goTo(_page + 1)
                              : null,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
