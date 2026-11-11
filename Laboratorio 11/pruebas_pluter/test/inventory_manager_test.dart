import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pruebas_pluter/inventory/inventory_manager.dart';

class MockStockApiService extends Mock implements StockApiService {}

class MockLocationService extends Mock implements LocationService {}

class MockCouponRepository extends Mock implements CouponRepository {}

void main() {
  late MockStockApiService stockApi;
  late MockLocationService location;
  late MockCouponRepository coupons;
  late InventoryManager manager;

  final now = DateTime(2026, 11, 11, 12);
  const laptop = Product(id: 'p1', name: 'Laptop', price: 1000);
  const mouse = Product(id: 'p2', name: 'Mouse', price: 50);
  const rates = {'PE': 0.18, 'US': 0.07, 'MX': 0.16};

  void stubStock(String id, int stock) =>
      when(() => stockApi.getAvailableStock(id)).thenAnswer((_) async => stock);
  void stubRegion(String region) =>
      when(() => location.getRegionCode()).thenAnswer((_) async => region);
  void stubCoupon(String code, Coupon? coupon) =>
      when(() => coupons.findByCode(code)).thenAnswer((_) async => coupon);

  InventoryManager buildManager({double defaultTaxRate = 0.0}) =>
      InventoryManager(
        stockApi: stockApi,
        locationService: location,
        couponRepository: coupons,
        taxRatesByRegion: rates,
        defaultTaxRate: defaultTaxRate,
        clock: () => now,
      );

  setUp(() {
    stockApi = MockStockApiService();
    location = MockLocationService();
    coupons = MockCouponRepository();
    manager = buildManager();
    stubStock('p1', 10);
    stubStock('p2', 10);
    stubRegion('PE');
  });

  group('InventoryManager.addProduct', () {
    test('agrega el producto cuando hay stock suficiente', () async {
      await manager.addProduct(laptop, 3);

      expect(manager.quantityOf('p1'), 3);
      expect(manager.items, hasLength(1));
      verify(() => stockApi.getAvailableStock('p1')).called(1);
    });

    test('acumula la cantidad si el producto ya estaba en el carrito', () async {
      await manager.addProduct(laptop, 2);
      await manager.addProduct(laptop, 3);

      expect(manager.quantityOf('p1'), 5);
      expect(manager.items, hasLength(1));
    });

    test('permite pedir exactamente el stock disponible', () async {
      stubStock('p1', 5);
      await manager.addProduct(laptop, 5);
      expect(manager.quantityOf('p1'), 5);
    });

    test('lanza InsufficientStockException si excede el stock', () async {
      stubStock('p1', 5);

      await expectLater(
        manager.addProduct(laptop, 6),
        throwsA(isA<InsufficientStockException>()
            .having((e) => e.productId, 'productId', 'p1')
            .having((e) => e.requested, 'requested', 6)
            .having((e) => e.available, 'available', 5)),
      );
      expect(manager.items, isEmpty);
    });

    test('lanza la excepción al exceder el stock de forma acumulada', () async {
      stubStock('p1', 5);
      await manager.addProduct(laptop, 4);

      await expectLater(
        manager.addProduct(laptop, 2),
        throwsA(isA<InsufficientStockException>()),
      );
      expect(manager.quantityOf('p1'), 4);
    });

    test('rechaza cantidades cero o negativas sin consultar la API', () async {
      await expectLater(manager.addProduct(laptop, 0), throwsArgumentError);
      await expectLater(manager.addProduct(laptop, -2), throwsArgumentError);
      verifyNever(() => stockApi.getAvailableStock('p1'));
    });

    test('propaga los errores del servicio remoto de stock', () async {
      when(() => stockApi.getAvailableStock('p1'))
          .thenThrow(Exception('timeout'));

      await expectLater(manager.addProduct(laptop, 1), throwsException);
      expect(manager.items, isEmpty);
    });
  });

  group('InventoryManager.calculateTotal', () {
    Future<void> fillCart() async {
      await manager.addProduct(laptop, 1);
      await manager.addProduct(mouse, 2); // subtotal = 1100
    }

    test('devuelve 0 con el carrito vacío', () async {
      expect(await manager.calculateTotal(), 0);
    });

    test('aplica el impuesto de Perú (18 %) sin cupón', () async {
      await fillCart();
      expect(await manager.calculateTotal(), closeTo(1298.0, 0.001));
      verifyNever(() => coupons.findByCode(any()));
    });

    test('aplica el impuesto de EE. UU. (7 %)', () async {
      stubRegion('US');
      await fillCart();
      expect(await manager.calculateTotal(), closeTo(1177.0, 0.001));
    });

    test('aplica el impuesto de México (16 %)', () async {
      stubRegion('MX');
      await fillCart();
      expect(await manager.calculateTotal(), closeTo(1276.0, 0.001));
    });

    test('usa la tasa por defecto en una región desconocida', () async {
      stubRegion('XX');
      await fillCart();
      expect(await manager.calculateTotal(), closeTo(1100.0, 0.001));

      manager = buildManager(defaultTaxRate: 0.10);
      await fillCart();
      expect(await manager.calculateTotal(), closeTo(1210.0, 0.001));
    });

    test('aplica el descuento de un cupón válido antes del impuesto', () async {
      stubCoupon(
        'PROMO10',
        Coupon(
          code: 'PROMO10',
          discountRate: 0.10,
          expiresAt: now.add(const Duration(days: 1)),
        ),
      );
      await fillCart();
      manager.applyCoupon('PROMO10');

      // (1100 − 10 %) × 1.18 = 1168.2
      expect(await manager.calculateTotal(), closeTo(1168.2, 0.001));
      verify(() => coupons.findByCode('PROMO10')).called(1);
    });

    test('ignora un cupón vencido', () async {
      stubCoupon(
        'VIEJO',
        Coupon(
          code: 'VIEJO',
          discountRate: 0.50,
          expiresAt: now.subtract(const Duration(days: 1)),
        ),
      );
      await fillCart();
      manager.applyCoupon('VIEJO');

      expect(await manager.calculateTotal(), closeTo(1298.0, 0.001));
    });

    test('un cupón que vence justo ahora ya no es válido', () async {
      stubCoupon('LIMITE',
          Coupon(code: 'LIMITE', discountRate: 0.50, expiresAt: now));
      await fillCart();
      manager.applyCoupon('LIMITE');

      expect(await manager.calculateTotal(), closeTo(1298.0, 0.001));
    });

    test('ignora un cupón inexistente', () async {
      stubCoupon('FALSO', null);
      await fillCart();
      manager.applyCoupon('FALSO');

      expect(await manager.calculateTotal(), closeTo(1298.0, 0.001));
    });

    test('clearCoupon elimina el descuento y no consulta el repositorio',
        () async {
      await fillCart();
      manager.applyCoupon('PROMO10');
      manager.clearCoupon();

      expect(await manager.calculateTotal(), closeTo(1298.0, 0.001));
      verifyNever(() => coupons.findByCode(any()));
    });
  });

  group('Modelos', () {
    test('CartItem.subtotal = precio × cantidad', () {
      expect(const CartItem(product: mouse, quantity: 3).subtotal, 150);
    });

    test('Coupon.isValidAt compara contra la fecha de vencimiento', () {
      final coupon = Coupon(
          code: 'X', discountRate: 0.1, expiresAt: DateTime(2026, 12, 31));
      expect(coupon.isValidAt(DateTime(2026, 12, 30)), isTrue);
      expect(coupon.isValidAt(DateTime(2026, 12, 31)), isFalse);
    });

    test('InsufficientStockException.toString describe el error', () {
      final e = InsufficientStockException(
          productId: 'p1', requested: 6, available: 5);
      expect(e.toString(), contains('p1'));
      expect(e.toString(), contains('6'));
      expect(e.toString(), contains('5'));
    });
  });
}
