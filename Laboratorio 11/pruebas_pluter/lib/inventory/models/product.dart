class Product {
  const Product({required this.id, required this.name, required this.price});

  final String id;
  final String name;
  final double price;
}

class CartItem {
  const CartItem({required this.product, required this.quantity});

  final Product product;
  final int quantity;

  double get subtotal => product.price * quantity;
}
