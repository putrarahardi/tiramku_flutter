import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ConsultationScreen extends StatefulWidget {
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
          backgroundColor: Colors.red.shade700,
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
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
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
              const SizedBox(height: 20),
              _buildSectionLabel('Kondisi Penempatan'),
              const SizedBox(height: 12),
              _buildLocationSelector(),
              const SizedBox(height: 20),
              _buildSectionLabel('Pencahayaan'),
              const SizedBox(height: 12),
              _buildLightingSelector(),
              const SizedBox(height: 28),
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

  // ─── Info Banner ──────────────────────────────────────────
  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5EE),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2D6A4F).withOpacity(0.3)),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline_rounded, color: Color(0xFF2D6A4F), size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Isi kondisi lingkungan kumbung Anda untuk mendapatkan rekomendasi perawatan jamur tiram.',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF1B4332),
                height: 1.4,
              ),
            ),
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
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: Color(0xFF555E6A),
        letterSpacing: 0.5,
      ),
    );
  }

  // ─── Input Fields ─────────────────────────────────────────
  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFF2D6A4F), size: 20),
      filled: true,
      fillColor: Colors.white,
      labelStyle: const TextStyle(fontSize: 13, color: Colors.grey),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2D6A4F), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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

  // ─── Location Selector (chip-style) ───────────────────────
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
              duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.only(
                right: opt == options.first ? 12 : 0,
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: selected ? const Color(0xFF1B4332) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected ? const Color(0xFF1B4332) : Colors.grey.shade200,
                ),
                boxShadow: selected
                    ? [BoxShadow(color: const Color(0xFF1B4332).withOpacity(0.25), blurRadius: 8, offset: const Offset(0, 3))]
                    : [],
              ),
              child: Column(
                children: [
                  Icon(
                    opt['icon'] as IconData,
                    color: selected ? Colors.white : Colors.grey,
                    size: 24,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    opt['label'] as String,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
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

  // ─── Lighting Selector (chip-style) ───────────────────────
  Widget _buildLightingSelector() {
    final options = [
      {'value': 'gelap', 'label': 'Gelap', 'icon': Icons.nights_stay_rounded, 'color': const Color(0xFF3A3A5C)},
      {'value': 'redup', 'label': 'Redup', 'icon': Icons.wb_twilight_rounded, 'color': const Color(0xFFE07B39)},
      {'value': 'terang', 'label': 'Terang', 'icon': Icons.wb_sunny_rounded, 'color': const Color(0xFFF5C842)},
    ];

    return Row(
      children: options.asMap().entries.map((entry) {
        final i = entry.key;
        final opt = entry.value;
        final selected = _lighting == opt['value'];
        final color = opt['color'] as Color;

        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _lighting = opt['value'] as String),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.only(right: i < options.length - 1 ? 10 : 0),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: selected ? color : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected ? color : Colors.grey.shade200,
                ),
                boxShadow: selected
                    ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))]
                    : [],
              ),
              child: Column(
                children: [
                  Icon(
                    opt['icon'] as IconData,
                    color: selected ? Colors.white : Colors.grey,
                    size: 22,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    opt['label'] as String,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
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

  // ─── Submit Button ────────────────────────────────────────
  Widget _buildSubmitButton() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: _isLoading
          ? Container(
              height: 54,
              decoration: BoxDecoration(
                color: const Color(0xFF2D6A4F),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                ),
              ),
            )
          : ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B4332),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 2,
                shadowColor: const Color(0xFF1B4332).withOpacity(0.4),
              ),
              onPressed: _submit,
              icon: const Icon(Icons.search_rounded, size: 20),
              label: const Text(
                'Dapatkan Rekomendasi',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
    );
  }

  // ─── Result Card ──────────────────────────────────────────
  Widget _buildResultCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2D6A4F).withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2D6A4F).withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF1B4332),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: const Row(
              children: [
                Icon(Icons.eco_rounded, color: Colors.greenAccent, size: 20),
                SizedBox(width: 8),
                Text(
                  'Hasil Rekomendasi',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          // Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              _recommendation!,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF1A1A2E),
                height: 1.6,
              ),
            ),
          ),
          // Footer
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF2D6A4F),
                side: const BorderSide(color: Color(0xFF2D6A4F)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                // TODO: simpan ke riwayat konsultasi
              },
              icon: const Icon(Icons.bookmark_add_outlined, size: 18),
              label: const Text('Simpan Rekomendasi', style: TextStyle(fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }
}