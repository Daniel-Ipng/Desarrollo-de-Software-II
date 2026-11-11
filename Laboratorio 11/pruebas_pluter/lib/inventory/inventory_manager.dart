import 'insufficient_stock_exception.dart';
import 'models/product.dart';
import 'services/coupon_repository.dart';
import 'services/location_service.dart';
import 'services/stock_api_service.dart';

export 'insufficient_stock_exception.dart';
export 'models/coupon.dart';
export 'models/product.dart';
export 'services/coupon_repository.dart';
export 'services/location_service.dart';
export 'services/stock_api_service.dart';

class InventoryManager {
  InventoryManager({
    required StockApiService stockApi,
    required LocationService locationService,
    required CouponRepository couponRepository,
    required Map<String, double> taxRatesByRegion,
    double defaultTaxRate = 0.0,
    DateTime Function()? clock,
  })  : _stockApi = stockApi,
        _locationService = locationService,
        _couponRepository = couponRepository,
        _taxRatesByRegion = taxRatesByRegion,
        _defaultTaxRate = defaultTaxRate,
        _clock = clock ?? DateTime.now;

  final StockApiService _stockApi;
  final LocationService _locationService;
  final CouponRepository _couponRepository;
  final Map<String, double> _taxRatesByRegion;
  final double _defaultTaxRate;
  final DateTime Function() _clock;

  final Map<String, CartItem> _cart = {};
  String? _couponCode;

  List<CartItem> get items => List.unmodifiable(_cart.values);

  int quantityOf(String productId) => _cart[productId]?.quantity ?? 0;

  /// Agrega [quantity] unidades de [product] al carrito (acumulando).
  /// Lanza [InsufficientStockException] si lo acumulado supera el stock remoto.
  Future<void> addProduct(Product product, int quantity) async {
    if (quantity <= 0) {
      throw ArgumentError.value(quantity, 'quantity', 'Debe ser mayor que cero');
    }
    final available = await _stockApi.getAvailableStock(product.id);
    final requested = quantityOf(product.id) + quantity;
    if (requested > available) {
      throw InsufficientStockException(
        productId: product.id,
        requested: requested,
        available: available,
      );
    }
    _cart[product.id] = CartItem(product: product, quantity: requested);
  }

  void applyCoupon(String code) {
    _couponCode = code;
  }

  void clearCoupon() {
    _couponCode = null;
  }

  /// total = (subtotal − descuento del cupón válido) × (1 + tasa regional)
  Future<double> calculateTotal() async {
    final subtotal = _cart.values.fold<double>(0, (sum, i) => sum + i.subtotal);
    final region = await _locationService.getRegionCode();
    final taxRate = _taxRatesByRegion[region] ?? _defaultTaxRate;
    final discountRate = await _currentDiscountRate();
    return subtotal * (1 - discountRate) * (1 + taxRate);
  }

  Future<double> _currentDiscountRate() async {
    final code = _couponCode;
    if (code == null) return 0;
    final coupon = await _couponRepository.findByCode(code);
    if (coupon == null || !coupon.isValidAt(_clock())) return 0;
    return coupon.discountRate;
  }
}
