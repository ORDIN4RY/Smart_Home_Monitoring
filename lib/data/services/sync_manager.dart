import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/config/api_config.dart';
import '../models/device_status.dart';
import '../models/sensor_reading.dart';
import 'home_service.dart';
import 'mock_data_generator.dart';
import 'server_connection_manager.dart';

enum SyncStatus {
  syncing,
  synced,
  offline,
  mock,
  error,
}

class SyncManager {
  static const String _keyDeviceStatus = 'smarthome_device_status';
  static const String _keySensorReading = 'smarthome_sensor_reading';
  static const String _keyPendingSettings = 'smarthome_pending_settings';
  static const String _keyLastSyncTime = 'smarthome_last_sync_time';

  // ── Reactive Notifiers (Single Source of Truth) ──
  static final ValueNotifier<SyncStatus> syncStatus =
      ValueNotifier<SyncStatus>(SyncStatus.syncing);

  static final ValueNotifier<DateTime?> lastSyncTime =
      ValueNotifier<DateTime?>(null);

  static final ValueNotifier<DeviceStatus> currentDeviceStatus =
      ValueNotifier<DeviceStatus>(
    DeviceStatus(lastUpdated: DateTime.now()),
  );

  static final ValueNotifier<SensorReading> currentSensors =
      ValueNotifier<SensorReading>(
    SensorReading(
      temperature: 24.0,
      humidity: 50.0,
      lightIntensity: 50.0,
      gasPpm: 0.0,
      flameDetected: false,
      motionDetected: false,
      doorOpen: false,
      timestamp: DateTime.now(),
    ),
  );

  static final ValueNotifier<int> pendingChangesCount =
      ValueNotifier<int>(0);

  static Timer? _syncTimer;
  static bool _isSyncing = false;
  static SharedPreferences? _prefs;

