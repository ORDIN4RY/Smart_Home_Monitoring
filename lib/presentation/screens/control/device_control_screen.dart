import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/device_status.dart';
import '../../../data/models/sensor_reading.dart';
import '../../../data/services/home_service.dart';
import '../../widgets/neu_box.dart';
import '../../widgets/ac_dial_card.dart';
import '../../widgets/device_switch_card.dart';

class DeviceControlScreen extends StatefulWidget {
  const DeviceControlScreen({super.key});

  @override
  State<DeviceControlScreen> createState() => _DeviceControlScreenState();
}

class _DeviceControlScreenState extends State<DeviceControlScreen> {
  DeviceStatus? _deviceStatus;
  SensorReading? _sensors;
  bool _isLoading = true;
  bool _isActionInProgress = false;

  @override
  void initState() {
    super.initState();
    _fetchStatus();
  }

  Future<void> _fetchStatus() async {
    setState(() => _isLoading = true);
    final status = await HomeService.fetchDeviceStatus();
    final sensors = await HomeService.fetchCurrentSensors();
    if (mounted) {
      setState(() {
        _deviceStatus = status;
        _sensors = sensors;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleDevice(String key, dynamic value) async {
    setState(() => _isActionInProgress = true);
    final updated = await HomeService.controlDevice(key, value);
    if (mounted) {
      setState(() {
        _deviceStatus = updated;
        _isActionInProgress = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Perintah $key berhasil diterapkan'),
          duration: const Duration(seconds: 1),
          backgroundColor: AppColors.textPrimary,
        ),
      );
    }
  }

  void _confirmDoorUnlock() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.neuBase,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.lock_open, color: AppColors.warning),
            SizedBox(width: 10),
            Text('Buka Kunci Pintu', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Apakah Anda yakin ingin membuka solenoid door lock pintu depan?',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.textPrimary,
              foregroundColor: AppColors.neuBase,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              _toggleDevice('door_lock', false);
            },
            child: const Text('Buka Kunci'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _deviceStatus == null) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    final dev = _deviceStatus ?? DeviceStatus(lastUpdated: DateTime.now());
    final currentTemp = _sensors?.temperature ?? 28.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kendali Perangkat'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isActionInProgress ? null : _fetchStatus,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status bar
            NeuBox(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              borderRadius: BorderRadius.circular(20),
              child: Row(
                children: [
                  const Icon(Icons.wifi_tethering, size: 16, color: AppColors.normal),
                  const SizedBox(width: 8),
                  const Text('Sinkronisasi Aktif', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  const Spacer(),
                  Text(
                    AppFormatters.formatTimeOnly(dev.lastUpdated),
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // 1. Solenoid Door Lock Highlight Card
            NeuBox(
              padding: const EdgeInsets.all(20),
              borderRadius: BorderRadius.circular(26),
              child: Row(
                children: [
                  NeuBox(
                    isPressed: !dev.doorLocked,
                    shape: BoxShape.circle,
                    padding: const EdgeInsets.all(14),
                    child: Icon(
                      dev.doorLocked ? Icons.lock : Icons.lock_open,
                      color: dev.doorLocked ? AppColors.normal : AppColors.warning,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Solenoid Door Lock',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          dev.doorLocked ? 'Terkunci Otomatis (Aman)' : 'KUNCI TERBUKA!',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: dev.doorLocked ? AppColors.normal : AppColors.warning,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Tactile Push Button
                  NeuBox(
                    onTap: () {
                      if (dev.doorLocked) {
                        _confirmDoorUnlock();
                      } else {
                        _toggleDevice('door_lock', true);
                      }
                    },
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    borderRadius: BorderRadius.circular(16),
                    isPressed: !dev.doorLocked,
                    child: Text(
                      dev.doorLocked ? 'Buka' : 'Kunci',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: dev.doorLocked ? AppColors.textPrimary : AppColors.warning,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 2. Air Conditioner / Peltier Cooling Dial Card with MOSFET PWM
            AcDialCard(
              currentTemp: currentTemp,
              targetTemp: dev.targetTemperature,
              isOn: dev.coolingOn,
              isAutoMode: dev.coolingAutoMode,
              peltierPwm: dev.peltierPwm,
              onToggle: (val) => _toggleDevice('cooling', val),
              onTempChanged: (newTemp) => _toggleDevice('target_temp', newTemp),
              onAutoModeChanged: (val) => _toggleDevice('cooling_auto_mode', val),
            ),
            const SizedBox(height: 20),

            // 3. Kontrol Atap Rumah (Sensor Hujan: Otomatis & Manual)
            DeviceSwitchCard(
              icon: Icons.roofing_outlined,
              title: 'Atap Rumah (Kanopi)',
              description: dev.roofOpen ? 'Atap Terbuka' : 'Atap Tertutup Rapat',
              isOn: dev.roofOpen,
              isAutoMode: dev.roofAutoMode,
              onToggle: (val) => _toggleDevice('roof', val),
              onAutoModeChanged: (val) => _toggleDevice('roof_auto_mode', val),
              extraWidget: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          (_sensors?.rainDetected ?? false) ? Icons.water_drop : Icons.wb_sunny_outlined,
                          size: 14,
                          color: (_sensors?.rainDetected ?? false) ? AppColors.activeBlue : AppColors.normal,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          (_sensors?.rainDetected ?? false)
                              ? 'Sensor Hujan: 🌧️ Hujan Terdeteksi'
                              : 'Sensor Hujan: ☀️ Kering / Tidak Hujan',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: (_sensors?.rainDetected ?? false) ? AppColors.activeBlue : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Mode Otomatis menutup atap seketika sensor hujan mendeteksi air, dan membuka kembali saat cerah. Anda juga dapat membuka/menutup secara manual.',
                      style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 4. Lampu Penerangan & Teras (PIR & LDR)
            DeviceSwitchCard(
              icon: Icons.lightbulb_outline,
              title: 'Lampu Penerangan & Teras',
              description: dev.lightOn ? 'Lampu sedang Menyala' : 'Lampu Mati',
              isOn: dev.lightOn,
              isAutoMode: dev.lightAutoMode,
              onToggle: (val) => _toggleDevice('light', val),
              onAutoModeChanged: (val) => _toggleDevice('light_auto_mode', val),
              extraWidget: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (_sensors?.motionDetected ?? false)
                          ? 'PIR: 🟢 Ada Gerakan di Teras (Kamera Aktif)'
                          : 'PIR: ⚪ Tidak ada gerakan di teras',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: (_sensors?.motionDetected ?? false) ? AppColors.normal : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Mode Auto terhubung ke sensor LDR (gelap < 30%) dan sensor PIR (gerakan teras). Saat PIR aktif, kamera juga otomatis diaktifkan.',
                      style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 5. Output Buzzer Peringatan (Flame & MQ-2 Gas)
            DeviceSwitchCard(
              icon: Icons.notifications_active_outlined,
              title: 'Alarm Buzzer (Flame & MQ-2)',
              description: dev.buzzerOn
                  ? '🚨 ALARM AKTIF (Bahaya Api/Gas Terdeteksi!)'
                  : '🔕 Senyap • Standby Aman',
              isOn: dev.buzzerOn,
              onToggle: (val) => _toggleDevice('buzzer', val),
              extraWidget: const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  'Output Buzzer didedikasikan khusus sebagai peringatan suara darurat saat sensor flame mendeteksi nyala api atau sensor MQ-2 membaca gas berbahaya (> 400 PPM).',
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
