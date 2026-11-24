import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../core/config/api_config.dart';

enum ServerConnectionState {
  connected,
  disconnected,
  checking,
  mockMode,
}

class ServerConnectionManager {
  static final ValueNotifier<ServerConnectionState> status =
      ValueNotifier<ServerConnectionState>(ServerConnectionState.checking);

  static final ValueNotifier<String> currentBaseUrl =
      ValueNotifier<String>(ApiConfig.baseUrl);

  static Timer? _periodicTimer;
  static bool _isCheckingNow = false;

  /// Inisialisasi polling berkala untuk memantau konektivitas server backend Flask
  static void initialize() {
    currentBaseUrl.value = ApiConfig.baseUrl;
    checkConnection();
    _periodicTimer?.cancel();
    _periodicTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      checkConnection();
    });
  }

  static void dispose() {
    _periodicTimer?.cancel();
  }

  /// Cek koneksi langsung ke backend Flask (/api/health atau /api/devices/status)
  static Future<bool> checkConnection() async {
    if (_isCheckingNow) return status.value == ServerConnectionState.connected;
    _isCheckingNow = true;

    currentBaseUrl.value = ApiConfig.baseUrl;

    if (ApiConfig.useMockData) {
      status.value = ServerConnectionState.mockMode;
      _isCheckingNow = false;
      return true;
    }

    try {
      final healthUri = Uri.parse(ApiConfig.healthUrl);
      final res = await http.get(healthUri).timeout(const Duration(seconds: 3));
      if (res.statusCode >= 200 && res.statusCode < 400) {
        status.value = ServerConnectionState.connected;
        _isCheckingNow = false;
        return true;
      }
    } catch (_) {
      // Coba fallback cek status endpoint
      try {
        final statusUri = Uri.parse(ApiConfig.deviceStatusUrl);
        final res2 = await http.get(statusUri).timeout(const Duration(seconds: 3));
        if (res2.statusCode >= 200 && res2.statusCode < 400) {
          status.value = ServerConnectionState.connected;
          _isCheckingNow = false;
          return true;
        }
      } catch (_) {
        // Gagal terhubung
      }
    }

    status.value = ServerConnectionState.disconnected;
    _isCheckingNow = false;
    return false;
  }

  /// Memperbarui status secara langsung (misal saat request dari ApiClient berhasil / gagal)
  static void setConnected(bool isOnline) {
    if (ApiConfig.useMockData) {
      status.value = ServerConnectionState.mockMode;
      return;
    }
    status.value = isOnline
        ? ServerConnectionState.connected
        : ServerConnectionState.disconnected;
  }
}
