import 'package:flutter/foundation.dart';
import '../models/home_models.dart';
import '../models/cart_item.dart';

class CartService {
  // Singleton pattern
  CartService._privateConstructor();
  static final CartService instance = CartService._privateConstructor();

  final ValueNotifier<List<CartItem>> cartNotifier = ValueNotifier([]);

  void addToCart(ProductModel product) {
    final currentCart = List<CartItem>.from(cartNotifier.value);
    
    // Check if product already exists in cart
    final index = currentCart.indexWhere((item) => item.product.id == product.id);
    
    if (index >= 0) {
      // Increment quantity
      currentCart[index].quantity++;
    } else {
      // Add new item
      currentCart.add(CartItem(product: product));
    }
    
    cartNotifier.value = currentCart;
  }

  void removeFromCart(int productId) {
    final currentCart = List<CartItem>.from(cartNotifier.value);
    currentCart.removeWhere((item) => item.product.id == productId);
    cartNotifier.value = currentCart;
  }

  void updateQuantity(int productId, int delta) {
    final currentCart = List<CartItem>.from(cartNotifier.value);
    final index = currentCart.indexWhere((item) => item.product.id == productId);
    
    if (index >= 0) {
      currentCart[index].quantity += delta;
      if (currentCart[index].quantity <= 0) {
        currentCart.removeAt(index);
      }
      cartNotifier.value = currentCart;
    }
  }

  double getTotalPrice() {
    double total = 0.0;
    for (var item in cartNotifier.value) {
      total += item.totalPrice;
    }
    return total;
  }

  void clearCart() {
    cartNotifier.value = [];
  }
}
