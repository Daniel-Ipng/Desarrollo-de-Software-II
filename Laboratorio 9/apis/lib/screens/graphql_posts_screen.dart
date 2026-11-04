import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

import '../widgets/liquid_glass.dart';

/// Ejercicio 3: mismos posts pero consumidos con GraphQL.
/// API pública: https://graphqlzero.almansi.me/api (datos de JSONPlaceholder).
class GraphqlPostsScreen extends StatefulWidget {
  const GraphqlPostsScreen({super.key});

  @override
  State<GraphqlPostsScreen> createState() => _GraphqlPostsScreenState();
}

class _GraphqlPostsScreenState extends State<GraphqlPostsScreen> {
  static const int _limit = 10;
  static const String _query = r'''
query Posts($page: Int, $limit: Int) {
  posts(options: {paginate: {page: $page, limit: $limit}}) {
    data { id title body }
    meta { totalCount }
  }
}
''';

  final GraphQLClient _client = GraphQLClient(
    link: HttpLink('https://graphqlzero.almansi.me/api'),
    cache: GraphQLCache(),
  );

  int _page = 1;
  late Future<_GqlPage> _future;

  @override
  void initState() {
    super.initState();
    _future = _fetch(_page);
  }

  Future<_GqlPage> _fetch(int page) async {
    final result = await _client.query(
      QueryOptions(
        document: gql(_query),
        variables: {'page': page, 'limit': _limit},
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );
    if (result.hasException) {
      throw Exception(result.exception.toString());
    }
    final posts = result.data!['posts'] as Map<String, dynamic>;
    final data = (posts['data'] as List<dynamic>).cast<Map<String, dynamic>>();
    final total = posts['meta']['totalCount'] as int;
    return _GqlPage(data, total);
  }

  void _goTo(int page) {
    setState(() {
      _page = page;
      _future = _fetch(page);
    });
  }

  @override
  Widget build(BuildContext context) {
    return LiquidGlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('GraphQL'),
          flexibleSpace: const LiquidGlassAppBar(),
        ),
        body: Column(
          children: [
            GlassPanel(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(14),
              child: Text(
                'REST: GET /posts?_page=$_page&_limit=$_limit\n'
                'GraphQL: UNA sola consulta POST que pide solo los campos '
                'necesarios (id, title, body) y el total.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            Expanded(
              child: FutureBuilder<_GqlPage>(
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
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              'Error: ${snapshot.error}',
                              textAlign: TextAlign.center,
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () => _goTo(_page),
                            child: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    );
                  }
                  final page = snapshot.data!;
                  final totalPages = (page.total / _limit).ceil();
                  return Column(
                    children: [
                      Text(
                        'Página $_page de $totalPages',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: page.items.length,
                          itemBuilder: (context, i) {
                            final p = page.items[i];
                            return GlassPanel(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  child: Text('${p['id']}'),
                                ),
                                title: Text(
                                  '${p['title']}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  '${p['body']}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      SafeArea(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.chevron_left),
                              onPressed: _page > 1
                                  ? () => _goTo(_page - 1)
                                  : null,
                            ),
                            Text('$_page / $totalPages'),
                            IconButton(
                              icon: const Icon(Icons.chevron_right),
                              onPressed: _page < totalPages
                                  ? () => _goTo(_page + 1)
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GqlPage {
  final List<Map<String, dynamic>> items;
  final int total;
  const _GqlPage(this.items, this.total);
}
