class InsufficientStockException implements Exception {
  InsufficientStockException({
    required this.productId,
    required this.requested,
    required this.available,
  });

  final String productId;
  final int requested;
  final int available;

  @override
  String toString() =>
      'InsufficientStockException: producto $productId, solicitado $requested, disponible $available';
}
