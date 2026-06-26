import 'package:flutter/material.dart';
import '../models/home_models.dart';
import '../theme/app_colors.dart';
import '../widgets/home/product_card.dart';

class CategoryProductsScreen extends StatelessWidget {
  final String categoryName;
  final List<ProductModel> allProducts;

  const CategoryProductsScreen({
    super.key,
    required this.categoryName,
    required this.allProducts,
  });

  @override
  Widget build(BuildContext context) {
    // Filter produk berdasarkan kategori (case-insensitive)
    final filteredProducts = allProducts.where((product) {
      return product.category.toLowerCase() == categoryName.toLowerCase();
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: AppColors.primary),
        title: Text(
          'Kategori: $categoryName',
          style: const TextStyle(
            color: Color(0xFF1A1A1A),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: filteredProducts.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 64,
                    color: Colors.grey.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada produk untuk\nkategori $categoryName',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(20),
              physics: const BouncingScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                mainAxisExtent: 298, // Menggunakan tinggi tetap agar sesuai konten dan jarak bawah ~10px
              ),
              itemCount: filteredProducts.length,
              itemBuilder: (context, index) {
                return ProductCard(
                  product: filteredProducts[index],
                  width: null, // Biarkan menyesuaikan dengan cell GridView
                  rightMargin: 0, // Hapus margin agar rapi di grid
                );
              },
            ),
    );
  }
}
