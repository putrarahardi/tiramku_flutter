import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';
import 'consultation_screen.dart';
import 'catalog_screen.dart';
import 'history_screen.dart';
import 'education_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<double>> _cardAnimations;

  // === DUMMY DATA: Ganti dengan data dari provider/API nyata ===
  final Map<String, dynamic> _farmStats = {
    'activeBaglogs': 120,
    'harvestReady': 35,
    'totalHarvest': '48 kg',
    'weather': 'Cerah',
    'humidity': '72%',
    'temperature': '27°C',
  };

  final List<Map<String, dynamic>> _notifications = [
    {
      'icon': Icons.water_drop,
      'color': Colors.blue,
      'message': 'Waktunya penyiraman baglog blok A',
      'time': '08:00',
    },
    {
      'icon': Icons.eco,
      'color': Colors.green,
      'message': '35 baglog siap panen hari ini',
      'time': '07:30',
    },
    {
      'icon': Icons.warning_amber,
      'color': Colors.orange,
      'message': 'Kelembaban blok B di bawah optimal',
      'time': '06:15',
    },
  ];
  // ============================================================

  final List<Map<String, dynamic>> _menuItems = [
    {
      'title': 'Katalog Baglog',
      'subtitle': 'Jelajahi produk',
      'icon': Icons.shopping_bag_rounded,
      'color': Color(0xFFFF8C42),
      'bgColor': Color(0xFFFFF3E9),
    },
    {
      'title': 'Konsultasi',
      'subtitle': 'Rule-based expert',
      'icon': Icons.psychology_rounded,
      'color': Color(0xFF4A90D9),
      'bgColor': Color(0xFFE8F2FC),
    },
    {
      'title': 'Edukasi Tanam',
      'subtitle': 'Panduan & tips',
      'icon': Icons.menu_book_rounded,
      'color': Color(0xFF2ECC8E),
      'bgColor': Color(0xFFE5F9F2),
    },
    {
      'title': 'Riwayat',
      'subtitle': 'Transaksi & log',
      'icon': Icons.history_rounded,
      'color': Color(0xFF8B7EC8),
      'bgColor': Color(0xFFF0EEF9),
    },
    {
      'title': 'Monitor Blok',
      'subtitle': 'Status kumbung',
      'icon': Icons.sensor_window_rounded,
      'color': Color(0xFFE04F6A),
      'bgColor': Color(0xFFFCECEF),
    },
    {
      'title': 'Laporan',
      'subtitle': 'Ringkasan hasil',
      'icon': Icons.bar_chart_rounded,
      'color': Color(0xFF3ABCB7),
      'bgColor': Color(0xFFE5F7F7),
    },
  ];

  @override
  void initState() {
    super.initState();
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
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _navigate(BuildContext context, int index) {
    final routes = [
      CatalogScreen(),
      ConsultationScreen(),
      EducationScreen(), // Edukasi (aktif)
      HistoryScreen(),
      null, // Monitor Blok (belum ada)
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
          // === HEADER ===
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: const Color(0xFF1B4332),
            flexibleSpace: FlexibleSpaceBar(
              background: _buildHeader(greeting, userName),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_rounded, color: Colors.white),
                onPressed: () => _showNotificationsSheet(context),
              ),
              IconButton(
                icon: const Icon(Icons.logout_rounded, color: Colors.white),
                onPressed: () => _confirmLogout(context, auth),
              ),
            ],
          ),

          // === STATS CARDS ===
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: _buildStatsRow(),
            ),
          ),

          // === CUACA ===
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: _buildWeatherCard(),
            ),
          ),

          // === MENU TITLE ===
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Text(
                'Menu Utama',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1B4332),
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),

          // === GRID MENU ===
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
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
        ],
      ),
    );
  }

  // ─── Header ───────────────────────────────────────────────
  Widget _buildHeader(String greeting, String userName) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1B4332), Color(0xFF2D6A4F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.white24,
                child: Text(
                  userName.isNotEmpty ? userName[0].toUpperCase() : 'P',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      greeting,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        letterSpacing: 0.3,
                      ),
                    ),
                    Text(
                      userName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.eco, color: Colors.greenAccent, size: 14),
                    SizedBox(width: 4),
                    Text('Tiramku', style: TextStyle(color: Colors.white, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Stats Row ────────────────────────────────────────────
  Widget _buildStatsRow() {
    final stats = [
      {
        'label': 'Baglog Aktif',
        'value': '${_farmStats['activeBaglogs']}',
        'icon': Icons.grid_view_rounded,
        'color': const Color(0xFF2D6A4F),
      },
      {
        'label': 'Siap Panen',
        'value': '${_farmStats['harvestReady']}',
        'icon': Icons.agriculture_rounded,
        'color': const Color(0xFFFF8C42),
      },
      {
        'label': 'Total Panen',
        'value': '${_farmStats['totalHarvest']}',
        'icon': Icons.scale_rounded,
        'color': const Color(0xFF4A90D9),
      },
    ];

    return Row(
      children: stats.map((s) {
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(
              right: stats.indexOf(s) < stats.length - 1 ? 10 : 0,
            ),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(s['icon'] as IconData, color: s['color'] as Color, size: 22),
                const SizedBox(height: 8),
                Text(
                  s['value'] as String,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: s['color'] as Color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  s['label'] as String,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ─── Weather Card ─────────────────────────────────────────
  Widget _buildWeatherCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4A90D9), Color(0xFF74B3E8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4A90D9).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.wb_sunny_rounded, color: Colors.white, size: 40),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_farmStats['weather']} · ${_farmStats['temperature']}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'Kelembaban: ${_farmStats['humidity']}',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'Kondisi\nOptimal',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
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
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
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
                size: 28,
                color: item['color'] as Color,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              item['title'] as String,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              item['subtitle'] as String,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10, color: Colors.grey),
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
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Notifikasi',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ..._notifications.map(
              (n) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: (n['color'] as Color).withOpacity(0.15),
                  child: Icon(n['icon'] as IconData, color: n['color'] as Color, size: 20),
                ),
                title: Text(n['message'] as String, style: const TextStyle(fontSize: 13)),
                trailing: Text(
                  n['time'] as String,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  // ─── Logout Dialog ────────────────────────────────────────
  void _confirmLogout(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Keluar Akun'),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B4332),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(context);
              await auth.logout();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => LoginScreen()),
              );
            },
            child: const Text('Keluar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}