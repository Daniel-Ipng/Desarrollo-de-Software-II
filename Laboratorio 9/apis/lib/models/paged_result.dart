/// Resultado de una consulta paginada.
class PagedResult<T> {
  final List<T> items;
  final int totalItems;
  final int page;
  final int limit;

  const PagedResult({
    required this.items,
    required this.totalItems,
    required this.page,
    required this.limit,
  });

  int get totalPages => limit == 0 ? 1 : (totalItems / limit).ceil();
}
