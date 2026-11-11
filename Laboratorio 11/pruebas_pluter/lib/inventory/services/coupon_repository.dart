import '../models/coupon.dart';

abstract class CouponRepository {
  /// Devuelve el cupón o `null` si no existe.
  Future<Coupon?> findByCode(String code);
}
