import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/config/api_config.dart';
import '../models/device_status.dart';
import '../models/sensor_reading.dart';
import 'api_client.dart';
import 'home_service.dart';
import 'mock_data_generator.dart';
import 'mqtt_service.dart';
import 'server_connection_manager.dart';

enum SyncStatus {
  syncing,
  synced,
  offline,
  mock,
  error,
}

class SyncManager {
  static const String _keyPendingSettings = 'homatix_pending_settings';
  static const String _keyLastSyncTime = 'homatix_last_sync_time';

  // ── Reactive Notifiers (Single Source of Truth) ──
  // Mulai sebagai null ("Tidak Terdeteksi") hingga data aktual diterima dari server/MQTT
  static final ValueNotifier<SyncStatus> syncStatus =
      ValueNotifier<SyncStatus>(SyncStatus.syncing);

  static final ValueNotifier<DateTime?> lastSyncTime =
      ValueNotifier<DateTime?>(null);

  static final ValueNotifier<DeviceStatus?> currentDeviceStatus =
      ValueNotifier<DeviceStatus?>(null);

  static final ValueNotifier<SensorReading?> currentSensors =
      ValueNotifier<SensorReading?>(null);

  static final ValueNotifier<int> pendingChangesCount =
      ValueNotifier<int>(0);

  static Timer? _syncTimer;
  static bool _isSyncing = false;
  static SharedPreferences? _prefs;

  /// Inisialisasi local storage & sinkronisasi berkala
  static Future<void> initialize() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      await _loadFromLocalStorage();
    } catch (e) {
      debugPrint('[SyncManager] Gagal memuat local storage: $e');
    }

    ServerConnectionManager.status.addListener(_onServerConnectionChanged);

    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      syncAll(silent: true);
    });

    unawaited(MqttService.initialize());
  }

  /// Terapkan update sensor realtime dari MQTT tanpa menunggu polling HTTP
  static void applyRealtimeSensors(SensorReading reading) {
    currentSensors.value = reading;
    lastSyncTime.value = DateTime.now();
    syncStatus.value = SyncStatus.synced;
  }

  /// Terapkan update status perangkat realtime dari MQTT
  static void applyRealtimeDeviceStatus(DeviceStatus status) {
    if (pendingChangesCount.value == 0) {
      currentDeviceStatus.value = status;
    }
  }

  static void dispose() {
    _syncTimer?.cancel();
    ServerConnectionManager.status.removeListener(_onServerConnectionChanged);
  }

  static void _onServerConnectionChanged() {
    final connState = ServerConnectionManager.status.value;
    if (connState == ServerConnectionState.disconnected) {
      if (syncStatus.value != SyncStatus.offline) {
        syncStatus.value = SyncStatus.offline;
      }
      // Jangan tampilkan nilai dummy/basi saat server terputus
      if (!ApiConfig.useMockData) {
        currentSensors.value = null;
        if (pendingChangesCount.value == 0) {
          currentDeviceStatus.value = null;
        }
      }
    } else if (connState == ServerConnectionState.mockMode) {
      syncStatus.value = SyncStatus.mock;
    } else if (connState == ServerConnectionState.connected &&
        syncStatus.value == SyncStatus.offline) {
      syncAll(silent: true);
    }
  }

  static Future<void> _loadFromLocalStorage() async {
    if (_prefs == null) return;
    try {
      final pendingMap = _getPendingSettingsMap();
      pendingChangesCount.value = pendingMap.length;

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

  /// Update pengaturan perangkat dan sinkronkan ke server
  static Future<void> updateDeviceSetting(
    String deviceKey,
    dynamic value, {
    bool syncImmediately = true,
  }) async {
    final current = currentDeviceStatus.value ??
        DeviceStatus(lastUpdated: DateTime.now());
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
        // Untuk pintu: tandai transisi sambil menunggu konfirmasi Wemos
        updated = current.copyWith(
          doorTransition: (value as bool) ? 'closing' : 'opening',
        );
        break;
    }

    currentDeviceStatus.value = updated;

    final pending = _getPendingSettingsMap();
    pending[deviceKey] = value;
    await _savePendingSettingsMap(pending);

    if (syncImmediately) {
      await syncAll(silent: true);
    }
  }

  static Future<void> updateMultipleSettings(Map<String, dynamic> settings) async {
    for (final entry in settings.entries) {
      await updateDeviceSetting(entry.key, entry.value, syncImmediately: false);
    }
    await syncAll(silent: false);
  }

  /// Sinkronisasi antara perangkat dan server backend
  static Future<bool> syncAll({bool silent = false}) async {
    if (_isSyncing) return false;
    _isSyncing = true;

    if (!silent) {
      syncStatus.value = SyncStatus.syncing;
    }

    try {
      if (ApiConfig.useMockData) {
        final mockSensors = MockDataGenerator.tickSensorData();
        currentSensors.value = mockSensors;

        final pending = _getPendingSettingsMap();
        if (pending.isNotEmpty) {
          for (final entry in pending.entries) {
            MockDataGenerator.updateDevice(entry.key, entry.value);
          }
          await _savePendingSettingsMap({});
        }

        currentDeviceStatus.value = MockDataGenerator.deviceStatus;

        lastSyncTime.value = DateTime.now();
        if (_prefs != null) {
          await _prefs!.setString(_keyLastSyncTime, DateTime.now().toIso8601String());
        }

        syncStatus.value = SyncStatus.mock;
        _isSyncing = false;
        return true;
      }

      final isOnline = await ServerConnectionManager.checkConnection();
      if (!isOnline) {
        syncStatus.value = SyncStatus.offline;
        currentSensors.value = null;
        if (pendingChangesCount.value == 0) {
          currentDeviceStatus.value = null;
        }
        _isSyncing = false;
        return false;
      }

      // ── Step 1: Push Pending Local Settings ke Server ──
      final pending = _getPendingSettingsMap();
      if (pending.isNotEmpty) {
        final sentKeys = <String>[];
        for (final entry in pending.entries) {
          try {
            final resStatus = await HomeService.controlDevice(entry.key, entry.value);
            currentDeviceStatus.value = resStatus;
            sentKeys.add(entry.key);
          } on ApiException catch (e) {
            debugPrint('[SyncManager] Tolak/gagal push setting ${entry.key}: ${e.message}');
            if (e.statusCode == 400 || e.statusCode == 409) {
              // Jangan ulang terus-menerus jika ditolak (mis. pintu sedang sibuk)
              sentKeys.add(entry.key);
            }
          } catch (e) {
            debugPrint('[SyncManager] Gagal push setting ${entry.key}: $e');
          }
        }
        for (final k in sentKeys) {
          pending.remove(k);
        }
        await _savePendingSettingsMap(pending);
      }

      // ── Step 2: Sinkronisasi Sensor (Server Authoritative, null jika belum ada status) ──
      final serverSensors = await HomeService.fetchCurrentSensors();
      currentSensors.value = serverSensors;

      // ── Step 3: Sinkronisasi Device Status ──
      if (pending.isEmpty) {
        final serverDevices = await HomeService.fetchDeviceStatus();
        currentDeviceStatus.value = serverDevices;
      }

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
