import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/sensor_reading.dart';
import '../../../data/models/device_status.dart';
import '../../../data/models/face_model.dart';
import '../../../data/services/home_service.dart';
import '../../../data/services/sync_manager.dart';
import '../../widgets/neu_box.dart';
import '../../widgets/ac_dial_card.dart';
import '../../widgets/device_pill_tile.dart';
import '../../widgets/scene_card.dart';
import '../../../data/services/alert_manager.dart';
import '../main_navigation.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  SensorReading? _sensors;
  DeviceStatus? _devices;
  List<AccessAttempt> _lastAttempts = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _sensors = SyncManager.currentSensors.value;
    _devices = SyncManager.currentDeviceStatus.value;

    SyncManager.currentSensors.addListener(_onSensorsChanged);
    SyncManager.currentDeviceStatus.addListener(_onDevicesChanged);

    _loadAccessAttempts();
  }

  @override
  void dispose() {
    SyncManager.currentSensors.removeListener(_onSensorsChanged);
    SyncManager.currentDeviceStatus.removeListener(_onDevicesChanged);
    super.dispose();
  }

  void _onSensorsChanged() {
    if (!mounted) return;
    setState(() {
      _sensors = SyncManager.currentSensors.value;
    });
    _syncAlerts(_sensors, _lastAttempts);
  }

  void _onDevicesChanged() {
    if (!mounted) return;
    setState(() {
      _devices = SyncManager.currentDeviceStatus.value;
    });
  }

  Future<void> _loadAccessAttempts() async {
    try {
      final a = await HomeService.fetchAccessAttempts();
      if (mounted) {
        _lastAttempts = a;
        _syncAlerts(_sensors, a);
      }
    } catch (_) {}
  }

  Future<void> _loadData({bool silent = false}) async {
    if (!silent) {
      setState(() => _isLoading = true);
    }
    await SyncManager.syncAll(silent: silent);
    await _loadAccessAttempts();
    if (mounted && !silent) {
      setState(() => _isLoading = false);
    }
  }

  void _syncAlerts(SensorReading? sensors, List<AccessAttempt> attempts) {
    if (sensors == null) return;

    // Periksa apakah ada serangan spoofing yang terjadi sangat baru (< 60 detik lalu)
    final recentSpoof = attempts.cast<AccessAttempt?>().firstWhere(
          (a) =>
              a != null &&
              a.isSpoofAttack &&
              DateTime.now().difference(a.timestamp).inSeconds.abs() < 60,
          orElse: () => null,
        );

    if (sensors.flameDetected && !AlertManager.isDismissed('flame')) {
      AlertManager.show(DynamicAlert(
        id: 'flame',
        title: 'Api Terdeteksi!',
        message: 'Sensor flame membaca nyala api. Buzzer aktif.',
        icon: Icons.local_fire_department,
        priority: AlertPriority.danger,
        onTap: () => MainNavigation.switchTo(context, 0),
      ));
    } else if (sensors.isGasDanger && !AlertManager.isDismissed('gas')) {
      AlertManager.show(DynamicAlert(
        id: 'gas',
        title: 'Kebocoran Gas Berbahaya!',
        message: 'Kadar gas mencapai ${sensors.gasPpm.toStringAsFixed(0)} PPM.',
        icon: Icons.gas_meter,
        priority: AlertPriority.danger,
        onTap: () => MainNavigation.switchTo(context, 0),
      ));
    } else if (recentSpoof != null &&
        !AlertManager.isDismissed('spoof_${recentSpoof.id}')) {
      AlertManager.show(DynamicAlert(
        id: 'spoof_${recentSpoof.id}',
        title: 'Wajah Palsu Ditolak',
        message: 'Upaya pembobolan pintu teras digagalkan.',
        icon: Icons.no_photography,
        priority: AlertPriority.danger,
        onTap: () => MainNavigation.switchTo(context, 2),
      ));
    } else if (sensors.motionDetected && !AlertManager.isDismissed('motion')) {
      AlertManager.show(DynamicAlert(
        id: 'motion',
        title: 'Gerakan di Teras',
        message: 'Kamera teras aktif memantau.',
        icon: Icons.videocam,
        priority: AlertPriority.info,
        onTap: () => MainNavigation.switchTo(context, 2),
      ));
    } else if (sensors.rainDetected && !AlertManager.isDismissed('rain')) {
      AlertManager.show(DynamicAlert(
        id: 'rain',
        title: 'Hujan Terdeteksi',
        message: 'Kanopi atap telah ditutup otomatis.',
        icon: Icons.water_drop,
        priority: AlertPriority.warning,
        onTap: () => MainNavigation.switchTo(context, 1),
      ));
    } else if (sensors.isGasWarning && !AlertManager.isDismissed('gas_warn')) {
      AlertManager.show(DynamicAlert(
        id: 'gas_warn',
        title: 'Kadar Gas Meningkat',
        message: 'Kadar gas MQ-2: ${sensors.gasPpm.toStringAsFixed(0)} PPM.',
        icon: Icons.info_outline,
        priority: AlertPriority.warning,
        onTap: () => MainNavigation.switchTo(context, 0),
      ));
    }
  }

  Future<void> _quickToggle(String key, dynamic val) async {
    await SyncManager.updateDeviceSetting(key, val);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _sensors == null) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (_sensors == null && _error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 36, color: AppColors.danger),
              const SizedBox(height: 10),
              Text('Koneksi: $_error', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
        ),
      );
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

    return RefreshIndicator(
      onRefresh: () => _loadData(),
      color: AppColors.primary,
      backgroundColor: AppColors.neuBase,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // 1. Featured Peltier Cooling with MOSFET PWM Dial Card
            AcDialCard(
              currentTemp: sensors.temperature,
              targetTemp: devices.targetTemperature,
              isOn: devices.coolingOn,
              isAutoMode: devices.coolingAutoMode,
              peltierPwm: devices.peltierPwm,
              onToggle: (val) => _quickToggle('cooling', val),
              onTempChanged: (newTemp) => _quickToggle('target_temp', newTemp),
              onAutoModeChanged: (val) => _quickToggle('cooling_auto_mode', val),
            ),
            const SizedBox(height: 20),

            // 2. Quick Scene / Automation Cards: Lampu (PIR & LDR) + Atap (Sensor Hujan)
            Row(
              children: [
                Expanded(
                  child: SceneCard(
                    icon: Icons.wb_sunny_outlined,
                    title: 'Lampu & Teras',
                    subtitle: devices.lightAutoMode
                        ? (sensors.motionDetected ? 'Gerakan! Lampu ON' : (sensors.isDark ? 'Gelap: Lampu ON' : 'PIR/LDR Siaga'))
                        : 'Manual Mode',
                    isActive: devices.lightOn,
                    onTap: () => _quickToggle('light_auto_mode', !devices.lightAutoMode),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SceneCard(
                    icon: devices.roofOpen ? Icons.roofing : Icons.umbrella,
                    title: 'Atap Rumah',
                    subtitle: devices.roofAutoMode
                        ? (sensors.rainDetected ? 'Hujan (Tertutup)' : 'Cerah (Terbuka)')
                        : (devices.roofOpen ? 'Buka Manual' : 'Tutup Manual'),
                    isActive: devices.roofOpen,
                    onTap: () => _quickToggle('roof', !devices.roofOpen),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Bottom Horizontal Scene Strip (Matching Reference Bottom-Left Strip)
            NeuBox(
              onTap: () {
                MainNavigation.switchTo(context, 1);
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
                          MainNavigation.switchTo(context, 2);
                        },
                        shape: BoxShape.circle,
                        padding: const EdgeInsets.all(8),
                        child: const Icon(Icons.north_east, size: 16, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Pill List Stack
                  DevicePillTile(
                    icon: Icons.lightbulb_outline,
                    title: 'Lampu Penerangan (PIR & LDR)',
                    subtitle: devices.lightOn
                        ? 'Menyala • ${devices.lightAutoMode ? (sensors.motionDetected ? "PIR Gerakan Aktif" : "LDR Otomatis") : "Manual"}'
                        : 'Mati • Siaga',
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
                    icon: Icons.videocam_outlined,
                    title: 'Kamera Teras',
                    subtitle: sensors.motionDetected
                        ? '🟢 AKTIF • PIR Mendeteksi Gerakan'
                        : '⚪ Standby • Area Teras Sepi',
                    onTap: () {
                      MainNavigation.switchTo(context, 2);
                    },
                    trailing: Icon(
                      Icons.circle,
                      size: 10,
                      color: sensors.motionDetected ? AppColors.normal : AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 12),

                  DevicePillTile(
                    icon: Icons.roofing_outlined,
                    title: 'Atap Rumah (Kanopi)',
                    subtitle: '${devices.roofOpen ? "Terbuka" : "Tertutup"} • ${devices.roofAutoMode ? (sensors.rainDetected ? "Otomatis: Tutup karena Hujan" : "Otomatis: Buka karena Cerah") : "Mode Manual"}',
                    onTap: () => _quickToggle('roof', !devices.roofOpen),
                    trailing: Text(
                      devices.roofOpen ? 'OPEN' : 'CLOSED',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: devices.roofOpen ? AppColors.textPrimary : AppColors.warning,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  DevicePillTile(
                    icon: Icons.umbrella_outlined,
                    title: 'Sensor Hujan',
                    subtitle: sensors.rainDetected ? '🌧️ Hujan Sedang Turun' : '☀️ Kering / Tidak Hujan',
                    trailing: Icon(
                      Icons.circle,
                      size: 10,
                      color: sensors.rainDetected ? AppColors.activeBlue : AppColors.normal,
                    ),
                  ),
                  const SizedBox(height: 12),

                  DevicePillTile(
                    icon: Icons.notifications_active_outlined,
                    title: 'Alarm Buzzer (Flame & MQ-2)',
                    subtitle: devices.buzzerOn
                        ? '🚨 BERBUNYI NYARING • Peringatan Api/Gas!'
                        : '🔕 Senyap • Kondisi Aman',
                    trailing: Icon(
                      Icons.circle,
                      size: 10,
                      color: devices.buzzerOn ? AppColors.danger : AppColors.normal,
                    ),
                  ),
                  const SizedBox(height: 12),

                  DevicePillTile(
                    icon: Icons.local_fire_department_outlined,
                    title: 'Sensor Api (Flame)',
                    subtitle: sensors.flameDetected ? 'API TERDETEKSI! Output Buzzer Aktif' : 'Aman • Tidak ada api',
                    trailing: Icon(
                      Icons.circle,
                      size: 10,
                      color: sensors.flameDetected ? AppColors.danger : AppColors.normal,
                    ),
                  ),
                  const SizedBox(height: 12),

                  DevicePillTile(
                    icon: Icons.gas_meter_outlined,
                    title: 'Sensor Gas MQ-2',
                    subtitle: '${sensors.gasPpm.toStringAsFixed(0)} PPM • ${sensors.isGasDanger ? "BAHAYA (Buzzer ON)" : (sensors.isGasWarning ? "Waspada" : "Normal")}',
                    trailing: Icon(
                      Icons.circle,
                      size: 10,
                      color: sensors.isGasDanger ? AppColors.danger : (sensors.isGasWarning ? AppColors.warning : AppColors.normal),
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
