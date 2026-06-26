// lib/screens/dashboard/home_tab.dart
// Main Home screen for BeautyCare app with Laravel API integration.

import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../models/home_models.dart';
import '../../services/api_service.dart'; // Import ApiService Anda
import '../../widgets/home/promo_banner_carousel.dart';
import '../../widgets/home/product_card.dart';
import '../../widgets/home/article_card.dart';
import '../category_products_screen.dart';

class HomeTab extends StatefulWidget {
  final String userName; // Nama fallback jika data user di API kosong

  const HomeTab({super.key, required this.userName});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  late Future<HomeResponse> _homeDataFuture;

  @override
  void initState() {
    super.initState();
    // Memicu pengambilan data dari API Laravel saat widget pertama kali dibuat
    _homeDataFuture = ApiService().fetchHomeData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: FutureBuilder<HomeResponse>(
          future: _homeDataFuture,
          builder: (context, snapshot) {
            // ── [Kondisi 1] Sedang Menunggu Data (Loading) ──
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }

            // ── [Kondisi 2] Terjadi Masalah Koneksi/Error ──
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.wifi_off_rounded,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Gagal memuat data halaman\n${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _homeDataFuture = ApiService().fetchHomeData();
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                        ),
                        child: const Text(
                          'Coba Lagi',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            // ── [Kondisi 3] Data Sukses Didapatkan ──
            if (snapshot.hasData) {
              final apiData = snapshot.data!;

              // Gunakan parameter nama user yang login
              final String profileName = widget.userName;

              return RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () async {
                  setState(() {
                    _homeDataFuture = ApiService().fetchHomeData();
                  });
                },
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 24),

                        // ── [1] Header (Nama diambil dari data API) ──
                        _HeaderSection(userName: profileName),
                        const SizedBox(height: 22),

                        // ── [2] Promo Banner Carousel (Tetap pakai mock data lokal) ──
                        const PromoBannerCarousel(),
                        const SizedBox(height: 28),

                        // ── [3] Pilihan Kategori ──
                        const _SectionHeader(title: 'Pilihan Kategori'),
                        const SizedBox(height: 14),
                        _CategoryRow(products: apiData.products),
                        const SizedBox(height: 28),

                        // ── [4] Rekomendasi Untukmu (Data Asli dari API) ──
                        const _SectionHeader(
                          title: 'Rekomendasi Untukmu',
                          actionText: 'Lihat Semua',
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          height: 298,
                          child: apiData.products.isEmpty
                              ? const Center(
                                  child: Text('Tidak ada produk tersedia'),
                                )
                              : ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  physics: const BouncingScrollPhysics(),
                                  itemCount: apiData.products.length,
                                  itemBuilder: (_, i) =>
                                      ProductCard(product: apiData.products[i]),
                                ),
                        ),
                        const SizedBox(height: 28),

                        // ── [5] BeautyPedia (Data Asli dari API) ──
                        const _SectionHeader(
                          title: 'BeautyPedia',
                          actionText: 'Semua Artikel',
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          height: 260,
                          child: apiData.articles.isEmpty
                              ? const Center(
                                  child: Text('Tidak ada artikel tersedia'),
                                )
                              : ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  physics: const BouncingScrollPhysics(),
                                  itemCount: apiData.articles.length,
                                  itemBuilder: (_, i) =>
                                      ArticleCard(article: apiData.articles[i]),
                                ),
                        ),

                        // Bottom nav spacing
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              );
            }

            return const Center(child: Text('Tidak ada data'));
          },
        ),
      ),
    );
  }
}

// ── [1] Header ────────────────────────────────────────────────────────────────
class _HeaderSection extends StatelessWidget {
  final String userName;
  const _HeaderSection({required this.userName});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hello, $userName',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 3),
              const Text(
                'Selamat datang di Beautycare!',
                style: TextStyle(fontSize: 14, color: Color(0xFF8C8C8C)),
              ),
            ],
          ),
        ),
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.notifications_outlined,
            color: AppColors.primary,
            size: 22,
          ),
        ),
      ],
    );
  }
}

// ── Section Header ────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final String? actionText;

  const _SectionHeader({required this.title, this.actionText});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A1A),
          ),
        ),
        if (actionText != null)
          GestureDetector(
            onTap: () {},
            child: Text(
              actionText!,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
      ],
    );
  }
}

// ── [3] Category Row ──────────────────────────────────────────────────────────
class _CategoryRow extends StatelessWidget {
  final List<ProductModel> products;
  const _CategoryRow({required this.products});

  static const List<_CategoryData> _items = [
    _CategoryData(
      icon: Icons.water_drop_outlined,
      label: 'Facewash',
      bg: Color(0xFFFFE9F0),
      iconColor: Color(0xFFFF6B9D),
    ),
    _CategoryData(
      icon: Icons.face_retouching_natural,
      label: 'Skincare',
      bg: Color(0xFFEDE7FF),
      iconColor: Color(0xFF8B5CF6),
    ),
    _CategoryData(
      icon: Icons.spa_outlined,
      label: 'Bodycare',
      bg: Color(0xFFDCFCE7),
      iconColor: Color(0xFF22C55E),
    ),
    _CategoryData(
      icon: Icons.grid_view_rounded,
      label: 'Lainnya',
      bg: Color(0xFFFFF3CD),
      iconColor: Color(0xFFF59E0B),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: _items
          .map(
            (item) => Expanded(
              child: _CategoryItem(data: item, products: products),
            ),
          )
          .toList(),
    );
  }
}

class _CategoryData {
  final IconData icon;
  final String label;
  final Color bg;
  final Color iconColor;

  const _CategoryData({
    required this.icon,
    required this.label,
    required this.bg,
    required this.iconColor,
  });
}

class _CategoryItem extends StatelessWidget {
  final _CategoryData data;
  final List<ProductModel> products;
  const _CategoryItem({required this.data, required this.products});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CategoryProductsScreen(
              categoryName: data.label,
              allProducts: products,
            ),
          ),
        );
      },
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: data.bg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(data.icon, color: data.iconColor, size: 26),
          ),
          const SizedBox(height: 7),
          Text(
            data.label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
