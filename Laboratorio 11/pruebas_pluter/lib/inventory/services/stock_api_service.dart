/// Servicio remoto que informa las existencias disponibles.
abstract class StockApiService {
  Future<int> getAvailableStock(String productId);
}
