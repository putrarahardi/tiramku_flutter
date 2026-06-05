import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ConsultationScreen extends StatefulWidget {
  const ConsultationScreen({Key? key}) : super(key: key);

  @override
  State<ConsultationScreen> createState() => _ConsultationScreenState();
}

class _ConsultationScreenState extends State<ConsultationScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  final _tempController = TextEditingController();
  final _humidController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String _location = 'tertutup';
  String _lighting = 'redup';
  bool _isLoading = false;
  String? _recommendation;

  late AnimationController _resultController;
  late Animation<double> _resultFade;
  late Animation<Offset> _resultSlide;

  @override
  void initState() {
    super.initState();
    _resultController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _resultFade = CurvedAnimation(parent: _resultController, curve: Curves.easeOut);
    _resultSlide = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(CurvedAnimation(parent: _resultController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _tempController.dispose();
    _humidController.dispose();
    _resultController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _recommendation = null;
    });
    _resultController.reset();

    try {
      final response = await _apiService.post('consultation', {
        'temperature': _tempController.text,
        'humidity': _humidController.text,
        'location': _location,
        'lighting': _lighting,
      });

      if (response.statusCode == 200) {
        setState(() {
          _recommendation =
              response.data['data']['recommendation']['recommendation_text'];
        });
        _resultController.forward();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 8),
              Text('Gagal melakukan konsultasi'),
            ],
          ),
          backgroundColor: const Color(0xFFE04F6A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B4332),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Konsultasi Perawatan',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildInfoBanner(),
              const SizedBox(height: 24),
              _buildSectionLabel('Parameter Lingkungan'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildTempField()),
                  const SizedBox(width: 12),
                  Expanded(child: _buildHumidField()),
                ],
              ),
              const SizedBox(height: 24),
              _buildSectionLabel('Kondisi Penempatan'),
              const SizedBox(height: 12),
              _buildLocationSelector(),
              const SizedBox(height: 24),
              _buildSectionLabel('Pencahayaan'),
              const SizedBox(height: 12),
              _buildLightingSelector(),
              const SizedBox(height: 32),
              _buildSubmitButton(),
              const SizedBox(height: 28),
              if (_recommendation != null)
                SlideTransition(
                  position: _resultSlide,
                  child: FadeTransition(
                    opacity: _resultFade,
                    child: _buildResultCard(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Info Banner (Redesigned Hero Welcome Card) ───────────
  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1B4332),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B4332).withOpacity(0.12),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -24,
            bottom: -24,
            child: Opacity(
              opacity: 0.08,
              child: const Icon(
                Icons.psychology_rounded,
                size: 110,
                color: Colors.white,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.spa_rounded, color: Colors.amber, size: 13),
                    SizedBox(width: 4),
                    Text(
                      'Diagnosis Cerdas',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Analisis Perawatan Jamur',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Masukkan kondisi fisik kumbung Anda di bawah ini untuk memperoleh panduan perawatan jamur tiram yang paling presisi secara instan.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Section Label ────────────────────────────────────────
  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1B4332),
        letterSpacing: 0.3,
      ),
    );
  }

  // ─── Input Fields Decoration ──────────────────────────────
  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 13, color: Colors.grey),
      floatingLabelStyle: const TextStyle(
        color: Color(0xFF2ECC8E),
        fontWeight: FontWeight.bold,
      ),
      prefixIcon: Container(
        margin: const EdgeInsets.only(right: 8, left: 6),
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(
          color: Color(0xFFE5F9F2),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: const Color(0xFF2D6A4F), size: 18),
      ),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF2ECC8E), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 16),
    );
  }

  Widget _buildTempField() {
    return TextFormField(
      controller: _tempController,
      decoration: _inputDecoration('Suhu (°C)', Icons.thermostat_rounded),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Wajib diisi';
        final n = double.tryParse(v);
        if (n == null) return 'Angka valid';
        if (n < 0 || n > 50) return '0–50°C';
        return null;
      },
    );
  }

  Widget _buildHumidField() {
    return TextFormField(
      controller: _humidController,
      decoration: _inputDecoration('Kelembapan (%)', Icons.water_drop_rounded),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Wajib diisi';
        final n = double.tryParse(v);
        if (n == null) return 'Angka valid';
        if (n < 0 || n > 100) return '0–100%';
        return null;
      },
    );
  }

  // ─── Location Selector (Beautified) ───────────────────────
  Widget _buildLocationSelector() {
    final options = [
      {'value': 'tertutup', 'label': 'Tertutup', 'icon': Icons.home_rounded},
      {'value': 'terbuka', 'label': 'Terbuka', 'icon': Icons.nature_rounded},
    ];

    return Row(
      children: options.map((opt) {
        final selected = _location == opt['value'];
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _location = opt['value'] as String),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              margin: EdgeInsets.only(
                right: opt == options.first ? 12 : 0,
              ),
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                color: selected ? const Color(0xFF1B4332) : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: selected ? Colors.transparent : Colors.grey.shade200,
                  width: 1.5,
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: const Color(0xFF1B4332).withOpacity(0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: Column(
                children: [
                  Icon(
                     opt['icon'] as IconData,
                     color: selected ? Colors.white : Colors.grey.shade400,
                     size: 26,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    opt['label'] as String,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: selected ? Colors.white : Colors.grey.shade600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ─── Lighting Selector (Beautified & Glowing) ─────────────
  Widget _buildLightingSelector() {
    final options = [
      {
        'value': 'gelap',
        'label': 'Gelap',
        'icon': Icons.nights_stay_rounded,
        'color': const Color(0xFF2B2B4D),
        'shadowColor': const Color(0xFF2B2B4D),
      },
      {
        'value': 'redup',
        'label': 'Redup',
        'icon': Icons.wb_twilight_rounded,
        'color': const Color(0xFFE07B39),
        'shadowColor': const Color(0xFFE07B39),
      },
      {
        'value': 'terang',
        'label': 'Terang',
        'icon': Icons.wb_sunny_rounded,
        'color': const Color(0xFFF5C842),
        'shadowColor': const Color(0xFFF5C842),
      },
    ];

    return Row(
      children: options.asMap().entries.map((entry) {
        final i = entry.key;
        final opt = entry.value;
        final selected = _lighting == opt['value'];
        final solidColor = opt['color'] as Color;
        final shadowColor = opt['shadowColor'] as Color;

        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _lighting = opt['value'] as String),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              margin: EdgeInsets.only(right: i < options.length - 1 ? 10 : 0),
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                color: selected ? solidColor : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: selected ? Colors.transparent : Colors.grey.shade200,
                  width: 1.5,
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: shadowColor.withOpacity(0.25),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: Column(
                children: [
                  Icon(
                    opt['icon'] as IconData,
                    color: selected ? Colors.white : Colors.grey.shade400,
                    size: 24,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    opt['label'] as String,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: selected ? Colors.white : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ─── Submit Button (Full-Width Gradient Capsule) ─────────
  Widget _buildSubmitButton() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: _isLoading
          ? Container(
              height: 54,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF2D6A4F),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                ),
              ),
            )
          : Container(
              width: double.infinity,
              height: 54,
              decoration: BoxDecoration(
                color: const Color(0xFF1B4332),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1B4332).withOpacity(0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                onPressed: _submit,
                icon: const Icon(Icons.psychology_rounded, color: Colors.white, size: 22),
                label: const Text(
                  'Dapatkan Rekomendasi',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
    );
  }

  // ─── Result Card (Refurbished Report Design) ──────────────
  Widget _buildResultCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: const Color(0xFF2D6A4F).withOpacity(0.15), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: const BoxDecoration(
              color: Color(0xFF1B4332),
              borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 18),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Hasil Rekomendasi',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          // Body
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _recommendation!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF2D3748),
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 20),
                const Divider(height: 1),
              ],
            ),
          ),
          // Footer Action
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF2D6A4F),
                side: const BorderSide(color: Color(0xFF2D6A4F), width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Rekomendasi berhasil disimpan ke riwayat!'),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    backgroundColor: const Color(0xFF1B4332),
                  ),
                );
              },
              icon: const Icon(Icons.bookmark_add_outlined, size: 20),
              label: const Text(
                'Simpan Rekomendasi',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}