  /// Inisialisasi local storage & load data lokal pertama kali (offline-first)
  static Future<void> initialize() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      await _loadFromLocalStorage();
    } catch (e) {
      debugPrint('[SyncManager] Gagal memuat local storage: $e');
    }

    // Pantau perubahan koneksi dari ServerConnectionManager
    ServerConnectionManager.status.addListener(_onServerConnectionChanged);

    // Jalankan timer sinkronisasi berkala (tiap 5 detik)
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      syncAll(silent: true);
    });
  }

  static void dispose() {
    _syncTimer?.cancel();
    ServerConnectionManager.status.removeListener(_onServerConnectionChanged);
  }

  static void _onServerConnectionChanged() {
    final connState = ServerConnectionManager.status.value;
    if (connState == ServerConnectionState.disconnected &&
        syncStatus.value != SyncStatus.offline) {
      syncStatus.value = SyncStatus.offline;
    } else if (connState == ServerConnectionState.mockMode) {
      syncStatus.value = SyncStatus.mock;
    } else if (connState == ServerConnectionState.connected &&
        syncStatus.value == SyncStatus.offline) {
      syncAll(silent: true);
    }
  }

  /// Memuat data dari local SharedPreferences ke dalam memori aplikasi
  static Future<void> _loadFromLocalStorage() async {
    if (_prefs == null) return;

    try {
      // 1. Muat DeviceStatus lokal
      final devJsonStr = _prefs!.getString(_keyDeviceStatus);
      if (devJsonStr != null && devJsonStr.isNotEmpty) {
        final Map<String, dynamic> devMap = jsonDecode(devJsonStr);
        currentDeviceStatus.value = DeviceStatus.fromJson(devMap);
      }

      // 2. Muat SensorReading lokal
      final sensJsonStr = _prefs!.getString(_keySensorReading);
      if (sensJsonStr != null && sensJsonStr.isNotEmpty) {
        final Map<String, dynamic> sensMap = jsonDecode(sensJsonStr);
        currentSensors.value = SensorReading.fromJson(sensMap);
      }

      // 3. Muat Pending Settings
      final pendingMap = _getPendingSettingsMap();
      pendingChangesCount.value = pendingMap.length;

      // 4. Muat Waktu Sinkronisasi Terakhir
      final lastSyncStr = _prefs!.getString(_keyLastSyncTime);
      if (lastSyncStr != null && lastSyncStr.isNotEmpty) {
        lastSyncTime.value = DateTime.tryParse(lastSyncStr);
      }
    } catch (e) {
      debugPrint('[SyncManager] Error parsing local storage: $e');
    }
  }

  static Map<String, dynamic> _getPendingSettingsMap() {
    if (_prefs == null) return {};
    final raw = _prefs!.getString(_keyPendingSettings);
    if (raw == null || raw.isEmpty) return {};
    try {
      return Map<String, dynamic>.from(jsonDecode(raw));
    } catch (_) {
      return {};
    }
  }

  static Future<void> _savePendingSettingsMap(Map<String, dynamic> map) async {
    if (_prefs == null) return;
    await _prefs!.setString(_keyPendingSettings, jsonEncode(map));
    pendingChangesCount.value = map.length;
  }

  /// Simpan status perangkat saat ini ke local storage
  static Future<void> _saveDeviceStatusLocal(DeviceStatus status) async {
    if (_prefs == null) return;
    try {
      await _prefs!.setString(_keyDeviceStatus, jsonEncode(status.toJson()));
    } catch (e) {
      debugPrint('[SyncManager] Gagal simpan DeviceStatus ke local: $e');
    }
  }

  /// Simpan nilai sensor saat ini ke local storage
  static Future<void> _saveSensorsLocal(SensorReading sensors) async {
    if (_prefs == null) return;
    try {
      await _prefs!.setString(_keySensorReading, jsonEncode(sensors.toJson()));
    } catch (e) {
      debugPrint('[SyncManager] Gagal simpan SensorReading ke local: $e');
    }
  }

  /// Update pengaturan perangkat secara lokal terlebih dahulu (optimistic update),
  /// lalu secara otomatis disinkronkan ke server bila terhubung.
  static Future<void> updateDeviceSetting(
    String deviceKey,
    dynamic value, {
    bool syncImmediately = true,
  }) async {
    // 1. Terapkan perubahan ke state lokal (Single Source of Truth)
    final current = currentDeviceStatus.value;
    DeviceStatus updated = current;

    switch (deviceKey) {
      case 'cooling':
        updated = current.copyWith(coolingOn: value as bool);
        break;
      case 'target_temp':
        updated = current.copyWith(targetTemperature: (value as num).toDouble());
        break;
      case 'cooling_auto_mode':
        updated = current.copyWith(coolingAutoMode: value as bool);
        break;
      case 'roof':
        updated = current.copyWith(roofOpen: value as bool);
        break;
      case 'roof_auto_mode':
        updated = current.copyWith(roofAutoMode: value as bool);
        break;
      case 'light':
        updated = current.copyWith(lightOn: value as bool);
        break;
      case 'light_auto_mode':
        updated = current.copyWith(lightAutoMode: value as bool);
        break;
      case 'buzzer':
        updated = current.copyWith(buzzerOn: value as bool);
        break;
      case 'door_lock':
        updated = current.copyWith(doorLocked: value as bool);
        break;
    }

    currentDeviceStatus.value = updated;
    await _saveDeviceStatusLocal(updated);

    // 2. Tandai perubahan ini di pending settings (untuk dikirim ke server)
    final pending = _getPendingSettingsMap();
    pending[deviceKey] = value;
    await _savePendingSettingsMap(pending);

    // 3. Jika diminta sinkron segera, lakukan push ke server
    if (syncImmediately) {
      unawaited(syncAll(silent: true));
    }
  }

  /// Simpan batch pengaturan (misal dari form atau dialog pengaturan sekaligus)
  static Future<void> updateMultipleSettings(Map<String, dynamic> settings) async {
    for (final entry in settings.entries) {
      await updateDeviceSetting(entry.key, entry.value, syncImmediately: false);
    }
    await syncAll(silent: false);
  }

  /// Sinkronisasi penuh antara Local Storage dan Server Backend:
  /// - Sensor: disamakan dengan server (Server is authoritative for sensor telemetry).
  /// - Setting: disamakan dengan local jika ada perubahan lokal (Local is authoritative for pending user intents),
  ///   kemudian dikirim ke server. Jika tidak ada perubahan lokal, ambil dari server.
  static Future<bool> syncAll({bool silent = false}) async {
    if (_isSyncing) return false;
    _isSyncing = true;

    if (!silent) {
      syncStatus.value = SyncStatus.syncing;
    }

    try {
      // Periksa apakah mode mock aktif
      if (ApiConfig.useMockData) {
        final mockSensors = MockDataGenerator.tickSensorData();

        currentSensors.value = mockSensors;
        await _saveSensorsLocal(mockSensors);

        // Jika ada pending setting, aplikasikan ke mock
        final pending = _getPendingSettingsMap();
        if (pending.isNotEmpty) {
          for (final entry in pending.entries) {
            MockDataGenerator.updateDevice(entry.key, entry.value);
          }
          await _savePendingSettingsMap({});
        }

        currentDeviceStatus.value = MockDataGenerator.deviceStatus;
        await _saveDeviceStatusLocal(MockDataGenerator.deviceStatus);

        lastSyncTime.value = DateTime.now();
        if (_prefs != null) {
          await _prefs!.setString(_keyLastSyncTime, DateTime.now().toIso8601String());
        }

        syncStatus.value = SyncStatus.mock;
        _isSyncing = false;
        return true;
      }

      // Cek konektivitas ke server
      final isOnline = await ServerConnectionManager.checkConnection();
      if (!isOnline) {
        syncStatus.value = SyncStatus.offline;
        _isSyncing = false;
        return false;
      }

      // ── Step 1: Push Pending Local Settings ke Server ──
      final pending = _getPendingSettingsMap();
      if (pending.isNotEmpty) {
        final sentKeys = <String>[];
        for (final entry in pending.entries) {
          try {
            await HomeService.controlDevice(entry.key, entry.value);
            sentKeys.add(entry.key);
          } catch (e) {
            debugPrint('[SyncManager] Gagal push setting ${entry.key}: $e');
            // Biarkan di antrian pending jika gagal kirim
          }
        }
        for (final k in sentKeys) {
          pending.remove(k);
        }
        await _savePendingSettingsMap(pending);
      }

      // ── Step 2: Sinkronisasi Sensor (Authoritative: Server) ──
      try {
        final serverSensors = await HomeService.fetchCurrentSensors();
        currentSensors.value = serverSensors;
        await _saveSensorsLocal(serverSensors);
      } catch (e) {
        debugPrint('[SyncManager] Gagal fetch sensor: $e');
      }

      // ── Step 3: Sinkronisasi Device Settings ──
      // Jika masih ada pending setting lokal, pertahankan local status.
      // Jika tidak ada pending, perbarui dari respons server.
      if (pending.isEmpty) {
        try {
          final serverDevices = await HomeService.fetchDeviceStatus();
          currentDeviceStatus.value = serverDevices;
          await _saveDeviceStatusLocal(serverDevices);
        } catch (e) {
          debugPrint('[SyncManager] Gagal fetch device status: $e');
        }
      }

      // ── Step 4: Catat Waktu Sinkronisasi Sukses ──
      final now = DateTime.now();
      lastSyncTime.value = now;
      if (_prefs != null) {
        await _prefs!.setString(_keyLastSyncTime, now.toIso8601String());
      }

      syncStatus.value = SyncStatus.synced;
      _isSyncing = false;
      return true;
    } catch (e) {
      debugPrint('[SyncManager] Error saat sinkronisasi: $e');
      syncStatus.value = SyncStatus.error;
      _isSyncing = false;
      return false;
    }
  }
}
