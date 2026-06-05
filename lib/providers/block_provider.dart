import 'dart:async';
import 'package:flutter/material.dart';

class FarmBlock {
  final String id;
  final String name;
  final int activeBaglogs;
  final int harvestReady;
  double temperature;
  double humidity;
  double moisture;
  bool sprayerOn;
  bool fanOn;

  FarmBlock({
    required this.id,
    required this.name,
    required this.activeBaglogs,
    required this.harvestReady,
    required this.temperature,
    required this.humidity,
    required this.moisture,
    this.sprayerOn = false,
    this.fanOn = false,
  });

  String get status {
    if (humidity < 70 || temperature > 34) return 'Kritis';
    if (humidity < 80 || temperature > 30) return 'Peringatan';
    return 'Optimal';
  }

  Color get statusColor {
    final s = status;
    if (s == 'Kritis') return const Color(0xFFE04F6A);
    if (s == 'Peringatan') return const Color(0xFFFF8C42);
    return const Color(0xFF2ECC8E);
  }
}

class BlockProvider extends ChangeNotifier {
  final List<FarmBlock> _blocks = [
    FarmBlock(
      id: 'block_a',
      name: 'Blok A (Inokulasi)',
      activeBaglogs: 150,
      harvestReady: 0,
      temperature: 27.2,
      humidity: 86.0,
      moisture: 65.0,
    ),
    FarmBlock(
      id: 'block_b',
      name: 'Blok B (Inkubasi)',
      activeBaglogs: 120,
      harvestReady: 15,
      temperature: 29.8,
      humidity: 78.0, // Memperlihatkan warning awal
      moisture: 58.0,
    ),
    FarmBlock(
      id: 'block_c',
      name: 'Blok C (Produksi)',
      activeBaglogs: 200,
      harvestReady: 32,
      temperature: 25.5,
      humidity: 88.0,
      moisture: 72.0,
    ),
  ];

  final List<Map<String, dynamic>> _notifications = [];
  Timer? _simulationTimer;

  List<FarmBlock> get blocks => _blocks;
  List<Map<String, dynamic>> get notifications => _notifications;

  BlockProvider() {
    _generateInitialNotifications();
    _startSimulation();
  }

  void _generateInitialNotifications() {
    _notifications.add({
      'id': 'init_1',
      'icon': Icons.eco_rounded,
      'color': const Color(0xFF2ECC8E),
      'message': '35 baglog siap panen hari ini',
      'time': '07:30',
    });
    _notifications.add({
      'id': 'init_2',
      'icon': Icons.warning_amber_rounded,
      'color': const Color(0xFFFF8C42),
      'message': 'Kelembaban Blok B (Inkubasi) di bawah optimal (78%)',
      'time': '06:15',
    });
  }

  void _startSimulation() {
    _simulationTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      bool changed = false;
      for (var block in _blocks) {
        if (block.sprayerOn) {
          if (block.humidity < 95.0) {
            block.humidity += 1.5;
            block.moisture += 0.8;
            changed = true;
          }
          if (block.temperature > 24.0) {
            block.temperature -= 0.2;
            changed = true;
          }
        } else {
          if (block.humidity > 70.0) {
            block.humidity -= 0.4;
            changed = true;
            // Picu notifikasi baru jika kelembaban turun di bawah 75% secara periodik
            if (block.humidity <= 75.0 && block.humidity + 0.4 > 75.0) {
              _addNotification(
                Icons.warning_amber_rounded,
                const Color(0xFFFF8C42),
                'Peringatan: Kelembaban ${block.name} menurun (${block.humidity.toStringAsFixed(1)}%)!',
              );
            }
          }
          if (block.temperature < 32.0) {
            block.temperature += 0.1;
            changed = true;
          }
        }

        if (block.fanOn) {
          if (block.temperature > 24.0) {
            block.temperature -= 0.1;
            changed = true;
          }
        }
      }
      if (changed) {
        notifyListeners();
      }
    });
  }

  void _addNotification(IconData icon, Color color, String message) {
    final now = DateTime.now();
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    _notifications.insert(0, {
      'id': 'noti_${now.millisecondsSinceEpoch}',
      'icon': icon,
      'color': color,
      'message': message,
      'time': timeStr,
    });
    if (_notifications.length > 25) {
      _notifications.removeLast();
    }
    notifyListeners();
  }

  void toggleSprayer(String blockId) {
    final idx = _blocks.indexWhere((b) => b.id == blockId);
    if (idx != -1) {
      final block = _blocks[idx];
      block.sprayerOn = !block.sprayerOn;
      
      if (block.sprayerOn) {
        _addNotification(
          Icons.water_drop_rounded,
          const Color(0xFF4A90D9),
          'Penyiram otomatis diaktifkan di ${block.name}',
        );
      } else {
        _addNotification(
          Icons.water_drop_outlined,
          Colors.grey,
          'Penyiram otomatis dimatikan di ${block.name}',
        );
      }
      notifyListeners();
    }
  }

  void toggleFan(String blockId) {
    final idx = _blocks.indexWhere((b) => b.id == blockId);
    if (idx != -1) {
      final block = _blocks[idx];
      block.fanOn = !block.fanOn;
      
      if (block.fanOn) {
        _addNotification(
          Icons.wind_power_rounded,
          const Color(0xFF3ABCB7),
          'Kipas ventilasi diaktifkan di ${block.name}',
        );
      } else {
        _addNotification(
          Icons.mode_fan_off_rounded,
          Colors.grey,
          'Kipas ventilasi dimatikan di ${block.name}',
        );
      }
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _simulationTimer?.cancel();
    super.dispose();
  }
}
