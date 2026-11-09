import 'dart:convert';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import '../../core/config/api_config.dart';
import '../models/sensor_reading.dart';
import '../models/device_status.dart';
import '../models/event_log.dart';
import '../models/face_model.dart';
import 'api_client.dart';
import 'mock_data_generator.dart';

class HomeService {
  /// Fetch current real-time sensor metrics
  static Future<SensorReading> fetchCurrentSensors() async {
    if (ApiConfig.useMockData) {
      return MockDataGenerator.tickSensorData();
    }

    try {
      final response = await ApiClient.get(ApiConfig.currentSensorsUrl);
      if (response is Map<String, dynamic>) {
        return SensorReading.fromJson(response['data'] ?? response);
      }
      return MockDataGenerator.tickSensorData();
    } catch (_) {
      return MockDataGenerator.tickSensorData();
    }
  }

  /// Fetch historic sensor telemetry
  static Future<List<SensorReading>> fetchSensorHistory() async {
    if (ApiConfig.useMockData) {
      return MockDataGenerator.getMockHistory();
    }

    try {
      final response = await ApiClient.get(ApiConfig.sensorHistoryUrl);
      if (response is List) {
        return response
            .map((item) => SensorReading.fromJson(item as Map<String, dynamic>))
            .toList();
      } else if (response is Map && response['history'] is List) {
        return (response['history'] as List)
            .map((item) => SensorReading.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return MockDataGenerator.getMockHistory();
    } catch (_) {
      return MockDataGenerator.getMockHistory();
    }
  }

  /// Fetch current devices status (light, cooling, door lock)
  static Future<DeviceStatus> fetchDeviceStatus() async {
    if (ApiConfig.useMockData) {
      return MockDataGenerator.deviceStatus;
    }

    try {
      final response = await ApiClient.get(ApiConfig.deviceStatusUrl);
      if (response is Map<String, dynamic>) {
        return DeviceStatus.fromJson(response['status'] ?? response);
      }
      return MockDataGenerator.deviceStatus;
    } catch (_) {
      return MockDataGenerator.deviceStatus;
    }
  }

  /// Send device control command to backend Flask API
  static Future<DeviceStatus> controlDevice(String deviceKey, dynamic value) async {
    if (ApiConfig.useMockData) {
      return MockDataGenerator.updateDevice(deviceKey, value);
    }

    try {
      final response = await ApiClient.post(
        ApiConfig.controlDeviceUrl,
        {
          'device': deviceKey,
          'value': value,
        },
      );

      if (response is Map<String, dynamic>) {
        return DeviceStatus.fromJson(response['status'] ?? response);
      }
      return MockDataGenerator.updateDevice(deviceKey, value);
    } catch (_) {
      return MockDataGenerator.updateDevice(deviceKey, value);
    }
  }

  /// Fetch important system event logs
  static Future<List<EventLog>> fetchEventLogs() async {
    if (ApiConfig.useMockData) {
      return List.from(MockDataGenerator.eventLogs);
    }

    try {
      final response = await ApiClient.get(ApiConfig.eventsUrl);
      if (response is List) {
        return response
            .map((item) => EventLog.fromJson(item as Map<String, dynamic>))
            .toList();
      } else if (response is Map && response['events'] is List) {
        return (response['events'] as List)
            .map((item) => EventLog.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return List.from(MockDataGenerator.eventLogs);
    } catch (_) {
      return List.from(MockDataGenerator.eventLogs);
    }
  }

  // ── Face Recognition (Flask Backend) ─────────────────────────────────

  /// GET /api/faces — daftar wajah terdaftar
  static Future<List<RegisteredFace>> fetchRegisteredFaces() async {
    if (ApiConfig.useMockData) {
      return List.from(MockDataGenerator.registeredFaces);
    }

    try {
      final response = await ApiClient.get(ApiConfig.facesUrl);
      // Flask response: {"wajah": [...], "total": 3}
      if (response is Map && response['wajah'] is List) {
        return (response['wajah'] as List)
            .map((item) => RegisteredFace.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      // Fallback jika response langsung List
      if (response is List) {
        return response
            .map((item) => RegisteredFace.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (_) {
      return List.from(MockDataGenerator.registeredFaces);
    }
  }

  /// POST /api/enroll/photo — daftarkan wajah dari foto file
  /// [name]     — nama orang
  /// [role]     — peran (Pemilik, Keluarga, dsb.)
  /// [filePath] — path file foto dari image_picker
  static Future<RegisteredFace> registerNewFace(
    String name,
    String role, {
    String? filePath,
  }) async {
    if (ApiConfig.useMockData) {
      return MockDataGenerator.registerFace(name, role);
    }

    // Jika ada foto, kirim sebagai multipart
    if (filePath != null && filePath.isNotEmpty) {
      try {
        final response = await ApiClient.postMultipart(
          ApiConfig.enrollPhotoUrl,
          fields: {'nama': name, 'role': role},
          filePath: filePath,
          fileField: 'photo',
        );
        // Flask response: {"nama": "Faris", "jumlah_frame": 1, "pesan": "..."}
        if (response is Map<String, dynamic>) {
          return RegisteredFace(
            id: response['nama']?.toString() ?? name,
            name: response['nama']?.toString() ?? name,
            role: role,
            registeredAt: DateTime.now(),
            jumlahFrame: response['jumlah_frame'] as int? ?? 1,
          );
        }
      } catch (_) {
        return MockDataGenerator.registerFace(name, role);
      }
    }

    // Fallback: enroll via kamera live (jika backend punya kamera)
    try {
      final response = await ApiClient.post(
        '${ApiConfig.baseUrl}/api/enroll',
        {'nama': name},
      );
      if (response is Map<String, dynamic>) {
        return RegisteredFace(
          id: response['nama']?.toString() ?? name,
          name: response['nama']?.toString() ?? name,
          role: role,
          registeredAt: DateTime.now(),
          jumlahFrame: response['jumlah_frame'] as int? ?? 1,
        );
      }
    } catch (_) {}
    return MockDataGenerator.registerFace(name, role);
  }

  /// DELETE /api/faces/{nama} — hapus wajah
  static Future<void> deleteFace(String id) async {
    if (ApiConfig.useMockData) {
      MockDataGenerator.deleteFace(id);
      return;
    }
    try {
      // id di sini adalah nama (Flask pakai nama sebagai identifier)
      await ApiClient.delete(ApiConfig.faceDeleteUrl(id));
    } catch (_) {
      MockDataGenerator.deleteFace(id);
    }
  }

  /// POST /api/recognize — kenali wajah dari foto upload
  /// Kembalikan AccessAttempt dari hasil recognition Flask
  static Future<AccessAttempt> recognizeFace(String filePath) async {
    if (ApiConfig.useMockData) {
      return MockDataGenerator.accessAttempts.first;
    }
    final response = await ApiClient.postMultipart(
      ApiConfig.recognizeUrl,
      filePath: filePath,
      fileField: 'photo',
    );
    if (response is Map<String, dynamic>) {
      return AccessAttempt.fromJson(response);
    }
    throw ApiException('Format respons recognize tidak dikenali.');
  }

  /// POST /api/recognize — khusus untuk pengujian kamera realtime (Web, Mobile, Desktop)
  /// Mengukur latency (ms), menangani status 200, 403 (spoof), 404 (tidak ada wajah) secara mulus
  static Future<AccessAttempt> testRecognizeRealtime(dynamic fileOrPath) async {
    final stopwatch = Stopwatch()..start();
    try {
      final request = http.MultipartRequest('POST', Uri.parse(ApiConfig.recognizeUrl));
      request.headers.addAll({'Accept': 'application/json'});
      final List<int> bytes = fileOrPath is XFile
          ? await fileOrPath.readAsBytes()
          : (fileOrPath is List<int>
              ? fileOrPath
              : await XFile(fileOrPath.toString()).readAsBytes());
      request.files.add(http.MultipartFile.fromBytes('photo', bytes, filename: 'frame.jpg'));

      final streamed = await request.send().timeout(const Duration(seconds: 5));
      final response = await http.Response.fromStream(streamed);
      stopwatch.stop();
      final latency = stopwatch.elapsedMilliseconds;

      dynamic body;
      try {
        body = jsonDecode(response.body);
      } catch (_) {
        body = {};
      }

      if (body is Map<String, dynamic>) {
        if (response.statusCode == 404) {
          return AccessAttempt(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            matchedName: null,
            isLivenessPassed: false,
            livenessScore: 0.0,
            isAuthorized: false,
            message: body['error']?.toString() ?? 'Wajah tidak terdeteksi',
            timestamp: DateTime.now(),
            latencyMs: latency,
          );
        }
        return AccessAttempt.fromJson(body, latency: latency);
      }
      return AccessAttempt(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        matchedName: null,
        isLivenessPassed: false,
        livenessScore: 0.0,
        isAuthorized: false,
        message: 'Respons tidak valid (${response.statusCode})',
        timestamp: DateTime.now(),
        latencyMs: latency,
      );
    } catch (e) {
      stopwatch.stop();
      return AccessAttempt(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        matchedName: null,
        isLivenessPassed: false,
        livenessScore: 0.0,
        isAuthorized: false,
        message: 'Koneksi: $e',
        timestamp: DateTime.now(),
        latencyMs: stopwatch.elapsedMilliseconds,
      );
    }
  }

  /// GET /api/status — hasil recognition terakhir dari worker kamera backend
  static Future<AccessAttempt> fetchLastRecognitionStatus() async {
    if (ApiConfig.useMockData) {
      return MockDataGenerator.accessAttempts.first;
    }
    final response = await ApiClient.get(ApiConfig.statusUrl);
    if (response is Map<String, dynamic>) {
      return AccessAttempt.fromJson(response);
    }
    throw ApiException('Format respons status tidak dikenali.');
  }

  /// GET /api/faces/attempts — riwayat akses pintu (endpoint opsional, mock jika tidak ada)
  static Future<List<AccessAttempt>> fetchAccessAttempts() async {
    if (ApiConfig.useMockData) {
      return List.from(MockDataGenerator.accessAttempts);
    }
    try {
      // Coba GET /api/status untuk status terakhir jika tidak ada endpoint attempts
      final snap = await fetchLastRecognitionStatus();
      return [snap];
    } catch (_) {
      return List.from(MockDataGenerator.accessAttempts);
    }
  }
}
