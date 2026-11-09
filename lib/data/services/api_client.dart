import 'dart:convert';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import '../../core/config/api_config.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
}

class ApiClient {
  static String? authToken;

  static Map<String, String> get _jsonHeaders => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (authToken != null && authToken!.isNotEmpty)
          'Authorization': 'Bearer $authToken',
      };

  static Map<String, String> get _acceptHeaders => {
        'Accept': 'application/json',
        if (authToken != null && authToken!.isNotEmpty)
          'Authorization': 'Bearer $authToken',
      };

  // ── GET ──────────────────────────────────────────────────────────────

  static Future<dynamic> get(String url) async {
    try {
      final response = await http
          .get(Uri.parse(url), headers: _jsonHeaders)
          .timeout(ApiConfig.timeout);
      return _processResponse(response);
    } on http.ClientException catch (e) {
      throw ApiException('Kesalahan koneksi HTTP: ${e.message}');
    } catch (e) {
      throw ApiException('Tidak dapat terhubung ke server backend Flask: $e');
    }
  }

  // ── POST JSON ─────────────────────────────────────────────────────────

  static Future<dynamic> post(String url, Map<String, dynamic> body) async {
    try {
      final response = await http
          .post(Uri.parse(url), headers: _jsonHeaders, body: jsonEncode(body))
          .timeout(ApiConfig.timeout);
      return _processResponse(response);
    } on http.ClientException catch (e) {
      throw ApiException('Kesalahan koneksi HTTP: ${e.message}');
    } catch (e) {
      throw ApiException('Tidak dapat terhubung ke server backend Flask: $e');
    }
  }

  // ── POST Multipart (upload foto ke Flask) ────────────────────────────

  /// Upload foto ke Flask endpoint (misal /api/enroll/photo atau /api/recognize).
  /// [fields]  — form fields teks (misal {"nama": "Faris"})
  /// [fileField] — nama field file (default "photo")
  /// [filePath]  — path atau blob URL gambar di device/web
  static Future<dynamic> postMultipart(
    String url, {
    Map<String, String> fields = const {},
    required String filePath,
    String fileField = 'photo',
    List<int>? bytes,
  }) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse(url));
      request.headers.addAll(_acceptHeaders);
      request.fields.addAll(fields);
      final List<int> fileBytes = bytes ?? await XFile(filePath).readAsBytes();
      request.files.add(http.MultipartFile.fromBytes(fileField, fileBytes, filename: 'photo.jpg'));

      final streamed = await request.send().timeout(ApiConfig.timeout);
      final response = await http.Response.fromStream(streamed);
      return _processResponse(response);
    } on http.ClientException catch (e) {
      throw ApiException('Kesalahan koneksi HTTP: ${e.message}');
    } catch (e) {
      throw ApiException('Tidak dapat terhubung ke server backend Flask: $e');
    }
  }

  // ── DELETE ────────────────────────────────────────────────────────────

  static Future<dynamic> delete(String url) async {
    try {
      final response = await http
          .delete(Uri.parse(url), headers: _jsonHeaders)
          .timeout(ApiConfig.timeout);
      return _processResponse(response);
    } on http.ClientException catch (e) {
      throw ApiException('Kesalahan koneksi HTTP: ${e.message}');
    } catch (e) {
      throw ApiException('Tidak dapat terhubung ke server backend Flask: $e');
    }
  }

  // ── Response handler ─────────────────────────────────────────────────

  static dynamic _processResponse(http.Response response) {
    final statusCode = response.statusCode;
    dynamic body;
    try {
      body = jsonDecode(response.body);
    } catch (_) {
      body = response.body;
    }

    if (statusCode >= 200 && statusCode < 300) return body;

    if (statusCode == 401) {
      throw ApiException('Sesi kedaluwarsa atau belum login.', 401);
    } else if (statusCode == 403) {
      throw ApiException(
        (body is Map && body['catatan'] != null)
            ? body['catatan'].toString()
            : 'Akses ditolak.',
        403,
      );
    } else if (statusCode == 404) {
      throw ApiException(
        (body is Map && body['error'] != null)
            ? body['error'].toString()
            : 'Tidak ditemukan.',
        404,
      );
    } else if (statusCode >= 500) {
      throw ApiException('Kesalahan pada server Flask.', statusCode);
    } else {
      final msg = (body is Map)
          ? (body['error'] ?? body['message'] ?? 'Permintaan gagal')
          : 'Permintaan gagal';
      throw ApiException(msg.toString(), statusCode);
    }
  }
}
