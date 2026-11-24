import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/device_status.dart';
import '../../../data/models/sensor_reading.dart';
import '../../../data/services/sync_manager.dart';
import '../../../data/services/alert_manager.dart';
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
  bool _isSaving = false;

  // ── Local Staged State (Untuk sistem simpan batch seluruh halaman) ──
  double _stagedTargetTemp = 24.0;
  bool _stagedCoolingOn = false;
  bool _stagedCoolingAuto = false;
  bool _stagedRoofOpen = false;
  bool _stagedRoofAuto = false;
  bool _stagedLightOn = false;
  bool _stagedLightAuto = false;
  bool _stagedBuzzerOn = false;

  @override
  void initState() {
    super.initState();
    _deviceStatus = SyncManager.currentDeviceStatus.value;
    _sensors = SyncManager.currentSensors.value;
    _initStagedValues(_deviceStatus ?? DeviceStatus(lastUpdated: DateTime.now()));

    SyncManager.currentDeviceStatus.addListener(_onDeviceStatusChanged);
    SyncManager.currentSensors.addListener(_onSensorsChanged);
  }

  @override
  void dispose() {
    SyncManager.currentDeviceStatus.removeListener(_onDeviceStatusChanged);
    SyncManager.currentSensors.removeListener(_onSensorsChanged);
    super.dispose();
  }

  void _onDeviceStatusChanged() {
    if (!mounted) return;
    final dev = SyncManager.currentDeviceStatus.value;
    setState(() {
      _deviceStatus = dev;
      // Perbarui staged hanya jika belum ada perubahan lokal yang belum disimpan
      if (!_hasUnsavedChanges) {
        _initStagedValues(dev);
      }
    });
  }

  void _onSensorsChanged() {
    if (!mounted) return;
    setState(() {
      _sensors = SyncManager.currentSensors.value;
    });
  }

  void _initStagedValues(DeviceStatus dev) {
    _stagedTargetTemp = dev.targetTemperature;
    _stagedCoolingOn = dev.coolingOn;
    _stagedCoolingAuto = dev.coolingAutoMode;
    _stagedRoofOpen = dev.roofOpen;
    _stagedRoofAuto = dev.roofAutoMode;
    _stagedLightOn = dev.lightOn;
    _stagedLightAuto = dev.lightAutoMode;
    _stagedBuzzerOn = dev.buzzerOn;
  }

  bool get _hasUnsavedChanges {
    if (_deviceStatus == null) return false;
    final dev = _deviceStatus!;
    return (_stagedTargetTemp - dev.targetTemperature).abs() > 0.1 ||
        _stagedCoolingOn != dev.coolingOn ||
        _stagedCoolingAuto != dev.coolingAutoMode ||
        _stagedRoofOpen != dev.roofOpen ||
        _stagedRoofAuto != dev.roofAutoMode ||
        _stagedLightOn != dev.lightOn ||
        _stagedLightAuto != dev.lightAutoMode ||
        _stagedBuzzerOn != dev.buzzerOn;
  }

  Future<void> _saveAllChanges() async {
    if (!_hasUnsavedChanges || _isSaving || _deviceStatus == null) return;
    setState(() => _isSaving = true);
    final dev = _deviceStatus!;

    try {
      final settings = <String, dynamic>{};

      if (_stagedCoolingOn != dev.coolingOn) {
        settings['cooling'] = _stagedCoolingOn;
      }
      if ((_stagedTargetTemp - dev.targetTemperature).abs() > 0.1) {
        settings['target_temp'] = _stagedTargetTemp;
      }
      if (_stagedCoolingAuto != dev.coolingAutoMode) {
        settings['cooling_auto_mode'] = _stagedCoolingAuto;
      }
      if (_stagedRoofOpen != dev.roofOpen) {
        settings['roof'] = _stagedRoofOpen;
      }
      if (_stagedRoofAuto != dev.roofAutoMode) {
        settings['roof_auto_mode'] = _stagedRoofAuto;
      }
      if (_stagedLightOn != dev.lightOn) {
        settings['light'] = _stagedLightOn;
      }
      if (_stagedLightAuto != dev.lightAutoMode) {
        settings['light_auto_mode'] = _stagedLightAuto;
      }
      if (_stagedBuzzerOn != dev.buzzerOn) {
        settings['buzzer'] = _stagedBuzzerOn;
      }

      await SyncManager.updateMultipleSettings(settings);

      if (mounted) {
        setState(() {
          _deviceStatus = SyncManager.currentDeviceStatus.value;
          _initStagedValues(_deviceStatus!);
          _isSaving = false;
        });

        AlertManager.show(
          const DynamicAlert(
            id: 'settings_applied',
            title: 'Pengaturan Disimpan',
            message: 'Semua perubahan perangkat berhasil disimpan ke lokal & dikirim ke server.',
            icon: Icons.check_circle_outline,
            priority: AlertPriority.info,
          ),
          autoCloseDuration: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan pengaturan: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
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
            onPressed: () async {
              Navigator.of(ctx).pop();
              await SyncManager.updateDeviceSetting('door_lock', false);
            },
            child: const Text('Buka Kunci'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dev = _deviceStatus ?? DeviceStatus(lastUpdated: DateTime.now());
    final currentTemp = _sensors?.temperature ?? 28.0;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      // ── Neumorphic Themed FAB (Tidak lagi hitam, selaras dengan tema) ──
      floatingActionButton: AnimatedSlide(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        offset: _hasUnsavedChanges ? Offset.zero : const Offset(0, 1.5),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 220),
          opacity: _hasUnsavedChanges ? 1.0 : 0.0,
          child: _hasUnsavedChanges
              ? Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: GestureDetector(
                    onTap: _isSaving ? null : _saveAllChanges,
                    child: NeuBox(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                      borderRadius: BorderRadius.circular(24),
                      glowColor: AppColors.normal.withAlpha(50),
                      glowRadius: 10,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_isSaving)
                            const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.textPrimary,
                              ),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.normal,
                              ),
                              child: const Icon(
                                Icons.check,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          const SizedBox(width: 10),
                          Text(
                            _isSaving ? 'Menyimpan...' : 'Simpan Pengaturan',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => SyncManager.syncAll(silent: false),
        color: AppColors.primary,
        backgroundColor: AppColors.neuBase,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                      onTap: () async {
                        if (dev.doorLocked) {
                          _confirmDoorUnlock();
                        } else {
                          await SyncManager.updateDeviceSetting('door_lock', true);
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
                targetTemp: _stagedTargetTemp,
                isOn: _stagedCoolingOn,
                isAutoMode: _stagedCoolingAuto,
                peltierPwm: dev.peltierPwm,
                onToggle: (val) => setState(() => _stagedCoolingOn = val),
                onTempChanged: (newTemp) => setState(() => _stagedTargetTemp = newTemp),
                onAutoModeChanged: (val) => setState(() => _stagedCoolingAuto = val),
              ),
              const SizedBox(height: 20),

              // 3. Kontrol Atap Rumah (Sensor Hujan: Otomatis & Manual)
              DeviceSwitchCard(
                icon: Icons.roofing_outlined,
                title: 'Atap Rumah (Kanopi)',
                description: _stagedRoofOpen ? 'Atap Terbuka' : 'Atap Tertutup',
                isOn: _stagedRoofOpen,
                isAutoMode: _stagedRoofAuto,
                onToggle: (val) => setState(() => _stagedRoofOpen = val),
                onAutoModeChanged: (val) => setState(() => _stagedRoofAuto = val),
                extraWidget: Row(
                  children: [
                    Icon(
                      (_sensors?.rainDetected ?? false) ? Icons.water_drop : Icons.wb_sunny_outlined,
                      size: 14,
                      color: (_sensors?.rainDetected ?? false) ? AppColors.activeBlue : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      (_sensors?.rainDetected ?? false) ? 'Sensor: Hujan Terdeteksi' : 'Sensor: Kering',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: (_sensors?.rainDetected ?? false) ? AppColors.activeBlue : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // 4. Lampu Penerangan & Teras (PIR & LDR)
              DeviceSwitchCard(
                icon: Icons.lightbulb_outline,
                title: 'Lampu Penerangan & Teras',
                description: _stagedLightOn ? 'Menyala' : 'Mati',
                isOn: _stagedLightOn,
                isAutoMode: _stagedLightAuto,
                onToggle: (val) => setState(() => _stagedLightOn = val),
                onAutoModeChanged: (val) => setState(() => _stagedLightAuto = val),
                extraWidget: Row(
                  children: [
                    Icon(
                      Icons.motion_photos_on_outlined,
                      size: 14,
                      color: (_sensors?.motionDetected ?? false) ? AppColors.normal : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      (_sensors?.motionDetected ?? false) ? 'PIR: Ada Gerakan' : 'PIR: Siaga',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: (_sensors?.motionDetected ?? false) ? AppColors.normal : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // 5. Output Buzzer Peringatan (Flame & MQ-2 Gas)
              DeviceSwitchCard(
                icon: Icons.notifications_active_outlined,
                title: 'Alarm Buzzer',
                description: _stagedBuzzerOn ? 'Alarm Bunyi' : 'Siaga / Aman',
                isOn: _stagedBuzzerOn,
                onToggle: (val) => setState(() => _stagedBuzzerOn = val),
              ),
              // Extra bottom padding for FAB clear space
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}
