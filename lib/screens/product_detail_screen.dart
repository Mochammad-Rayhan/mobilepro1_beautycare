import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/home_models.dart';
import '../theme/app_colors.dart';
<<<<<<< HEAD
import '../services/cart_service.dart';
import 'order_detail_screen.dart';
=======
>>>>>>> 8985c0d7e200dd4738632a81834fc6231659dc18

class ProductDetailScreen extends StatelessWidget {
  final ProductModel product;

  const ProductDetailScreen({super.key, required this.product});

  String _formatPrice(String price) {
    try {
      final parsedPrice = double.parse(price);
      final formatter = NumberFormat.currency(
        locale: 'id_ID',
        symbol: 'Rp ',
        decimalDigits: 0,
      );
      return formatter.format(parsedPrice);
    } catch (e) {
      return 'Rp $price';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFCF8), // Soft cream background
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProductImage(),
                    const SizedBox(height: 24),
                    _buildCategoryTag(),
                    const SizedBox(height: 12),
                    _buildTitleAndRating(),
                    const SizedBox(height: 24),
                    const Divider(color: Color(0xFFE5E5E5), height: 1),
                    const SizedBox(height: 24),
                    _buildPriceSection(),
                    const SizedBox(height: 24),
                    _buildDescriptionSection(),
                    const SizedBox(height: 24),
                    const Divider(color: Color(0xFFE5E5E5), height: 1),
                    const SizedBox(height: 24),
                    _buildSkinTypeTags(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
<<<<<<< HEAD
            _buildBottomBar(context),
=======
            _buildBottomBar(),
>>>>>>> 8985c0d7e200dd4738632a81834fc6231659dc18
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A1A)),
            onPressed: () => Navigator.pop(context),
          ),
          Text(
            'PRODUCT DETAIL',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: 2.0,
              color: AppColors.primary,
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.shopping_bag_outlined,
              color: Color(0xFF1A1A1A),
            ),
<<<<<<< HEAD
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const OrderDetailScreen(),
                ),
              );
            },
=======
            onPressed: () {},
>>>>>>> 8985c0d7e200dd4738632a81834fc6231659dc18
          ),
        ],
      ),
    );
  }

  Widget _buildProductImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: double.infinity,
        height: 300,
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Image.network(
          product.imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stack) => const Center(
            child: Icon(
              Icons.image_not_supported,
              size: 50,
              color: Colors.grey,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryTag() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5E5E5)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        product.category.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF8C8C8C),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildTitleAndRating() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          product.name,
          style: GoogleFonts.inter(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1A1A1A),
            height: 1.2,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Icon(Icons.star, color: Color(0xFF1A1A1A), size: 16),
            const SizedBox(width: 4),
            Text(
              product.rating.toString(),
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${product.buyers} Reviews',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF8C8C8C),
                decoration: TextDecoration.underline,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPriceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _formatPrice(product.price),
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Free standard shipping included',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF8C8C8C),
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'THE RITUAL',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
            color: const Color(0xFF8C8C8C),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          product.description ??
              'A potent, anti-aging serum formulated with advanced peptides and hyaluronic acid to visibly firm, brighten, and hydrate your skin. Suitable for all skin types, especially those seeking a youthful glow.',
          style: GoogleFonts.inter(
            fontSize: 15,
            height: 1.8,
            color: const Color(0xFF1A1A1A),
          ),
        ),
      ],
    );
  }

  Widget _buildSkinTypeTags() {
    return Row(
      children: [
        _buildTag('Oily'),
        const SizedBox(width: 10),
        _buildTag('Dry'),
        const SizedBox(width: 10),
        _buildTag('Sensitive'),
      ],
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF1A1A1A),
        ),
      ),
    );
  }

<<<<<<< HEAD
  Widget _buildBottomBar(BuildContext context) {
=======
  Widget _buildBottomBar() {
>>>>>>> 8985c0d7e200dd4738632a81834fc6231659dc18
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: const BoxDecoration(
        color: Color(0xFFFDFCF8),
        border: Border(top: BorderSide(color: Color(0xFFE5E5E5), width: 1)),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE5E5E5)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.share_outlined, color: Color(0xFF1A1A1A)),
              onPressed: () {},
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: SizedBox(
              height: 50,
              child: ElevatedButton(
<<<<<<< HEAD
                onPressed: () {
                  CartService.instance.addToCart(product);
                  final navigator = Navigator.of(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Produk ditambahkan ke keranjang'),
                      action: SnackBarAction(
                        label: 'CHECKOUT',
                        textColor: Colors.white,
                        onPressed: () {
                          navigator.push(
                            MaterialPageRoute(
                              builder: (context) => const OrderDetailScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
=======
                onPressed: () {},
>>>>>>> 8985c0d7e200dd4738632a81834fc6231659dc18
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'ADD TO CART',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
