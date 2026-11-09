import 'package:flutter/foundation.dart';

class ApiConfig {
  /// Base URL Flask Backend:
  /// - Jika dijalankan di Web / Browser laptop: 'http://127.0.0.1:5000'
  /// - Jika dijalankan di HP fisik via Wi-Fi LAN: 'http://10.10.4.169:5000'
  static String baseUrl = kIsWeb
      ? 'http://127.0.0.1:5000'
      : 'http://10.238.25.157:5000';

  /// Toggle: true = pakai Mock Data (dev/demo), false = live ke Flask
  static bool useMockData = false;

  /// Connection timeout
  static const Duration timeout = Duration(seconds: 10);

  // ── Authentication (tidak dipakai di Flask face recognition backend) ──
  static String get loginUrl => '$baseUrl/api/auth/login';
  static String get logoutUrl => '$baseUrl/api/auth/logout';
  static String get profileUrl => '$baseUrl/api/auth/profile';

  // ── Sensor & Device (dari ESP32 / backend lain) ──────────────────────
  static String get currentSensorsUrl => '$baseUrl/api/sensors/current';
  static String get sensorHistoryUrl => '$baseUrl/api/sensors/history';
  static String get deviceStatusUrl => '$baseUrl/api/devices/status';
  static String get controlDeviceUrl => '$baseUrl/api/devices/control';
  static String get eventsUrl => '$baseUrl/api/events';

  // ── Face Recognition Flask Backend ───────────────────────────────────
  /// GET  /api/faces            — daftar wajah terdaftar
  static String get facesUrl => '$baseUrl/api/faces';

  /// POST /api/enroll/photo     — daftarkan wajah dari foto upload
  static String get enrollPhotoUrl => '$baseUrl/api/enroll/photo';

  /// DELETE /api/faces/<nama>   — hapus wajah
  static String faceDeleteUrl(String nama) => '$baseUrl/api/faces/$nama';

  /// POST /api/recognize        — kenali wajah dari foto upload
  static String get recognizeUrl => '$baseUrl/api/recognize';

  /// GET /api/health            — status semua komponen backend
  static String get healthUrl => '$baseUrl/api/health';

  /// GET /api/status            — hasil recognition terakhir dari kamera
  static String get statusUrl => '$baseUrl/api/status';

  // ── Legacy (kompatibilitas kode lama) ────────────────────────────────
  static String get registerFaceUrl => enrollPhotoUrl;
  static String get accessAttemptsUrl => '$baseUrl/api/faces/attempts';

  /// Update base URL saat runtime (dari Settings screen)
  static void updateBaseUrl(String newUrl) {
    var trimmed = newUrl.trim();
    if (trimmed.endsWith('/'))
      trimmed = trimmed.substring(0, trimmed.length - 1);
    baseUrl = trimmed;
  }
}
