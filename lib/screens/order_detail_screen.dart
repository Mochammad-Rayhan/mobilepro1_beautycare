import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/cart_item.dart';
import '../services/cart_service.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';

class OrderDetailScreen extends StatefulWidget {
  final int? currentUserId; // Pass this if the user is logged in
  
  const OrderDetailScreen({super.key, this.currentUserId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final _addressController = TextEditingController();
  bool _isLoading = false;

  String _formatPrice(double price) {
    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return formatter.format(price);
  }

  void _checkout() async {
    final cartItems = CartService.instance.cartNotifier.value;
    if (cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Keranjang Anda kosong!')),
      );
      return;
    }

    final address = _addressController.text.trim();
    if (address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alamat pengiriman harus diisi!')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final totalPrice = CartService.instance.getTotalPrice();
    final userId = widget.currentUserId ?? AuthService.instance.currentUser?.id;
    final result = await ApiService().checkoutOrder(userId, address, totalPrice, cartItems);

    setState(() => _isLoading = false);

    if (result['success'] == true) {
      CartService.instance.clearCart();
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.primary,
                    size: 60,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Pesanan Berhasil!',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Terima kasih telah berbelanja di BeautyCare. Pesanan Anda segera kami proses.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Tutup dialog
                      Navigator.of(context).pop(); // Kembali ke home
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Kembali ke Beranda',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${result['message']}'),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: AppColors.primary),
        title: const Text(
          'Detail Pesanan',
          style: TextStyle(color: Color(0xFF1A1A1A), fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: ValueListenableBuilder<List<CartItem>>(
        valueListenable: CartService.instance.cartNotifier,
        builder: (context, cartItems, child) {
          if (cartItems.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  const Text('Keranjang belanja Anda kosong', style: TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(20),
                  physics: const BouncingScrollPhysics(),
                  itemCount: cartItems.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final item = cartItems[index];
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFEEEEEE)),
                        boxShadow: [
                          BoxShadow(color: AppColors.primary.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Product Image
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              item.product.imageUrl,
                              width: 70,
                              height: 70,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(width: 70, height: 70, color: Colors.grey[200], child: const Icon(Icons.image)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Product Details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.product.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatPrice(double.tryParse(item.product.price) ?? 0),
                                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                // Counter & Trash Row
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(color: const Color(0xFFEEEEEE)),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          InkWell(
                                            onTap: () => CartService.instance.updateQuantity(item.product.id, -1),
                                            child: const Padding(padding: EdgeInsets.all(6), child: Icon(Icons.remove, size: 16)),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 8),
                                            child: Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                          ),
                                          InkWell(
                                            onTap: () => CartService.instance.updateQuantity(item.product.id, 1),
                                            child: const Padding(padding: EdgeInsets.all(6), child: Icon(Icons.add, size: 16)),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () => CartService.instance.removeFromCart(item.product.id),
                                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              // Address & Summary Section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Alamat Pengiriman', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _addressController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Masukkan alamat lengkap Anda...',
                        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                        filled: true,
                        fillColor: const Color(0xFFF9F9F9),
                        contentPadding: const EdgeInsets.all(12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Harga', style: TextStyle(color: Colors.grey, fontSize: 14)),
                        Text(
                          _formatPrice(CartService.instance.getTotalPrice()),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _checkout,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isLoading
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('Beli Sekarang', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }
}
