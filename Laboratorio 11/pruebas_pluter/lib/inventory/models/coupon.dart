class Coupon {
  const Coupon({
    required this.code,
    required this.discountRate,
    required this.expiresAt,
  });

  final String code;

  /// Fracción de descuento: 0.10 = 10 %.
  final double discountRate;
  final DateTime expiresAt;

  /// Un cupón es válido solo si [now] es estrictamente anterior a su vencimiento.
  bool isValidAt(DateTime now) => now.isBefore(expiresAt);
}
