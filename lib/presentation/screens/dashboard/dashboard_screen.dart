import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/sensor_reading.dart';
import '../../../data/models/device_status.dart';
import '../../../data/models/face_model.dart';
import '../../../data/services/home_service.dart';
import '../../../data/services/sync_manager.dart';
import '../../../data/services/alert_manager.dart';
import '../../../data/services/weather_service.dart';
import '../../widgets/neu_box.dart';
import '../../widgets/ac_dial_card.dart';
import '../../widgets/door_lock_slider.dart';
import '../main_navigation.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  SensorReading? _sensors;
  DeviceStatus? _devices;
  WeatherData? _weather;
  bool _weatherAttempted = false;
  List<AccessAttempt> _lastAttempts = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _sensors = SyncManager.currentSensors.value;
    _devices = SyncManager.currentDeviceStatus.value;
    _weather = WeatherService.currentWeather.value;

    SyncManager.currentSensors.addListener(_onSensorsChanged);
    SyncManager.currentDeviceStatus.addListener(_onDevicesChanged);
    WeatherService.currentWeather.addListener(_onWeatherChanged);

    _loadAccessAttempts();
    _initWeather();
  }

  Future<void> _initWeather() async {
    await WeatherService.loadSavedLocation();
    await WeatherService.fetchCurrentWeather();
    if (mounted) {
      setState(() => _weatherAttempted = true);
    }
  }

  @override
  void dispose() {
    SyncManager.currentSensors.removeListener(_onSensorsChanged);
    SyncManager.currentDeviceStatus.removeListener(_onDevicesChanged);
    WeatherService.currentWeather.removeListener(_onWeatherChanged);
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

  void _onWeatherChanged() {
    if (!mounted) return;
    setState(() {
      _weather = WeatherService.currentWeather.value;
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
    await WeatherService.fetchCurrentWeather(forceRefresh: true);
    if (mounted && !silent) {
      setState(() {
        _weatherAttempted = true;
        _isLoading = false;
      });
    }
  }

  void _syncAlerts(SensorReading? sensors, List<AccessAttempt> attempts) {
    if (sensors == null) return;

    final recentSpoof = attempts.cast<AccessAttempt?>().firstWhere(
          (a) =>
              a != null &&
              a.isSpoofAttack &&
              DateTime.now().difference(a.timestamp).inSeconds.abs() < 60,
          orElse: () => null,
        );

    if (sensors.flameDetected == true && !AlertManager.isDismissed('flame')) {
      AlertManager.show(DynamicAlert(
        id: 'flame',
        title: 'Api Terdeteksi!',
        message: 'Segera periksa kondisi rumah.',
        icon: Icons.local_fire_department,
        priority: AlertPriority.danger,
        onTap: () => MainNavigation.switchTo(context, 0),
      ));
    } else if (sensors.isGasDanger && !AlertManager.isDismissed('gas')) {
      AlertManager.show(DynamicAlert(
        id: 'gas',
        title: 'Gas Berbahaya!',
        message: 'Kadar gas ${sensors.gasPpm!.toStringAsFixed(0)} PPM.',
        icon: Icons.gas_meter,
        priority: AlertPriority.danger,
        onTap: () => MainNavigation.switchTo(context, 0),
      ));
    } else if (recentSpoof != null &&
        !AlertManager.isDismissed('spoof_${recentSpoof.id}')) {
      AlertManager.show(DynamicAlert(
        id: 'spoof_${recentSpoof.id}',
        title: 'Pemalsuan Wajah',
        message: '',
        icon: Icons.gpp_bad_rounded,
        priority: AlertPriority.danger,
        imageUrl: recentSpoof.fullSnapshotUrl,
        onTap: () => MainNavigation.switchTo(context, 2),
      ));
    } else if (sensors.motionDetected == true && !AlertManager.isDismissed('motion')) {
      AlertManager.show(DynamicAlert(
        id: 'motion',
        title: 'Ada Orang di Teras',
        message: '',
        icon: Icons.directions_walk_rounded,
        priority: AlertPriority.info,
        onTap: () => MainNavigation.switchTo(context, 2),
      ));
    } else if (sensors.rainDetected == true && !AlertManager.isDismissed('rain')) {
      AlertManager.show(DynamicAlert(
        id: 'rain',
        title: 'Hujan Terdeteksi',
        message: '',
        icon: Icons.water_drop_rounded,
        priority: AlertPriority.warning,
        onTap: () => MainNavigation.switchTo(context, 1),
      ));
    } else if (sensors.isGasWarning && !AlertManager.isDismissed('gas_warn')) {
      AlertManager.show(DynamicAlert(
        id: 'gas_warn',
        title: 'Gas Meningkat',
        message: 'Kadar gas ${sensors.gasPpm!.toStringAsFixed(0)} PPM.',
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
    if (_isLoading && _sensors == null && _devices == null) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    final sensors = _sensors;
    final devices = _devices;
    final weather = _weather;

    final bool? motionDetected = sensors?.motionDetected;
    final bool? doorLocked = devices?.doorLocked;
    final bool isDoorBusy = devices?.isDoorBusy ?? false;
    final bool? doorOpenPhys = sensors?.doorOpen;

    final String doorStatusLabel;
    final Color doorStatusColor;
    if (devices == null) {
      doorStatusLabel = 'Tidak Terdeteksi';
      doorStatusColor = AppColors.textMuted;
    } else if (devices.doorTransition == 'opening') {
      doorStatusLabel = 'Sedang Membuka (Menunggu Wemos)...';
      doorStatusColor = AppColors.activeBlue;
    } else if (devices.doorTransition == 'closing') {
      doorStatusLabel = 'Sedang Menutup (Menunggu Wemos)...';
      doorStatusColor = AppColors.activeBlue;
    } else if (doorLocked == null) {
      doorStatusLabel = doorOpenPhys == null
          ? 'Status Pintu: Tidak Terdeteksi'
          : (doorOpenPhys ? 'Pintu Terbuka' : 'Pintu Tertutup');
      doorStatusColor = doorOpenPhys == null ? AppColors.textMuted : AppColors.normal;
    } else {
      final lockText = doorLocked ? 'Terkunci' : 'Terbuka';
      final physText = doorOpenPhys == null
          ? 'Sensor: Tidak Terdeteksi'
          : (doorOpenPhys ? 'Pintu Terbuka' : 'Pintu Tertutup');
      doorStatusLabel = '$lockText • $physText';
      doorStatusColor = doorLocked ? AppColors.normal : AppColors.warning;
    }

    final bool? lightOn = devices?.lightOn;
    final bool? roofOpen = devices?.roofOpen;
    final bool? rainDetected = sensors?.rainDetected;
    final double? gasPpm = sensors?.gasPpm;
    final bool? flameDetected = sensors?.flameDetected;

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
            // ── 1. Header Cuaca & Lingkungan Terpadu ──
            NeuBox(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              borderRadius: BorderRadius.circular(22),
              onTap: () => WeatherService.fetchCurrentWeather(forceRefresh: true),
              child: Row(
                children: [
                  NeuBox(
                    isPressed: true,
                    shape: BoxShape.circle,
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      weather?.iconData ?? Icons.wb_sunny_outlined,
                      size: 20,
                      color: weather != null ? AppColors.activeBlue : AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          weather != null
                              ? '${weather.temperature.toStringAsFixed(0)}°C • ${weather.conditionText}'
                              : (_weatherAttempted
                                  ? 'Cuaca Tidak Terdeteksi'
                                  : 'Memuat Cuaca...'),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: weather != null ? AppColors.textPrimary : AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          WeatherService.locationName,
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // ── 2. Pendingin Ruangan ──
            AcDialCard(
              currentTemp: sensors?.temperature,
              targetTemp: devices?.targetTemperature,
              isOn: devices?.coolingOn,
              isAutoMode: devices?.coolingAutoMode ?? true,
              peltierPwm: devices?.peltierPwm,
              readOnly: true,
              onTapToControl: () => MainNavigation.switchTo(context, 1),
              onToggle: devices?.coolingOn != null
                  ? (val) => _quickToggle('cooling', val)
                  : null,
            ),
            const SizedBox(height: 18),

            // ── 3. Solenoid Door Lock Card & Status Pintu ──
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
                      size: 20,
                      color: isDoorBusy
                          ? AppColors.activeBlue
                          : (doorLocked == null
                              ? AppColors.textMuted
                              : (doorLocked ? AppColors.normal : AppColors.warning)),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Kunci Pintu Depan',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          transitionBuilder: (child, anim) =>
                              FadeTransition(opacity: anim, child: child),
                          child: Text(
                            doorStatusLabel,
                            key: ValueKey('door_status_$doorStatusLabel'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: doorStatusColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: motionDetected == true
                                ? AppColors.normal.withAlpha(30)
                                : AppColors.neuBase,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: motionDetected == true
                                  ? AppColors.normal.withAlpha(80)
                                  : AppColors.border,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                motionDetected == true
                                    ? Icons.videocam
                                    : Icons.videocam_outlined,
                                size: 11,
                                color: motionDetected == true
                                    ? AppColors.normal
                                    : AppColors.textMuted,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                motionDetected == null
                                    ? 'Teras: Tidak Terdeteksi'
                                    : (motionDetected ? 'Teras: Gerakan!' : 'Teras: Sepi'),
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                  color: motionDetected == true
                                      ? AppColors.normal
                                      : (motionDetected == null
                                          ? AppColors.textMuted
                                          : AppColors.textSecondary),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  DoorLockToggle(
                    isLocked: doorLocked,
                    isLoading: isDoorBusy,
                    onChanged: (devices == null || isDoorBusy)
                        ? null
                        : (newLockState) => _quickToggle('door_lock', newLockState),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // ── 4. Quick Shortcuts & Monitoring Grid (2x2) ──
            Row(
              children: [
                // Quick Card 1: Lampu Teras
                Expanded(
                  child: NeuBox(
                    onTap: lightOn != null ? () => _quickToggle('light', !lightOn) : null,
                    padding: const EdgeInsets.all(14),
                    borderRadius: BorderRadius.circular(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            NeuBox(
                              isPressed: lightOn == true,
                              shape: BoxShape.circle,
                              padding: const EdgeInsets.all(8),
                              child: Icon(
                                Icons.lightbulb_outline,
                                size: 16,
                                color: lightOn == true
                                    ? AppColors.activeBlue
                                    : AppColors.textMuted,
                              ),
                            ),
                            Text(
                              lightOn == null ? '--' : (lightOn ? 'ON' : 'OFF'),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: lightOn == true
                                    ? AppColors.textPrimary
                                    : AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Lampu Teras',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          lightOn == null
                              ? 'Tidak Terdeteksi'
                              : (devices!.lightAutoMode
                                  ? (sensors == null ||
                                          (sensors.motionDetected == null &&
                                              sensors.lightIntensity == null)
                                      ? 'Auto: Sensor Tidak Terdeteksi'
                                      : (motionDetected == true
                                          ? 'Gerakan: ON'
                                          : (sensors.isDark ? 'Gelap: ON' : 'LDR Standby')))
                                  : (lightOn ? 'Menyala Manual' : 'Mati')),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            color: lightOn == null
                                ? AppColors.textMuted
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Quick Card 2: Atap Kanopi
                Expanded(
                  child: NeuBox(
                    onTap: roofOpen != null ? () => _quickToggle('roof', !roofOpen) : null,
                    padding: const EdgeInsets.all(14),
                    borderRadius: BorderRadius.circular(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            NeuBox(
                              isPressed: roofOpen == true,
                              shape: BoxShape.circle,
                              padding: const EdgeInsets.all(8),
                              child: Icon(
                                roofOpen == false ? Icons.umbrella : Icons.roofing,
                                size: 16,
                                color: roofOpen == null
                                    ? AppColors.textMuted
                                    : (roofOpen ? AppColors.warning : AppColors.activeBlue),
                              ),
                            ),
                            Text(
                              roofOpen == null ? '--' : (roofOpen ? 'BUKA' : 'TUTUP'),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: roofOpen == null
                                    ? AppColors.textMuted
                                    : (roofOpen ? AppColors.warning : AppColors.textPrimary),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Atap Rumah',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          roofOpen == null && rainDetected == null
                              ? 'Tidak Terdeteksi'
                              : (rainDetected == null
                                  ? 'Sensor Hujan: Tidak Terdeteksi'
                                  : (rainDetected
                                      ? 'Hujan Terdeteksi'
                                      : (devices?.roofAutoMode == true
                                          ? 'Otomatis: Cerah'
                                          : 'Mode Manual'))),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            color: rainDetected == true
                                ? AppColors.activeBlue
                                : (roofOpen == null && rainDetected == null
                                    ? AppColors.textMuted
                                    : AppColors.textSecondary),
                            fontWeight: rainDetected == true ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            Row(
              children: [
                // Quick Card 3: Gas MQ-2
                Expanded(
                  child: NeuBox(
                    onTap: () => MainNavigation.switchTo(context, 1),
                    padding: const EdgeInsets.all(14),
                    borderRadius: BorderRadius.circular(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            NeuBox(
                              isPressed: true,
                              shape: BoxShape.circle,
                              padding: const EdgeInsets.all(8),
                              child: Icon(
                                Icons.gas_meter_outlined,
                                size: 16,
                                color: gasPpm == null
                                    ? AppColors.textMuted
                                    : (sensors!.isGasDanger
                                        ? AppColors.danger
                                        : (sensors.isGasWarning
                                            ? AppColors.warning
                                            : AppColors.normal)),
                              ),
                            ),
                            Icon(
                              Icons.circle,
                              size: 8,
                              color: gasPpm == null
                                  ? AppColors.textMuted
                                  : (sensors!.isGasDanger
                                      ? AppColors.danger
                                      : (sensors.isGasWarning
                                          ? AppColors.warning
                                          : AppColors.normal)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Sensor Gas MQ-2',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          gasPpm == null
                              ? 'Tidak Terdeteksi'
                              : '${gasPpm.toStringAsFixed(0)} PPM • ${sensors!.isGasDanger ? "BAHAYA" : (sensors.isGasWarning ? "Waspada" : "Normal")}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: gasPpm == null
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
                  ),
                ),
                const SizedBox(width: 14),

                // Quick Card 4: Deteksi Api (Flame)
                Expanded(
                  child: NeuBox(
                    onTap: () => MainNavigation.switchTo(context, 1),
                    padding: const EdgeInsets.all(14),
                    borderRadius: BorderRadius.circular(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            NeuBox(
                              isPressed: flameDetected == true,
                              shape: BoxShape.circle,
                              padding: const EdgeInsets.all(8),
                              child: Icon(
                                flameDetected == true
                                    ? Icons.local_fire_department
                                    : Icons.shield_outlined,
                                size: 16,
                                color: flameDetected == null
                                    ? AppColors.textMuted
                                    : (flameDetected ? AppColors.danger : AppColors.normal),
                              ),
                            ),
                            Icon(
                              Icons.circle,
                              size: 8,
                              color: flameDetected == null
                                  ? AppColors.textMuted
                                  : (flameDetected ? AppColors.danger : AppColors.normal),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Deteksi Api',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          flameDetected == null
                              ? 'Tidak Terdeteksi'
                              : (flameDetected
                                  ? 'API TERDETEKSI!'
                                  : (devices?.buzzerOn == true
                                      ? 'Buzzer Aktif'
                                      : 'Aman & Terkendali')),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: flameDetected == null
                                ? AppColors.textMuted
                                : (flameDetected ? AppColors.danger : AppColors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // ── 5. Shortcut Navigasi ke Halaman Kontrol Lengkap ──
            NeuBox(
              onTap: () => MainNavigation.switchTo(context, 1),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              borderRadius: BorderRadius.circular(20),
              child: const Row(
                children: [
                  Icon(Icons.tune, size: 18, color: AppColors.textPrimary),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pusat Kontrol Perangkat',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Atur target suhu, otomatisasi atap, & parameter detail',
                          style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, size: 13, color: AppColors.textSecondary),
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
