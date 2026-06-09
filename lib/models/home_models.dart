import 'dart:convert';

// Pembungkus Utama Response dari API Laravel
class HomeResponse {
  final bool success;
  final List<ProductModel> products;
  final List<ArticleModel> articles;
  final List<UserModel> users;

  HomeResponse({
    required this.success,
    required this.products,
    required this.articles,
    required this.users,
  });

  factory HomeResponse.fromJson(Map<String, dynamic> json) {
    return HomeResponse(
      success: json['success'] ?? false,
      products: List<ProductModel>.from(
        (json['products'] ?? []).map((x) => ProductModel.fromJson(x)),
      ),
      articles: List<ArticleModel>.from(
        (json['articles'] ?? []).map((x) => ArticleModel.fromJson(x)),
      ),
      users: List<UserModel>.from(
        (json['users'] ?? []).map((x) => UserModel.fromJson(x)),
      ),
    );
  }
}

// Model Product (Sekarang sudah punya field id dari database)
class ProductModel {
  final int id;
  final String imageUrl;
  final String name;
  final String category;
  final String price;
  final int buyers;
  final double rating;
  final String? description;

  const ProductModel({
    required this.id,
    required this.imageUrl,
    required this.name,
    required this.category,
    required this.price,
    required this.buyers,
    required this.rating,
    this.description,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] ?? 0,
      imageUrl: json['image_url'] ?? '',
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      price: json['price'] ?? '',
      buyers: json['buyers'] ?? 0,
      rating: (json['rating'] ?? 0.0).toDouble(),
      description: json['description'],
    );
  }
}

// Model Article (Sekarang sudah punya field id dari database)
class ArticleModel {
  final int id;
  final String imageUrl;
  final String title;
  final String description;
  final String readTime;

  const ArticleModel({
    required this.id,
    required this.imageUrl,
    required this.title,
    required this.description,
    required this.readTime,
  });

  factory ArticleModel.fromJson(Map<String, dynamic> json) {
    return ArticleModel(
      id: json['id'] ?? 0,
      imageUrl: json['image_url'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      readTime: json['read_time'] ?? '',
    );
  }
}

// Model User Baru (Tambahan dari API Laravel Anda)
class UserModel {
  final int id;
  final String name;
  final String email;

  const UserModel({required this.id, required this.name, required this.email});

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
    );
  }
}

// ── Perubahan Penting Banner & Mock Data ──────────────────────────────────────
// Karena API Laravel Anda BELUM mengembalikan data banners, kita simpan class lama
// ini di bawah agar Banner di UI Anda tidak hilang/error saat transisi ke API.
class BannerModel {
  final String imageUrl;
  final String title;
  final String subtitle;
  final String ctaText;

  const BannerModel({
    required this.imageUrl,
    required this.title,
    required this.subtitle,
    required this.ctaText,
  });
}

class HomeData {
  HomeData._();

  // Banner tetap kita hardcode di lokal sementara waktu
  static const List<BannerModel> banners = [
    BannerModel(
      imageUrl:
          'https://images.unsplash.com/photo-1522335789203-aabd1fc54bc9?w=800&q=80',
      title: '✨ Promo Spesial',
      subtitle: 'Diskon hingga 50% untuk produk pilihan',
      ctaText: 'Belanja Sekarang',
    ),
    BannerModel(
      imageUrl:
          'https://images.unsplash.com/photo-1596755389378-c31d21fd1273?w=800&q=80',
      title: '🌿 New Arrival',
      subtitle: 'Koleksi Skincare Terbaru telah hadir',
      ctaText: 'Lihat Koleksi',
    ),
    BannerModel(
      imageUrl:
          'https://images.unsplash.com/photo-1617897903246-719242758050?w=800&q=80',
      title: '💧 Hydration Series',
      subtitle: 'Kulit sehat, lembap & bercahaya',
      ctaText: 'Temukan Produk',
    ),
  ];
}
