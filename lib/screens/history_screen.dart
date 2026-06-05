import 'dart:io';
import 'package:flutter/material.dart';
import 'main_screen.dart';
import '../services/api_service.dart';
import '../services/utils.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _transactions = [];
  bool _isLoading = true;
  String _selectedStatusFilter = 'Semua';

  final List<String> _filters = [
    'Semua',
    'Belum Bayar',
    'Verifikasi',
    'Selesai',
    'Dibatalkan',
  ];

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
  }

  Future<void> _fetchTransactions() async {
    try {
      final response = await _apiService.get('transactions');
      if (response.statusCode == 200) {
        setState(() {
          _transactions = response.data['data'];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Gagal memuat riwayat transaksi'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  String _formatImageUrl(String? url) {
    if (url == null || url.trim().isEmpty) return '';
    String formatted = url.trim();
    if (!formatted.startsWith('http://') && !formatted.startsWith('https://')) {
      formatted = 'http://10.0.2.2:8000/storage/$formatted';
    }
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

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
        'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'
      ];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}, ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateStr;
    }
  }

  Map<String, dynamic> _getStatusConfig(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return {
          'label': 'Selesai',
          'bgColor': const Color(0xFFE5F9F2),
          'textColor': const Color(0xFF2ECC8E),
          'icon': Icons.check_circle_rounded,
        };
      case 'waiting_verification':
        return {
          'label': 'Verifikasi',
          'bgColor': const Color(0xFFFFF3E9),
          'textColor': const Color(0xFFFF8C42),
          'icon': Icons.pending_actions_rounded,
        };
      case 'pending':
        return {
          'label': 'Belum Bayar',
          'bgColor': const Color(0xFFE8F2FC),
          'textColor': const Color(0xFF4A90D9),
          'icon': Icons.payment_rounded,
        };
      case 'cancelled':
        return {
          'label': 'Dibatalkan',
          'bgColor': const Color(0xFFFCECEF),
          'textColor': const Color(0xFFE04F6A),
          'icon': Icons.cancel_rounded,
        };
      default:
        return {
          'label': status.toUpperCase(),
          'bgColor': Colors.grey.shade100,
          'textColor': Colors.grey.shade700,
          'icon': Icons.help_outline_rounded,
        };
    }
  }

  void _showTransactionDetails(BuildContext context, Map<String, dynamic> trx) {
    final statusConfig = _getStatusConfig(trx['status'] ?? 'pending');
    final details = trx['details'] as List<dynamic>? ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          builder: (_, controller) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  // Grab Handle
                  const SizedBox(height: 12),
                  Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),
                  const SizedBox(height: 18),
                  
                  // Invoice Header Block
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Struk Belanja #${trx['id']}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1B4332),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: statusConfig['bgColor'] as Color,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    statusConfig['icon'] as IconData,
                                    color: statusConfig['textColor'] as Color,
                                    size: 13,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    statusConfig['label'] as String,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                      color: statusConfig['textColor'] as Color,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(trx['created_at']),
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Dashed separator decoration
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: List.generate(
                        30,
                        (index) => Expanded(
                          child: Container(
                            height: 1.5,
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            color: Colors.grey.shade300,
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  // Items scrollable breakdown
                  Expanded(
                    child: ListView.builder(
                      controller: controller,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      itemCount: details.length,
                      itemBuilder: (context, idx) {
                        final item = details[idx];
                        final prod = item['product'] ?? {};
                        final imageUrl = _formatImageUrl(prod['image']);
                        
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: imageUrl.isNotEmpty
                                    ? Image.network(
                                        imageUrl,
                                        width: 50,
                                        height: 50,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => _buildItemPlaceholder(),
                                      )
                                    : _buildItemPlaceholder(),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      prod['name'] ?? 'Baglog Jamur',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: Color(0xFF1B4332),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${item['quantity']} pcs x Rp ${formatNumber(item['price'])}',
                                      style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                'Rp ${formatNumber(item['price'] * item['quantity'])}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Color(0xFF1B4332),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  
                  // Dotted bottom line
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: List.generate(
                        30,
                        (index) => Expanded(
                          child: Container(
                            height: 1.5,
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            color: Colors.grey.shade300,
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  // Total price panel & payment actions
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total Belanjaan',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1B4332),
                              ),
                            ),
                            Text(
                              'Rp ${formatNumber(trx['total_price'])}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                          ],
                        ),
                        if (trx['status'] == 'pending') ...[
                          const SizedBox(height: 20),
                          Container(
                            width: double.infinity,
                            height: 50,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1B4332),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF1B4332).withOpacity(0.2),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              onPressed: () {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('Silakan hubungi admin atau transfer untuk menyelesaikan pembayaran'),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    backgroundColor: const Color(0xFF1B4332),
                                  ),
                                );
                              },
                              child: const Text(
                                'Selesaikan Pembayaran',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildItemPlaceholder() {
    return Container(
      width: 50,
      height: 50,
      color: const Color(0xFF1B4332).withOpacity(0.08),
      child: const Icon(Icons.eco_rounded, color: Color(0xFF2ECC8E)),
    );
  }

  @override
  Widget build(BuildContext context) {
    // In-memory local filtering of transactions
    final filteredTrx = _transactions.where((t) {
      final status = t['status']?.toString().toLowerCase() ?? '';
      if (_selectedStatusFilter == 'Semua') return true;
      if (_selectedStatusFilter == 'Belum Bayar') return status == 'pending';
      if (_selectedStatusFilter == 'Verifikasi') return status == 'waiting_verification';
      if (_selectedStatusFilter == 'Selesai') return status == 'completed';
      if (_selectedStatusFilter == 'Dibatalkan') return status == 'cancelled';
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          // === HEADER PANEL ===
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFF1B4332),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(top: 14, bottom: 20),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Tombol Kembali ke Beranda
                    Positioned(
                      left: 16,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            final mainScreenState = context.findAncestorStateOfType<MainScreenState>();
                            if (mainScreenState != null) {
                              mainScreenState.switchTab(0); // Kembali ke Beranda (Index 0)
                            } else if (Navigator.of(context).canPop()) {
                              Navigator.of(context).pop();
                            }
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    // Judul di Tengah
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text(
                          'Riwayat Transaksi',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Kelola & pantau status pesanan baglog Anda',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // === HORIZONTAL STATUS FILTER CHIPS ===
          const SizedBox(height: 16),
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filters.length,
              itemBuilder: (context, idx) {
                final f = _filters[idx];
                final isSelected = _selectedStatusFilter == f;
                
                // Color customization for pastel badges based on filter text
                Color activeColor = const Color(0xFF1B4332);
                Color activeBg = const Color(0xFFE5F9F2);
                if (f == 'Belum Bayar') {
                  activeColor = const Color(0xFF4A90D9);
                  activeBg = const Color(0xFFE8F2FC);
                } else if (f == 'Verifikasi') {
                  activeColor = const Color(0xFFFF8C42);
                  activeBg = const Color(0xFFFFF3E9);
                } else if (f == 'Dibatalkan') {
                  activeColor = const Color(0xFFE04F6A);
                  activeBg = const Color(0xFFFCECEF);
                }

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(
                      f,
                      style: TextStyle(
                        color: isSelected ? activeColor : Colors.grey.shade600,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedStatusFilter = f;
                        });
                      }
                    },
                    selectedColor: activeBg,
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: isSelected ? activeColor.withOpacity(0.3) : Colors.grey.shade200,
                      width: 1.2,
                    ),
                    elevation: 0,
                    pressElevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          // === TRANSACTION LEDGER LIST ===
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: const Color(0xFF1B4332),
                      strokeWidth: 3,
                    ),
                  )
                : filteredTrx.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.receipt_long_rounded, size: 64, color: Colors.grey.shade300),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Tidak ada pesanan ditemukan',
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.grey.shade500,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Coba ubah filter transaksi Anda',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade400,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                        itemCount: filteredTrx.length,
                        itemBuilder: (context, index) {
                          final trx = filteredTrx[index];
                          final details = trx['details'] as List<dynamic>? ?? [];
                          final hasItems = details.isNotEmpty;
                          final firstItem = hasItems ? details[0] : null;
                          final prod = firstItem != null ? firstItem['product'] : null;
                          final productName = prod != null ? prod['name'] : 'Pesanan #${trx['id']}';
                          final productImg = prod != null ? prod['image'] : null;
                          final productImgUrl = _formatImageUrl(productImg);
                          
                          final totalQty = details.fold<int>(0, (sum, item) => sum + (item['quantity'] as int));
                          final statusConfig = _getStatusConfig(trx['status'] ?? 'pending');

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
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
                            child: InkWell(
                              onTap: () => _showTransactionDetails(context, trx),
                              borderRadius: BorderRadius.circular(20),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Header: Calendar Date and Status Badge
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(Icons.calendar_today_rounded, size: 13, color: Colors.grey.shade400),
                                            const SizedBox(width: 6),
                                            Text(
                                              _formatDate(trx['created_at']),
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey.shade500,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: statusConfig['bgColor'] as Color,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            statusConfig['label'] as String,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 10,
                                              color: statusConfig['textColor'] as Color,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    
                                    const SizedBox(height: 12),
                                    const Divider(height: 1, color: Color(0xFFF1F3F5)),
                                    const SizedBox(height: 12),
                                    
                                    // Row: Image thumbnail, name, total belanja
                                    Row(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: productImgUrl.isNotEmpty
                                              ? Image.network(
                                                  productImgUrl,
                                                  width: 48,
                                                  height: 48,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (_, __, ___) => _buildThumbPlaceholder(),
                                                )
                                              : _buildThumbPlaceholder(),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                productName,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                  color: Color(0xFF1B4332),
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                details.length > 1
                                                    ? '$totalQty produk (${details.length} item)'
                                                    : '$totalQty produk',
                                                style: TextStyle(
                                                  color: Colors.grey.shade500,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              'Total Belanja',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.grey.shade400,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              'Rp ${formatNumber(trx['total_price'])}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                                color: Color(0xFF1B4332),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildThumbPlaceholder() {
    return Container(
      width: 48,
      height: 48,
      color: const Color(0xFF1B4332).withOpacity(0.08),
      child: const Icon(Icons.eco_rounded, color: Color(0xFF1B4332), size: 20),
    );
  }
}
