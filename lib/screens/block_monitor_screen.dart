import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/block_provider.dart';

class BlockMonitorScreen extends StatelessWidget {
  const BlockMonitorScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Consumer<BlockProvider>(
        builder: (context, provider, _) {
          final blocks = provider.blocks;
          
          final totalBlocks = blocks.length;
          final warningBlocks = blocks.where((b) => b.status == 'Peringatan').length;
          final criticalBlocks = blocks.where((b) => b.status == 'Kritis').length;
          final optimalBlocks = blocks.where((b) => b.status == 'Optimal').length;

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // === PREMIUM HEADER PANEL ===
              SliverToBoxAdapter(
                child: Container(
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
                      padding: const EdgeInsets.only(top: 14, bottom: 24, left: 20, right: 20),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Positioned(
                            left: 0,
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => Navigator.of(context).pop(),
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
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Text(
                                'Monitor Blok Kumbung',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Pantau & kendalikan sensor IoT secara langsung',
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
              ),

              // === GENERAL SUMMARY CARDS ===
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  child: Row(
                    children: [
                      _buildSummaryCard(
                        'Optimal',
                        '$optimalBlocks/$totalBlocks',
                        Icons.check_circle_rounded,
                        const Color(0xFF2ECC8E),
                        const Color(0xFFE5F9F2),
                      ),
                      const SizedBox(width: 10),
                      _buildSummaryCard(
                        'Peringatan',
                        '$warningBlocks',
                        Icons.warning_amber_rounded,
                        const Color(0xFFFF8C42),
                        const Color(0xFFFFF3E9),
                      ),
                      const SizedBox(width: 10),
                      _buildSummaryCard(
                        'Kritis',
                        '$criticalBlocks',
                        Icons.error_outline_rounded,
                        const Color(0xFFE04F6A),
                        const Color(0xFFFCECEF),
                      ),
                    ],
                  ),
                ),
              ),

              // === BLOCKS LIST ===
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final block = blocks[index];
                      return _buildBlockCard(context, provider, block);
                    },
                    childCount: blocks.length,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(
      String label, String value, IconData icon, Color color, Color bgColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.015),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlockCard(BuildContext context, BlockProvider provider, FarmBlock block) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        block.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1B4332),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Total Baglog: ${block.activeBaglogs} pcs · Siap Panen: ${block.harvestReady} pcs',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: block.statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    block.status,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      color: block.statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Divider(height: 1, color: Color(0xFFF1F3F5)),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: Row(
              children: [
                _buildSensorMetric(
                  'Suhu',
                  '${block.temperature.toStringAsFixed(1)}°C',
                  Icons.thermostat_rounded,
                  block.temperature > 30 ? const Color(0xFFFF8C42) : const Color(0xFF2ECC8E),
                ),
                _buildSensorDivider(),
                _buildSensorMetric(
                  'Kelembaban',
                  '${block.humidity.toStringAsFixed(1)}%',
                  Icons.water_drop_rounded,
                  block.humidity < 80 ? const Color(0xFFFF8C42) : const Color(0xFF4A90D9),
                ),
                _buildSensorDivider(),
                _buildSensorMetric(
                  'Kadar Air',
                  '${block.moisture.toStringAsFixed(1)}%',
                  Icons.grass_rounded,
                  const Color(0xFF3ABCB7),
                ),
              ],
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Divider(height: 1, color: Color(0xFFF1F3F5)),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: _buildControlToggle(
                    'Penyiram Kabut',
                    block.sprayerOn,
                    Icons.water_drop_rounded,
                    const Color(0xFF4A90D9),
                    () => provider.toggleSprayer(block.id),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildControlToggle(
                    'Kipas Ventilasi',
                    block.fanOn,
                    Icons.wind_power_rounded,
                    const Color(0xFF3ABCB7),
                    () => provider.toggleFan(block.id),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSensorMetric(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B4332),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSensorDivider() {
    return Container(
      height: 30,
      width: 1.5,
      color: Colors.grey.shade100,
    );
  }

  Widget _buildControlToggle(
      String label, bool isOn, IconData icon, Color activeColor, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: isOn ? activeColor.withOpacity(0.08) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOn ? activeColor.withOpacity(0.24) : Colors.grey.shade200,
          width: 1.5,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isOn ? activeColor : Colors.grey.shade400,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isOn ? activeColor : Colors.grey.shade600,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: isOn ? activeColor : Colors.transparent,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
