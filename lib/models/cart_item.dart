import 'home_models.dart';

class CartItem {
  final ProductModel product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  double get totalPrice {
    try {
      final double price = double.parse(product.price);
      return price * quantity;
    } catch (e) {
      return 0.0;
    }
  }
}
