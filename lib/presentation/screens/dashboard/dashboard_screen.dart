import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/sensor_reading.dart';
import '../../../data/models/device_status.dart';
import '../../../data/models/face_model.dart';
import '../../../data/services/home_service.dart';
import '../../widgets/neu_box.dart';
import '../../widgets/ac_dial_card.dart';
import '../../widgets/device_pill_tile.dart';
import '../../widgets/scene_card.dart';
import '../../widgets/hazard_banner.dart';
import '../security/security_screen.dart';
import '../control/device_control_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Timer? _pollingTimer;
  SensorReading? _sensors;
  DeviceStatus? _devices;
  List<AccessAttempt> _accessAttempts = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) _loadData(silent: true);
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final s = await HomeService.fetchCurrentSensors();
      final d = await HomeService.fetchDeviceStatus();
      final a = await HomeService.fetchAccessAttempts();
      if (mounted) {
        setState(() {
          _sensors = s;
          _devices = d;
          _accessAttempts = a;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _quickToggle(String key, dynamic val) async {
    final updated = await HomeService.controlDevice(key, val);
    if (mounted) {
      setState(() => _devices = updated);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _sensors == null) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    final sensors = _sensors ??
        SensorReading(
          temperature: 0,
          humidity: 0,
          lightIntensity: 0,
          gasPpm: 0,
          flameDetected: false,
          motionDetected: false,
          doorOpen: false,
          timestamp: DateTime.now(),
        );

    final devices = _devices ?? DeviceStatus(lastUpdated: DateTime.now());

    final recentSpoof = _accessAttempts.cast<AccessAttempt?>().firstWhere(
          (a) => a != null && a.isSpoofAttack,
          orElse: () => null,
        );

    return RefreshIndicator(
      onRefresh: () => _loadData(),
      color: AppColors.primary,
      backgroundColor: AppColors.neuBase,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Header: Profile Pill + Avatar (Matching Reference Top-Right)
            Row(
              children: [
                // Circular Avatar in recessed NeuBox exactly like image
                NeuBox(
                  isPressed: true,
                  shape: BoxShape.circle,
                  padding: const EdgeInsets.all(5),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF242C38),
                    ),
                    child: const Center(
                      child: Icon(Icons.person, color: Color(0xFFE2E7EE), size: 22),
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Pill Card: "Hi, Administrator / Kondisi Rumah Aman" + Options ⋮
                Expanded(
                  child: NeuBox(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    borderRadius: BorderRadius.circular(24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hi, Administrator',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                                letterSpacing: -0.2,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Smart Home Active',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        PopupMenuButton<int>(
                          icon: const Icon(Icons.more_vert, size: 18, color: AppColors.textSecondary),
                          color: AppColors.neuBase,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          itemBuilder: (context) => [
                            const PopupMenuItem(value: 1, child: Text('Refresh Sensor')),
                            const PopupMenuItem(value: 2, child: Text('Pengaturan')),
                          ],
                          onSelected: (val) {
                            if (val == 1) _loadData();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Emergency Hazard Alert Banner (Gas / Flame / Spoof)
            if (recentSpoof != null)
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SecurityScreen()),
                  );
                },
                child: const HazardBanner(
                  title: '🚨 PERINGATAN: WAJAH PALSU DITOLAK!',
                  message: 'Upaya pembobolan pintu menggunakan foto/layar HP telah digagalkan.',
                  icon: Icons.no_photography,
                  isDanger: true,
                ),
              ),

            if (sensors.flameDetected)
              const HazardBanner(
                title: '🔥 PERINGATAN: API TERDETEKSI!',
                message: 'Sensor flame mendeteksi nyala api. Segera periksa area rumah!',
                icon: Icons.local_fire_department,
                isDanger: true,
              ),

            if (sensors.isGasDanger)
              HazardBanner(
                title: '⚠️ KEBOCORAN GAS BERBAHAYA!',
                message: 'Kadar gas MQ-2 mencapai ${sensors.gasPpm.toStringAsFixed(0)} PPM (Ambang Bahaya > 400). Buka ventilasi!',
                icon: Icons.gas_meter,
                isDanger: true,
              )
            else if (sensors.isGasWarning)
              HazardBanner(
                title: 'Kadar Gas Meningkat',
                message: 'Kadar gas MQ-2: ${sensors.gasPpm.toStringAsFixed(0)} PPM (Waspada).',
                icon: Icons.info_outline,
                isDanger: false,
              ),

            if (_error != null)
              NeuBox(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(12),
                child: Text('Koneksi: $_error', style: const TextStyle(fontSize: 11, color: AppColors.danger)),
              ),

            // 1. Featured Air Conditioner / Peltier Cooling Dial Card (Exact match of reference image)
            AcDialCard(
              currentTemp: sensors.temperature,
              targetTemp: devices.targetTemperature,
              isOn: devices.coolingOn,
              isAutoMode: devices.coolingAutoMode,
              onToggle: (val) => _quickToggle('cooling', val),
              onTempChanged: (newTemp) => _quickToggle('target_temp', newTemp),
            ),
            const SizedBox(height: 20),

            // 2. Quick Scene / Automation Cards (Matching Reference Bottom-Left)
            Row(
              children: [
                Expanded(
                  child: SceneCard(
                    icon: Icons.wb_sunny_outlined,
                    title: 'Otomatis Cahaya',
                    subtitle: devices.lightAutoMode ? 'LDR Aktif' : 'Manual',
                    isActive: devices.lightAutoMode,
                    onTap: () => _quickToggle('light_auto_mode', !devices.lightAutoMode),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SceneCard(
                    icon: Icons.nights_stay_outlined,
                    title: 'Pintu Utama',
                    subtitle: devices.doorLocked ? 'Terkunci Aman' : 'Kunci Terbuka',
                    isActive: devices.doorLocked,
                    onTap: () => _quickToggle('door_lock', !devices.doorLocked),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Bottom Horizontal Scene Strip (Matching Reference Bottom-Left Strip)
            NeuBox(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const DeviceControlScreen()),
                );
              },
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              borderRadius: BorderRadius.circular(22),
              child: Row(
                children: [
                  NeuBox(
                    isPressed: true,
                    shape: BoxShape.circle,
                    padding: const EdgeInsets.all(8),
                    child: const Icon(Icons.add, size: 16, color: AppColors.textPrimary),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sistem Monitoring & Kontrol',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          '5 Sensor Aktif • 3 Aktuator Terhubung',
                          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  NeuBox(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    borderRadius: BorderRadius.circular(16),
                    child: const Text(
                      'Semua',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 3. Right-hand Card from Reference: Device & Telemetry Stack
            NeuBox(
              padding: const EdgeInsets.all(18),
              borderRadius: BorderRadius.circular(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row with ↗ icon
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.bolt, size: 22, color: AppColors.textPrimary),
                          SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Sensor & Perangkat',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              Text(
                                'Status Pemantauan Rumah',
                                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ],
                      ),
                      NeuBox(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const SecurityScreen()),
                          );
                        },
                        shape: BoxShape.circle,
                        padding: const EdgeInsets.all(8),
                        child: const Icon(Icons.north_east, size: 16, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Pill List Stack matching reference exactly
                  DevicePillTile(
                    icon: Icons.lightbulb_outline,
                    title: 'Lampu Penerangan',
                    subtitle: devices.lightOn ? 'Menyala • Mode Otomatis' : 'Mati • Standby',
                    onTap: () => _quickToggle('light', !devices.lightOn),
                    trailing: Text(
                      devices.lightOn ? 'ON' : 'OFF',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: devices.lightOn ? AppColors.textPrimary : AppColors.textMuted,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  DevicePillTile(
                    icon: Icons.lock_outline,
                    title: 'Solenoid Door Lock',
                    subtitle: devices.doorLocked ? 'Terkunci Aman • Proteksi Aktif' : 'Kunci Terbuka',
                    onTap: () => _quickToggle('door_lock', !devices.doorLocked),
                    trailing: Text(
                      devices.doorLocked ? 'LOCK' : 'OPEN',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: devices.doorLocked ? AppColors.normal : AppColors.warning,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  DevicePillTile(
                    icon: Icons.gas_meter_outlined,
                    title: 'Sensor Gas MQ-2',
                    subtitle: '${sensors.gasPpm.toStringAsFixed(0)} PPM • ${sensors.isGasDanger ? "BAHAYA" : (sensors.isGasWarning ? "Waspada" : "Normal")}',
                    trailing: Icon(
                      Icons.circle,
                      size: 10,
                      color: sensors.isGasDanger ? AppColors.danger : (sensors.isGasWarning ? AppColors.warning : AppColors.normal),
                    ),
                  ),
                  const SizedBox(height: 12),

                  DevicePillTile(
                    icon: Icons.local_fire_department_outlined,
                    title: 'Sensor Api (Flame)',
                    subtitle: sensors.flameDetected ? 'API TERDETEKSI!' : 'Aman • Tidak ada api',
                    trailing: Icon(
                      Icons.circle,
                      size: 10,
                      color: sensors.flameDetected ? AppColors.danger : AppColors.normal,
                    ),
                  ),
                  const SizedBox(height: 12),

                  DevicePillTile(
                    icon: Icons.motion_photos_on_outlined,
                    title: 'Sensor PIR (Pintu Depan)',
                    subtitle: sensors.motionDetected ? 'Ada orang di depan pintu' : 'Area sepi',
                    trailing: Icon(
                      Icons.circle,
                      size: 10,
                      color: sensors.motionDetected ? AppColors.activeBlue : AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 12),

                  DevicePillTile(
                    icon: Icons.water_drop_outlined,
                    title: 'Kelembapan Udara',
                    subtitle: '${sensors.humidity.toStringAsFixed(0)}% RH • Ideal',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
