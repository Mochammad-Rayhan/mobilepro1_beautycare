import 'home_models.dart';

class OrderHistoryItem {
  final int id;
  final ProductModel product;
  final int quantity;
  final double price;

  OrderHistoryItem({
    required this.id,
    required this.product,
    required this.quantity,
    required this.price,
  });

  factory OrderHistoryItem.fromJson(Map<String, dynamic> json) {
    ProductModel parsedProduct;
    if (json['product'] != null && json['product'] is Map) {
      parsedProduct = ProductModel.fromJson(Map<String, dynamic>.from(json['product']));
    } else {
      parsedProduct = ProductModel(
        id: 0,
        name: json['product_name']?.toString() ?? 'Unknown Product',
        imageUrl: json['product_image_url']?.toString() ?? '',
        category: '',
        price: '0',
        buyers: 0,
        rating: 0.0,
      );
    }

    return OrderHistoryItem(
      id: json['id'] ?? 0,
      product: parsedProduct,
      quantity: json['quantity'] ?? 1,
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
    );
  }
}

class OrderHistory {
  final int id;
  final double totalPrice;
  final DateTime createdAt;
  final List<OrderHistoryItem> items;

  OrderHistory({
    required this.id,
    required this.totalPrice,
    required this.createdAt,
    required this.items,
  });

  factory OrderHistory.fromJson(Map<String, dynamic> json) {
    var itemsList = json['items'] as List? ?? [];
    List<OrderHistoryItem> parsedItems =
        itemsList.map((i) => OrderHistoryItem.fromJson(i)).toList();

    return OrderHistory(
      id: json['id'] ?? 0,
      totalPrice: double.tryParse(json['total_price']?.toString() ?? '0') ?? 0.0,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at']) ?? DateTime.now()
          : DateTime.now(),
      items: parsedItems,
    );
  }
}
