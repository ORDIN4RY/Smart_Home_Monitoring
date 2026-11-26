import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/device_status.dart';
import '../../../data/models/sensor_reading.dart';
import '../../../data/services/sync_manager.dart';
import '../../../data/services/alert_manager.dart';
import '../../widgets/neu_box.dart';
import '../../widgets/ac_dial_card.dart';
import '../../widgets/device_switch_card.dart';
import '../../widgets/door_lock_slider.dart';

class DeviceControlScreen extends StatefulWidget {
  const DeviceControlScreen({super.key});

  @override
  State<DeviceControlScreen> createState() => _DeviceControlScreenState();
}

class _DeviceControlScreenState extends State<DeviceControlScreen> {
  DeviceStatus? _deviceStatus;
  SensorReading? _sensors;
  bool _isSaving = false;
  bool _isInteractingDial = false;

  // ── Local Staged State (Nullable hingga data aktual diterima) ──
  double? _stagedTargetTemp;
  bool? _stagedCoolingOn;
  bool _stagedCoolingAuto = true;
  bool? _stagedRoofOpen;
  bool _stagedRoofAuto = true;
  bool? _stagedLightOn;
  bool _stagedLightAuto = true;
  bool? _stagedBuzzerOn;

  @override
  void initState() {
    super.initState();
    _deviceStatus = SyncManager.currentDeviceStatus.value;
    _sensors = SyncManager.currentSensors.value;
    _initStagedValues(_deviceStatus);

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

  void _initStagedValues(DeviceStatus? dev) {
    if (dev == null) {
      _stagedTargetTemp = null;
      _stagedCoolingOn = null;
      _stagedCoolingAuto = true;
      _stagedRoofOpen = null;
      _stagedRoofAuto = true;
      _stagedLightOn = null;
      _stagedLightAuto = true;
      _stagedBuzzerOn = null;
      return;
    }
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
    final tempChanged = _stagedTargetTemp != null &&
        (_stagedTargetTemp! - dev.targetTemperature).abs() > 0.1;
    return tempChanged ||
        _stagedCoolingOn != dev.coolingOn ||
        _stagedCoolingAuto != dev.coolingAutoMode ||
        _stagedRoofOpen != dev.roofOpen ||
        _stagedRoofAuto != dev.roofAutoMode ||
        _stagedLightOn != dev.lightOn ||
        _stagedLightAuto != dev.lightAutoMode ||
        _stagedBuzzerOn != dev.buzzerOn;
  }

  void _resetChanges() {
    if (_deviceStatus == null) return;
    setState(() {
      _initStagedValues(_deviceStatus);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Perubahan dibatalkan, kembali ke pengaturan aktif.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _saveAllChanges() async {
    if (!_hasUnsavedChanges || _isSaving || _deviceStatus == null) return;
    setState(() => _isSaving = true);
    final dev = _deviceStatus!;

    try {
      final settings = <String, dynamic>{};

      if (_stagedCoolingOn != null && _stagedCoolingOn != dev.coolingOn) {
        settings['cooling'] = _stagedCoolingOn;
      }
      if (_stagedTargetTemp != null &&
          (_stagedTargetTemp! - dev.targetTemperature).abs() > 0.1) {
        settings['target_temp'] = _stagedTargetTemp;
      }
      if (_stagedCoolingAuto != dev.coolingAutoMode) {
        settings['cooling_auto_mode'] = _stagedCoolingAuto;
      }
      if (_stagedRoofOpen != null && _stagedRoofOpen != dev.roofOpen) {
        settings['roof'] = _stagedRoofOpen;
      }
      if (_stagedRoofAuto != dev.roofAutoMode) {
        settings['roof_auto_mode'] = _stagedRoofAuto;
      }
      if (_stagedLightOn != null && _stagedLightOn != dev.lightOn) {
        settings['light'] = _stagedLightOn;
      }
      if (_stagedLightAuto != dev.lightAutoMode) {
        settings['light_auto_mode'] = _stagedLightAuto;
      }
      if (_stagedBuzzerOn != null && _stagedBuzzerOn != dev.buzzerOn) {
        settings['buzzer'] = _stagedBuzzerOn;
      }

      await SyncManager.updateMultipleSettings(settings);

      if (mounted) {
        setState(() {
          _deviceStatus = SyncManager.currentDeviceStatus.value;
          _initStagedValues(_deviceStatus);
          _isSaving = false;
        });

        AlertManager.show(
          const DynamicAlert(
            id: 'settings_applied',
            title: 'Pengaturan Disimpan',
            message: 'Semua perubahan perangkat berhasil disimpan & dikirim ke server.',
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

  @override
  Widget build(BuildContext context) {
    final dev = _deviceStatus;
    final sensors = _sensors;
    final currentTemp = sensors?.temperature;
    final isDoorBusy = dev?.isDoorBusy ?? false;
    final doorLocked = dev?.doorLocked;

    final String doorStatusText;
    final Color doorStatusColor;
    if (dev == null) {
      doorStatusText = 'Tidak Terdeteksi';
      doorStatusColor = AppColors.textMuted;
    } else if (dev.doorTransition == 'opening') {
      doorStatusText = 'Sedang Membuka (Menunggu Wemos)...';
      doorStatusColor = AppColors.activeBlue;
    } else if (dev.doorTransition == 'closing') {
      doorStatusText = 'Sedang Menutup (Menunggu Wemos)...';
      doorStatusColor = AppColors.activeBlue;
    } else if (doorLocked == null) {
      doorStatusText = sensors?.doorOpen == null
          ? 'Tidak Terdeteksi'
          : (sensors!.doorOpen! ? 'Pintu Terbuka' : 'Pintu Tertutup');
      doorStatusColor = sensors?.doorOpen == null ? AppColors.textMuted : AppColors.normal;
    } else {
      final phys = sensors?.doorOpen == null
          ? 'Sensor: Tidak Terdeteksi'
          : (sensors!.doorOpen! ? 'Pintu Terbuka' : 'Pintu Tertutup');
      doorStatusText = '${doorLocked ? 'Terkunci' : 'Terbuka'} • $phys';
      doorStatusColor = doorLocked ? AppColors.normal : AppColors.warning;
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
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
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: _isSaving ? null : _resetChanges,
                        child: NeuBox(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                          borderRadius: BorderRadius.circular(24),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.undo_rounded, size: 15, color: AppColors.danger),
                              SizedBox(width: 6),
                              Text(
                                'Batalkan',
                                style: TextStyle(
                                  color: AppColors.danger,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
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
                                  width: 16,
                                  height: 16,
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
                                    size: 13,
                                    color: Colors.white,
                                  ),
                                ),
                              const SizedBox(width: 8),
                              Text(
                                _isSaving ? 'Menyimpan...' : 'Simpan Pengaturan',
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
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
          physics: _isInteractingDial
              ? const NeverScrollableScrollPhysics()
              : const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Solenoid Door Lock Highlight Card dengan Tactile Toggle
              NeuBox(
                padding: const EdgeInsets.all(18),
                borderRadius: BorderRadius.circular(24),
                child: Row(
                  children: [
                    NeuBox(
                      isPressed: doorLocked == true,
                      shape: BoxShape.circle,
                      padding: const EdgeInsets.all(12),
                      child: Icon(
                        Icons.sensor_door_outlined,
                        color: isDoorBusy
                            ? AppColors.activeBlue
                            : (doorLocked == null
                                ? AppColors.textMuted
                                : (doorLocked ? AppColors.normal : AppColors.warning)),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
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
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            transitionBuilder: (child, anim) =>
                                FadeTransition(opacity: anim, child: child),
                            child: Text(
                              doorStatusText,
                              key: ValueKey('control_door_$doorStatusText'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: doorStatusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    DoorLockToggle(
                      isLocked: doorLocked,
                      isLoading: isDoorBusy,
                      onChanged: (dev == null || isDoorBusy)
                          ? null
                          : (newLockState) async {
                              await SyncManager.updateDeviceSetting('door_lock', newLockState);
                            },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 2. Air Conditioner / Peltier Cooling Dial Card
              AcDialCard(
                currentTemp: currentTemp,
                targetTemp: _stagedTargetTemp,
                isOn: _stagedCoolingOn,
                isAutoMode: _stagedCoolingAuto,
                peltierPwm: dev?.peltierPwm,
                onInteractionChanged: (interacting) {
                  if (_isInteractingDial != interacting) {
                    setState(() => _isInteractingDial = interacting);
                  }
                },
                onToggle: dev != null
                    ? (val) => setState(() => _stagedCoolingOn = val)
                    : null,
                onTempChanged: _stagedTargetTemp != null
                    ? (newTemp) => setState(() => _stagedTargetTemp = newTemp)
                    : null,
                onAutoModeChanged: dev != null
                    ? (val) => setState(() => _stagedCoolingAuto = val)
                    : null,
              ),
              const SizedBox(height: 20),

              // 3. Kontrol Atap Rumah
              DeviceSwitchCard(
                icon: Icons.roofing_outlined,
                title: 'Atap Rumah (Kanopi)',
                description: _stagedRoofOpen == null
                    ? 'Tidak Terdeteksi'
                    : (_stagedRoofOpen! ? 'Atap Terbuka' : 'Atap Tertutup'),
                isOn: _stagedRoofOpen,
                isAutoMode: dev != null ? _stagedRoofAuto : null,
                onToggle: dev != null ? (val) => setState(() => _stagedRoofOpen = val) : null,
                onAutoModeChanged: dev != null ? (val) => setState(() => _stagedRoofAuto = val) : null,
                extraWidget: Row(
                  children: [
                    Icon(
                      sensors?.rainDetected == true ? Icons.water_drop : Icons.wb_sunny_outlined,
                      size: 14,
                      color: sensors?.rainDetected == null
                          ? AppColors.textMuted
                          : (sensors!.rainDetected! ? AppColors.activeBlue : AppColors.textSecondary),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      sensors?.rainDetected == null
                          ? 'Sensor: Tidak Terdeteksi'
                          : (sensors!.rainDetected!
                              ? 'Sensor: Hujan Terdeteksi'
                              : 'Sensor: Kering'),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: sensors?.rainDetected == null
                            ? AppColors.textMuted
                            : (sensors!.rainDetected!
                                ? AppColors.activeBlue
                                : AppColors.textSecondary),
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
                description: _stagedLightOn == null
                    ? 'Tidak Terdeteksi'
                    : (_stagedLightOn! ? 'Menyala' : 'Mati'),
                isOn: _stagedLightOn,
                isAutoMode: dev != null ? _stagedLightAuto : null,
                onToggle: dev != null ? (val) => setState(() => _stagedLightOn = val) : null,
                onAutoModeChanged: dev != null ? (val) => setState(() => _stagedLightAuto = val) : null,
                extraWidget: Row(
                  children: [
                    Icon(
                      Icons.motion_photos_on_outlined,
                      size: 14,
                      color: sensors?.motionDetected == null
                          ? AppColors.textMuted
                          : (sensors!.motionDetected!
                              ? AppColors.normal
                              : AppColors.textSecondary),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      sensors?.motionDetected == null
                          ? 'PIR: Tidak Terdeteksi'
                          : (sensors!.motionDetected! ? 'PIR: Ada Gerakan' : 'PIR: Siaga'),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: sensors?.motionDetected == null
                            ? AppColors.textMuted
                            : (sensors!.motionDetected!
                                ? AppColors.normal
                                : AppColors.textSecondary),
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
                description: _stagedBuzzerOn == null
                    ? 'Tidak Terdeteksi'
                    : (_stagedBuzzerOn! ? 'Alarm Nyaring Aktif' : 'Siaga / Senyap'),
                isOn: _stagedBuzzerOn,
                onToggle: dev != null ? (val) => setState(() => _stagedBuzzerOn = val) : null,
                extraWidget: Wrap(
                  spacing: 14,
                  runSpacing: 6,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          sensors?.flameDetected == true
                              ? Icons.local_fire_department
                              : Icons.shield_outlined,
                          size: 14,
                          color: sensors?.flameDetected == null
                              ? AppColors.textMuted
                              : (sensors!.flameDetected! ? AppColors.danger : AppColors.normal),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          sensors?.flameDetected == null
                              ? 'Api: Tidak Terdeteksi'
                              : (sensors!.flameDetected! ? 'Api: TERDETEKSI' : 'Status Api: Aman'),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: sensors?.flameDetected == null
                                ? AppColors.textMuted
                                : (sensors!.flameDetected!
                                    ? AppColors.danger
                                    : AppColors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.gas_meter_outlined,
                          size: 14,
                          color: sensors?.gasPpm == null
                              ? AppColors.textMuted
                              : (sensors!.isGasDanger
                                  ? AppColors.danger
                                  : (sensors.isGasWarning
                                      ? AppColors.warning
                                      : AppColors.textSecondary)),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          sensors?.gasPpm == null
                              ? 'Gas: Tidak Terdeteksi'
                              : 'Gas: ${sensors!.gasPpm!.toStringAsFixed(0)} PPM',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: sensors?.gasPpm == null
                                ? AppColors.textMuted
                                : (sensors!.isGasDanger
                                    ? AppColors.danger
                                    : (sensors.isGasWarning
                                        ? AppColors.warning
                                        : AppColors.textSecondary)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}
