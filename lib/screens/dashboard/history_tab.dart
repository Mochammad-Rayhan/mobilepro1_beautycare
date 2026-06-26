import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/order_history_model.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';

class HistoryTab extends StatefulWidget {
  const HistoryTab({Key? key}) : super(key: key);

  @override
  State<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<HistoryTab> {
  bool _isLoading = true;
  List<OrderHistory> _historyList = [];

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    setState(() => _isLoading = true);
    final userId = AuthService.instance.currentUser?.id;
    if (userId != null) {
      final history = await ApiService().fetchOrderHistory(userId);
      print("HISTORY COUNT: ${history.length}");
      if (history.isNotEmpty) {
         print("FIRST HISTORY ITEM RAW: ${history.first.items.first.product.imageUrl}");
      }
      setState(() {
        _historyList = history;
        _isLoading = false;
      });
    } else {
      // Not logged in or userId is null
      setState(() => _isLoading = false);
    }
  }

  String _formatPrice(double price) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(price);
  }

  String _formatDate(DateTime date) {
    final formatter = DateFormat('dd MMM yyyy, HH:mm');
    return '${formatter.format(date)} WIB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'History Pembelian Kosmetik',
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _historyList.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history,
                    size: 80,
                    color: AppColors.textSecondary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada histori pembelian',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Pesanan Anda akan muncul di sini.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _fetchHistory,
              child: ListView.separated(
                padding: const EdgeInsets.all(20),
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                itemCount: _historyList.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final order = _historyList[index];
                  final firstItem = order.items.isNotEmpty
                      ? order.items.first
                      : null;

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFEEEEEE)),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Date and Status Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.shopping_bag_outlined,
                                  size: 16,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _formatDate(order.createdAt),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Selesai',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24, color: Color(0xFFEEEEEE)),

                        // Product Detail
                        if (firstItem != null)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(
                                  firstItem.product.imageUrl,
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 60,
                                      height: 60,
                                      color: AppColors.primary.withOpacity(0.1),
                                      child: Center(
                                        child: Text(
                                          firstItem.product.name.isNotEmpty 
                                              ? firstItem.product.name[0].toUpperCase() 
                                              : 'P',
                                          style: const TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      firstItem.product.name,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: Color(0xFF1A1A1A),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${firstItem.quantity} barang',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    if (order.items.length > 1) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        '+ ${order.items.length - 1} produk lainnya',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),

                        const SizedBox(height: 16),
                        // Total Price
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total Belanja',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF1A1A1A),
                              ),
                            ),
                            Text(
                              _formatPrice(order.totalPrice),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }
}
