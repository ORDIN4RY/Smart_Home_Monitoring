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
  /// Fetch current real-time sensor metrics (returns null if unavailable / not yet received)
  static Future<SensorReading?> fetchCurrentSensors() async {
    if (ApiConfig.useMockData) {
      return MockDataGenerator.tickSensorData();
    }

    try {
      final response = await ApiClient.get(ApiConfig.currentSensorsUrl);
      if (response is Map<String, dynamic>) {
        final raw = response.containsKey('data') ? response['data'] : response;
        if (raw is Map<String, dynamic>) {
          return SensorReading.fromJson(raw);
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Fetch historic sensor telemetry
  static Future<List<SensorReading>> fetchSensorHistory() async {
    if (ApiConfig.useMockData) {
      return MockDataGenerator.getMockHistory();
    }

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
    return [];
  }

  /// Fetch current devices status (returns null if unavailable)
  static Future<DeviceStatus?> fetchDeviceStatus() async {
    if (ApiConfig.useMockData) {
      return MockDataGenerator.deviceStatus;
    }

    try {
      final response = await ApiClient.get(ApiConfig.deviceStatusUrl);
      if (response is Map<String, dynamic>) {
        final raw = response.containsKey('status') ? response['status'] : response;
        if (raw is Map<String, dynamic>) {
          return DeviceStatus.fromJson(raw);
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Send device control command to backend API
  static Future<DeviceStatus> controlDevice(String deviceKey, dynamic value) async {
    if (ApiConfig.useMockData) {
      return MockDataGenerator.updateDevice(deviceKey, value);
    }

    final response = await ApiClient.post(
      ApiConfig.controlDeviceUrl,
      {
        'device': deviceKey,
        'value': value,
      },
    );

    if (response is Map<String, dynamic>) {
      final raw = response.containsKey('status') ? response['status'] : response;
      if (raw is Map<String, dynamic>) {
        return DeviceStatus.fromJson(raw);
      }
    }
    throw ApiException('Format respons kontrol perangkat tidak dikenali.');
  }

  /// Fetch important system event logs
  static Future<List<EventLog>> fetchEventLogs() async {
    if (ApiConfig.useMockData) {
      return List.from(MockDataGenerator.eventLogs);
    }

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
    return [];
  }

  // ── Face Recognition ─────────────────────────────────────────────────

  /// GET /api/faces — daftar wajah terdaftar
  static Future<List<RegisteredFace>> fetchRegisteredFaces() async {
    if (ApiConfig.useMockData) {
      return List.from(MockDataGenerator.registeredFaces);
    }

    final response = await ApiClient.get(ApiConfig.facesUrl);
    if (response is Map) {
      final list = response['faces'] ?? response['wajah'];
      if (list is List) {
        return list
            .map((item) => RegisteredFace.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    }
    if (response is List) {
      return response
          .map((item) => RegisteredFace.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// POST /api/enroll/photo — daftarkan wajah dari foto file
  static Future<RegisteredFace> registerNewFace(
    String name,
    String role, {
    String? filePath,
  }) async {
    if (ApiConfig.useMockData) {
      return MockDataGenerator.registerFace(name, role);
    }

    if (filePath != null && filePath.isNotEmpty) {
      final response = await ApiClient.postMultipart(
        ApiConfig.enrollPhotoUrl,
        fields: {'nama': name, 'role': role},
        filePath: filePath,
        fileField: 'photo',
      );
      if (response is Map<String, dynamic>) {
        return RegisteredFace(
          id: response['id']?.toString() ?? response['nama']?.toString() ?? name,
          name: response['nama']?.toString() ?? response['name']?.toString() ?? name,
          role: role,
          registeredAt: DateTime.now(),
          jumlahFrame: response['jumlah_frame'] as int? ?? 1,
        );
      }
      throw ApiException('Format respons pendaftaran wajah tidak dikenali.');
    }

    final response = await ApiClient.post(
      '${ApiConfig.baseUrl}/api/enroll',
      {'nama': name, 'role': role},
    );
    if (response is Map<String, dynamic>) {
      return RegisteredFace(
        id: response['id']?.toString() ?? response['nama']?.toString() ?? name,
        name: response['nama']?.toString() ?? response['name']?.toString() ?? name,
        role: role,
        registeredAt: DateTime.now(),
        jumlahFrame: response['jumlah_frame'] as int? ?? 1,
      );
    }
    throw ApiException('Format respons pendaftaran wajah tidak dikenali.');
  }

  /// DELETE /api/faces/{nama} — hapus wajah
  static Future<void> deleteFace(String id) async {
    if (ApiConfig.useMockData) {
      MockDataGenerator.deleteFace(id);
      return;
    }
    await ApiClient.delete(ApiConfig.faceDeleteUrl(id));
  }

  /// POST /api/recognize — kenali wajah dari foto upload
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
  static Future<AccessAttempt> testRecognizeRealtime(dynamic fileOrPath, {String mode = 'ai'}) async {
    final stopwatch = Stopwatch()..start();
    try {
      final request = http.MultipartRequest('POST', Uri.parse(ApiConfig.recognizeUrl));
      request.headers.addAll({'Accept': 'application/json'});
      request.fields['mode'] = mode;

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
            mode: mode,
          );
        }
        return AccessAttempt.fromJson(body, latency: latency, defaultMode: mode);
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
        mode: mode,
      );
    } catch (e) {
      stopwatch.stop();
      return AccessAttempt(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        matchedName: null,
        isLivenessPassed: false,
        livenessScore: 0.0,
        isAuthorized: false,
        message: 'Gagal terhubung ke backend: $e',
        timestamp: DateTime.now(),
        latencyMs: stopwatch.elapsedMilliseconds,
        mode: mode,
      );
    }
  }

  /// GET /api/status — hasil recognition terakhir dari backend
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

  /// GET /api/faces/attempts — riwayat akses pintu
  static Future<List<AccessAttempt>> fetchAccessAttempts() async {
    if (ApiConfig.useMockData) {
      return List.from(MockDataGenerator.accessAttempts);
    }

    final response = await ApiClient.get(ApiConfig.accessAttemptsUrl);
    if (response is Map && response['attempts'] is List) {
      return (response['attempts'] as List)
          .map((item) => AccessAttempt.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    if (response is List) {
      return response
          .map((item) => AccessAttempt.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }
}
