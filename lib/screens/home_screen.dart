import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../services/utils.dart';
import 'login_screen.dart';
import 'consultation_screen.dart';
import 'catalog_screen.dart';
import 'history_screen.dart';
import 'education_screen.dart';
import 'main_screen.dart';
import 'package:dio/dio.dart';
import '../services/api_service.dart';
import '../providers/block_provider.dart';
import 'block_monitor_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<double>> _cardAnimations;

  final ApiService _apiService = ApiService();
  List<dynamic> _banners = [];
  List<dynamic> _products = [];
  bool _isLoadingProducts = true;
  late PageController _pageController;
  Timer? _bannerTimer;
  int _currentBannerPage = 0;

  final Map<String, dynamic> _farmStats = {
    'activeBaglogs': 120,
    'harvestReady': 35,
    'totalHarvest': '48 kg',
    'weather': 'Memuat cuaca...',
    'humidity': '-%',
    'temperature': '-°C',
  };

  // Notifications are loaded dynamically from BlockProvider

  final List<Map<String, dynamic>> _menuItems = [
    {
      'title': 'Katalog Baglog',
      'subtitle': 'Jelajahi produk',
      'icon': Icons.shopping_bag_rounded,
      'color': const Color(0xFFFF8C42),
      'bgColor': const Color(0xFFFFF3E9),
    },
    {
      'title': 'Konsultasi',
      'subtitle': 'Diagnosis cerdas',
      'icon': Icons.psychology_rounded,
      'color': const Color(0xFF4A90D9),
      'bgColor': const Color(0xFFE8F2FC),
    },
    {
      'title': 'Edukasi Tanam',
      'subtitle': 'Panduan & tips',
      'icon': Icons.menu_book_rounded,
      'color': const Color(0xFF2ECC8E),
      'bgColor': const Color(0xFFE5F9F2),
    },
    {
      'title': 'Riwayat',
      'subtitle': 'Transaksi & log',
      'icon': Icons.history_rounded,
      'color': const Color(0xFF8B7EC8),
      'bgColor': const Color(0xFFF0EEF9),
    },
    {
      'title': 'Monitor Blok',
      'subtitle': 'Status kumbung',
      'icon': Icons.sensor_window_rounded,
      'color': const Color(0xFFE04F6A),
      'bgColor': const Color(0xFFFCECEF),
    },
    {
      'title': 'Bookmark',
      'subtitle': 'Rekomendasi hasil',
      'icon': Icons.bookmark,
      'color': const Color(0xFF3ABCB7),
      'bgColor': const Color(0xFFE5F7F7),
    },
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _cardAnimations = List.generate(
      _menuItems.length,
      (i) => CurvedAnimation(
        parent: _controller,
        curve: Interval(i * 0.1, 0.6 + i * 0.07, curve: Curves.easeOutBack),
      ),
    );

    _controller.forward();
    _fetchWeather();
    _fetchBanners();
    _fetchProducts();
  }

  Future<void> _fetchWeather() async {
    try {
      final dio = Dio();
      final response = await dio.get(
        'https://api.openweathermap.org/data/2.5/weather',
        queryParameters: {
          'q': 'Malang',
          'appid': '5a13ab74f6d755ac184adb2c952322cb',
          'units': 'metric',
          'lang': 'id',
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        String desc = data['weather'][0]['description'].toString();
        String capitalized = desc.isNotEmpty
            ? '${desc[0].toUpperCase()}${desc.substring(1)}'
            : desc;

        setState(() {
          _farmStats['weather'] = capitalized;
          _farmStats['temperature'] = '${data['main']['temp'].round()}°C';
          _farmStats['humidity'] = '${data['main']['humidity']}%';
        });
      }
    } catch (e) {
      setState(() {
        _farmStats['weather'] = 'Gagal memuat cuaca';
      });
    }
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _pageController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _fetchBanners() async {
    try {
      final response = await _apiService.get('banners');
      if (response.statusCode == 200) {
        setState(() {
          _banners = response.data['data'];
        });
        _startBannerTimer();
      }
    } catch (e) {
      // Keep silent fallback gradient
    }
  }

  void _startBannerTimer() {
    _bannerTimer?.cancel();
    if (_banners.length > 1) {
      _bannerTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
        if (_pageController.hasClients) {
          int nextPage = _currentBannerPage + 1;
          if (nextPage >= _banners.length) {
            nextPage = 0;
          }
          _pageController.animateToPage(
            nextPage,
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  String _formatImageUrl(String? url) {
    if (url == null) return '';
    String formatted = url;
    try {
      if (Platform.isAndroid) {
        formatted = formatted.replaceAll('127.0.0.1:8000', '10.0.2.2:8000');
        formatted = formatted.replaceAll('localhost:8000', '10.0.2.2:8000');
      }
    } catch (e) {
      // safe fallback
    }
    return formatted;
  }

  Future<void> _fetchProducts() async {
    debugPrint('TiramkuDebug: _fetchProducts started');
    try {
      final response = await _apiService.get('products');
      debugPrint('TiramkuDebug: response status: ${response.statusCode}');
      if (response.statusCode == 200) {
        setState(() {
          _products = response.data['data'] ?? [];
          _isLoadingProducts = false;
        });
        debugPrint('TiramkuDebug: loaded ${_products.length} products');
      } else {
        setState(() {
          _isLoadingProducts = false;
        });
        debugPrint('TiramkuDebug: failed with status: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _isLoadingProducts = false;
      });
      debugPrint('TiramkuDebug: error in _fetchProducts: $e');
    }
  }

  void _showProductDetail(BuildContext context, Map<String, dynamic> prod) {
    final cart = Provider.of<CartProvider>(context, listen: false);
    final stock = prod['stock'] ?? 0;
    final isOutOfStock = stock <= 0;
    final limit = prod['paket'] ?? 100;
    int quantity = 1;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(top: 12, bottom: 8),
                        width: 48,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2.5),
                        ),
                      ),
                    ),

                    Container(
                      height: 220,
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: prod['image'] != null
                            ? Image.network(
                                _formatImageUrl(
                                  'http://10.0.2.2:8000/storage/${prod['image']}',
                                ),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                      color: const Color(
                                        0xFF1B4332,
                                      ).withOpacity(0.04),
                                      child: const Icon(
                                        Icons.eco,
                                        size: 64,
                                        color: Color(0xFF1B4332),
                                      ),
                                    ),
                              )
                            : Container(
                                decoration: const BoxDecoration(
                                  color: Color(0xFFE8F5E9),
                                ),
                                child: const Icon(
                                  Icons.eco_rounded,
                                  size: 64,
                                  color: Color(0xFF1B4332),
                                ),
                              ),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  prod['name'] ?? '',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1B4332),
                                  ),
                                ),
                              ),
                              if (prod['category'] != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE5F9F2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    prod['category']['name'] ?? '',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2ECC8E),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          Text(
                            'Rp ${formatNumber(prod['price'])}',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                          const SizedBox(height: 16),

                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF5F7FA),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.grey.shade100,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Ketersediaan',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade500,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        isOutOfStock
                                            ? 'Stok Habis'
                                            : 'Stok: ${formatNumber(stock)}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: isOutOfStock
                                              ? const Color(0xFFE04F6A)
                                              : const Color(0xFF1B4332),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF5F7FA),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.grey.shade100,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Ukuran Paket',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade500,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${formatNumber(limit)} Baglog/Pkt',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1B4332),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          const Text(
                            'Deskripsi Produk',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1B4332),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            (prod['description'] != null &&
                                    prod['description']
                                        .toString()
                                        .trim()
                                        .isNotEmpty)
                                ? prod['description']
                                : 'Baglog jamur tiram berkualitas unggul, siap dibudidayakan. Dibuat dari serbuk kayu pilihan dengan nutrisi seimbang untuk pertumbuhan miselium yang cepat dan merata. Tahan terhadap kontaminasi dan siap panen dalam waktu singkat.',
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.5,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 24),

                          if (!isOutOfStock) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Jumlah Pembelian',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1B4332),
                                  ),
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                    ),
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.remove,
                                          size: 18,
                                        ),
                                        onPressed: () {
                                          if (quantity > 1) {
                                            setModalState(() {
                                              quantity--;
                                            });
                                          }
                                        },
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                        ),
                                        child: Text(
                                          '$quantity',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.add, size: 18),
                                        onPressed: () {
                                          if (quantity < stock) {
                                            setModalState(() {
                                              quantity++;
                                            });
                                          } else {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Stok maksimum tercapai (${formatNumber(stock)})',
                                                ),
                                                behavior:
                                                    SnackBarBehavior.floating,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                backgroundColor: const Color(
                                                  0xFFE04F6A,
                                                ),
                                                duration: const Duration(
                                                  seconds: 1,
                                                ),
                                              ),
                                            );
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                          ],

                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: isOutOfStock
                                  ? null
                                  : () {
                                      for (int i = 0; i < quantity; i++) {
                                        cart.addItem(
                                          prod['id'],
                                          prod['price'],
                                          prod['name'],
                                          imageUrl: prod['image'],
                                        );
                                      }
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(
                                        context,
                                      ).hideCurrentSnackBar();
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Ditambahkan $quantity item ke keranjang!',
                                          ),
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          backgroundColor: const Color(
                                            0xFF1B4332,
                                          ),
                                          duration: const Duration(seconds: 2),
                                        ),
                                      );
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1B4332),
                                disabledBackgroundColor: Colors.grey.shade300,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                isOutOfStock
                                    ? 'Stok Habis'
                                    : 'Tambah ke Keranjang',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isOutOfStock
                                      ? Colors.grey.shade500
                                      : Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildProductCard(Map<String, dynamic> prod) {
    final stock = prod['stock'] ?? 0;
    final isOutOfStock = stock <= 0;

    return GestureDetector(
      onTap: () => _showProductDetail(context, prod),
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade100, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    child: prod['image'] != null
                        ? Image.network(
                            _formatImageUrl(
                              'http://10.0.2.2:8000/storage/${prod['image']}',
                            ),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  color: const Color(
                                    0xFF1B4332,
                                  ).withOpacity(0.04),
                                  child: const Icon(
                                    Icons.eco_rounded,
                                    size: 36,
                                    color: Color(0xFF1B4332),
                                  ),
                                ),
                          )
                        : Container(
                            decoration: const BoxDecoration(
                              color: Color(0xFFE8F5E9),
                            ),
                            child: const Icon(
                              Icons.eco_rounded,
                              size: 36,
                              color: Color(0xFF1B4332),
                            ),
                          ),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5F9F2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.eco_rounded,
                            color: Color(0xFF2ECC8E),
                            size: 10,
                          ),
                          SizedBox(width: 2),
                          Text(
                            'ECO',
                            style: TextStyle(
                              color: Color(0xFF2ECC8E),
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (isOutOfStock)
                    Container(
                      decoration: const BoxDecoration(
                        color: Colors.black38,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          'HABIS',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    prod['name'] ?? '',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Color(0xFF1B4332),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Rp ${formatNumber(prod['price'])}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductShimmer() {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.image_rounded,
                  color: Colors.grey.shade300,
                  size: 36,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 100,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 60,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyProducts() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100, width: 1.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_rounded,
            color: Colors.grey.shade300,
            size: 40,
          ),
          const SizedBox(height: 8),
          const Text(
            'Produk segera hadir!',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B4332),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Kami sedang menyiapkan produk terbaik untuk Anda.',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _navigate(BuildContext context, int index) {
    // Switch active tab of MainScreen if MainScreen is an ancestor
    if (index == 0) {
      // Katalog Baglog -> Tab Index 1
      final mainScreenState = context
          .findAncestorStateOfType<MainScreenState>();
      if (mainScreenState != null) {
        mainScreenState.switchTab(1);
        return;
      }
    } else if (index == 1) {
      // Konsultasi -> Tab Index 2
      final mainScreenState = context
          .findAncestorStateOfType<MainScreenState>();
      if (mainScreenState != null) {
        mainScreenState.switchTab(2);
        return;
      }
    } else if (index == 3) {
      // Riwayat -> Tab Index 3
      final mainScreenState = context
          .findAncestorStateOfType<MainScreenState>();
      if (mainScreenState != null) {
        mainScreenState.switchTab(3);
        return;
      }
    }

    final routes = [
      const CatalogScreen(),
      const ConsultationScreen(),
      const EducationScreen(),
      const HistoryScreen(),
      const BlockMonitorScreen(), // Monitor Blok (aktif)
      null, // Laporan (belum ada)
    ];

    final target = routes[index];
    if (target != null) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => target));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fitur "${_menuItems[index]['title']}" segera hadir!'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: const Color(0xFF2ECC8E),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final userName = auth.user?['name'] ?? 'Petani';
    final now = DateTime.now();
    final greeting = now.hour < 11
        ? 'Selamat Pagi'
        : now.hour < 15
        ? 'Selamat Siang'
        : now.hour < 18
        ? 'Selamat Sore'
        : 'Selamat Malam';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // === HEADER (SLIVERAPPBAR) WITH LARGE SLIDING BANNER BACKGROUND ===
          SliverAppBar(
            expandedHeight: 220,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: const Color(0xFF1B4332),
            flexibleSpace: FlexibleSpaceBar(
              background: _buildHeader(greeting, userName, auth.user, auth),
            ),
            actions: [
              Consumer<BlockProvider>(
                builder: (context, blockProvider, _) {
                  final count = blockProvider.notifications.length;
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.notifications_outlined,
                          color: Colors.white,
                          size: 26,
                        ),
                        onPressed: () => _showNotificationsSheet(context),
                      ),
                      if (count > 0)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: IgnorePointer(
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE04F6A),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFF1B4332),
                                  width: 1.5,
                                ),
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 16,
                                minHeight: 16,
                              ),
                              child: Text(
                                '$count',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              IconButton(
                icon: const Icon(
                  Icons.logout_rounded,
                  color: Colors.white,
                  size: 26,
                ),
                onPressed: () => _confirmLogout(context, auth),
              ),
            ],
          ),

          // === CUACA ===
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: _buildWeatherCard(),
            ),
          ),

          // === MENU TITLE ===
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 24, 20, 10),
              child: Text(
                'Menu Utama',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B4332),
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),

          // === GRID MENU ===
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.88,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, i) => ScaleTransition(
                  scale: _cardAnimations[i],
                  child: _buildMenuCard(context, i),
                ),
                childCount: _menuItems.length,
              ),
            ),
          ),
          // === SEPARATOR ===
          const SliverPadding(padding: EdgeInsets.only(bottom: 24)),

          // === SECTION HEADER: PRODUK PILIHAN ===
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Produk Pilihan',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B4332),
                      letterSpacing: 0.2,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const CatalogScreen(),
                        ),
                      );
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      foregroundColor: const Color(0xFF2ECC8E),
                    ),
                    child: const Row(
                      children: [
                        Text(
                          'Lihat Semua',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward_rounded, size: 14),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // === PRODUCT SLIDER CAROUSEL ===
          SliverToBoxAdapter(
            child: Container(
              height: 180,
              margin: const EdgeInsets.only(top: 8, bottom: 32),
              child: _isLoadingProducts
                  ? ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      scrollDirection: Axis.horizontal,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: 3,
                      itemBuilder: (context, index) => _buildProductShimmer(),
                    )
                  : _products.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildEmptyProducts(),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: _products.length,
                      itemBuilder: (context, index) {
                        return _buildProductCard(_products[index]);
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Header ───────────────────────────────────────────────
  Widget _buildHeader(
    String greeting,
    String userName,
    Map<String, dynamic>? user,
    AuthProvider auth,
  ) {
    return Stack(
      children: [
        // Layer 1: Carousel sliding background or solid green fallback
        Positioned.fill(
          child: _banners.isEmpty
              ? Container(
                  decoration: const BoxDecoration(color: Color(0xFF1B4332)),
                )
              : PageView.builder(
                  controller: _pageController,
                  itemCount: _banners.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentBannerPage = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    final bannerUrl = _formatImageUrl(_banners[index]['image']);
                    return Image.network(
                      bannerUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, stack) => Container(
                        decoration: const BoxDecoration(
                          color: Color(0xFF1B4332),
                        ),
                      ),
                    );
                  },
                ),
        ),

        // Layer 2: Semi-transparent dark overlay to ensure white text readability
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(color: Colors.black.withOpacity(0.4)),
          ),
        ),

        // Layer 3: Profile info and greetings
        Positioned(
          bottom: 20,
          left: 20,
          right: 20,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(1.5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF2ECC8E),
                    width: 1.5,
                  ),
                ),
                child: CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.white24,
                  backgroundImage: user?['photo'] != null
                      ? NetworkImage(_formatImageUrl(user?['photo']))
                      : null,
                  child: user?['photo'] == null
                      ? Text(
                          userName.isNotEmpty ? userName[0].toUpperCase() : 'P',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      greeting,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        shadows: [
                          Shadow(
                            blurRadius: 4,
                            color: Colors.black38,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      userName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            blurRadius: 4,
                            color: Colors.black38,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Dynamic banner dot indicator inside header
              if (_banners.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black38,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(
                      _banners.length,
                      (idx) => Container(
                        width: _currentBannerPage == idx ? 12 : 5,
                        height: 5,
                        margin: const EdgeInsets.symmetric(horizontal: 1.5),
                        decoration: BoxDecoration(
                          color: _currentBannerPage == idx
                              ? const Color(0xFF2ECC8E)
                              : Colors.white60,
                          borderRadius: BorderRadius.circular(2.5),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Weather Card ─────────────────────────────────────────
  Widget _buildWeatherCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF4A90D9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4A90D9).withOpacity(0.2),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Colors.white24,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.wb_cloudy_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _farmStats['weather'] ?? 'Memuat cuaca...',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Suhu: ${_farmStats['temperature']}',
                  style: const TextStyle(
                    color: Color(0xDDFFFFFF),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white24),
            ),
            child: const Column(
              children: [
                Text(
                  'Kondisi',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'OPTIMAL',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Menu Card ────────────────────────────────────────────
  Widget _buildMenuCard(BuildContext context, int index) {
    final item = _menuItems[index];
    return GestureDetector(
      onTap: () => _navigate(context, index),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade100, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: item['bgColor'] as Color,
                shape: BoxShape.circle,
              ),
              child: Icon(
                item['icon'] as IconData,
                size: 26,
                color: item['color'] as Color,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              item['title'] as String,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B4332),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              item['subtitle'] as String,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 8.5, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Notifications Bottom Sheet ───────────────────────────
  void _showNotificationsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Consumer<BlockProvider>(
          builder: (context, blockProvider, _) {
            final list = blockProvider.notifications;
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Row(
                  children: [
                    Icon(
                      Icons.notifications_rounded,
                      color: Color(0xFF1B4332),
                      size: 24,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Notifikasi Saya',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B4332),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (list.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_none_rounded,
                          color: Colors.grey.shade300,
                          size: 48,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Tidak ada notifikasi saat ini',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ...list.map(
                    (n) => Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade100),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: (n['color'] as Color).withOpacity(
                            0.12,
                          ),
                          child: Icon(
                            n['icon'] as IconData,
                            color: n['color'] as Color,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          n['message'] as String,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1B4332),
                          ),
                        ),
                        trailing: Text(
                          n['time'] as String,
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ─── Logout Dialog ────────────────────────────────────────
  void _confirmLogout(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: Colors.redAccent, size: 24),
            SizedBox(width: 8),
            Text(
              'Keluar Akun',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B4332),
              ),
            ),
          ],
        ),
        content: const Text(
          'Apakah Anda yakin ingin keluar dari aplikasi Tiramku?',
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Batal',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B4332),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              Navigator.pop(context);
              await auth.logout();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => LoginScreen()),
                (route) => false,
              );
            },
            child: const Text(
              'Keluar',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
