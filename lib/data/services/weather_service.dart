import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WeatherData {
  final double temperature;
  final int humidity;
  final int weatherCode;
  final bool isDay;
  final DateTime timestamp;

  const WeatherData({
    required this.temperature,
    required this.humidity,
    required this.weatherCode,
    required this.isDay,
    required this.timestamp,
  });

  String get conditionText {
    switch (weatherCode) {
      case 0:
        return isDay ? 'Cerah' : 'Cerah Malam';
      case 1:
      case 2:
        return 'Sebagian Berawan';
      case 3:
        return 'Mendung / Berawan';
      case 45:
      case 48:
        return 'Berkabut';
      case 51:
      case 53:
      case 55:
        return 'Gerimis';
      case 61:
      case 63:
      case 65:
        return 'Hujan';
      case 80:
      case 81:
      case 82:
        return 'Hujan Deras';
      case 95:
      case 96:
      case 99:
        return 'Badai Petir';
      default:
        return 'Cerah Berawan';
    }
  }

  IconData get iconData {
    switch (weatherCode) {
      case 0:
        return isDay ? Icons.wb_sunny_outlined : Icons.nightlight_round;
      case 1:
      case 2:
        return isDay ? Icons.wb_cloudy_outlined : Icons.cloud_outlined;
      case 3:
        return Icons.cloud_outlined;
      case 45:
      case 48:
        return Icons.foggy;
      case 51:
      case 53:
      case 55:
        return Icons.grain;
      case 61:
      case 63:
      case 65:
      case 80:
      case 81:
      case 82:
        return Icons.water_drop_outlined;
      case 95:
      case 96:
      case 99:
        return Icons.thunderstorm_outlined;
      default:
        return Icons.wb_sunny_outlined;
    }
  }
}

class WeatherService {
  // Koordinat rumah default (bisa diperbarui via GPS dan disimpan permanen)
  static double latitude = -6.2088;
  static double longitude = 106.8456;
  static String locationName = 'Area Rumah';
  static bool hasSavedGps = false;

  static final ValueNotifier<WeatherData?> currentWeather = ValueNotifier<WeatherData?>(null);
  static DateTime? _lastFetchTime;

  /// Membaca koordinat yang sebelumnya disimpan dari SharedPreferences
  static Future<void> loadSavedLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLat = prefs.getDouble('weather_latitude');
      final savedLon = prefs.getDouble('weather_longitude');
      final savedName = prefs.getString('weather_loc_name');
      if (savedLat != null && savedLon != null) {
        latitude = savedLat;
        longitude = savedLon;
        hasSavedGps = true;
        if (savedName != null && !savedName.contains('(')) {
          locationName = savedName;
        } else {
          locationName = await _resolveCityName(latitude, longitude);
          await prefs.setString('weather_loc_name', locationName);
        }
      }
    } catch (_) {}
  }

  /// Mengambil nama kota / kabupaten yang bersih dari koordinat (Gratis, tanpa API key)
  static Future<String> _resolveCityName(double lat, double lon) async {
    try {
      final geoUrl = Uri.parse(
        'https://api.bigdatacloud.net/data/reverse-geocode-client?latitude=$lat&longitude=$lon&localityLanguage=id',
      );
      final geoRes = await http.get(geoUrl).timeout(const Duration(seconds: 4));
      if (geoRes.statusCode == 200) {
        final geoData = jsonDecode(geoRes.body);
        final city = geoData['city'] as String?;
        final locality = geoData['locality'] as String?;
        final admin = geoData['localityInfo']?['administrative'] as List?;
        String? regencyOrCity;
        if (admin != null) {
          for (final a in admin.reversed) {
            final name = a['name'] as String?;
            final desc = (a['description'] as String? ?? '').toLowerCase();
            if (name != null && (desc.contains('kabupaten') || desc.contains('kota') || desc.contains('regency') || desc.contains('city'))) {
              regencyOrCity = name;
              break;
            }
          }
        }
        if (regencyOrCity != null && regencyOrCity.isNotEmpty) return regencyOrCity;
        if (city != null && city.isNotEmpty) return city;
        if (locality != null && locality.isNotEmpty) return locality;
      }
    } catch (_) {}
    return 'Area Rumah';
  }

  /// Ambil koordinat GPS HP sekali saja dan simpan permanen ke HP
  static Future<String?> updateLocationFromGps() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return 'GPS HP sedang nonaktif. Silakan aktifkan lokasi di setelan HP.';
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return 'Izin lokasi ditolak.';
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return 'Izin lokasi ditolak permanen. Buka izin di setelan aplikasi HP.';
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );

      latitude = pos.latitude;
      longitude = pos.longitude;
      locationName = await _resolveCityName(latitude, longitude);
      hasSavedGps = true;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('weather_latitude', latitude);
      await prefs.setDouble('weather_longitude', longitude);
      await prefs.setString('weather_loc_name', locationName);

      await fetchCurrentWeather(forceRefresh: true);
      return null;
    } on MissingPluginException {
      return 'Package GPS baru dipasang. Silakan STOP dan jalankan ulang (Rebuild/Restart penuh) aplikasi, atau atur manual di Pengaturan.';
    } catch (e) {
      if (e.toString().contains('MissingPluginException') || e.toString().contains('No implementation found')) {
        return 'Package GPS baru dipasang. Silakan STOP dan jalankan ulang aplikasi (Rebuild APK/Restart penuh).';
      }
      return 'Gagal membaca GPS: $e';
    }
  }

  /// Simpan koordinat manual dari menu Pengaturan
  static Future<void> saveManualCoordinates(double lat, double lon, String name) async {
    latitude = lat;
    longitude = lon;
    locationName = name;
    hasSavedGps = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('weather_latitude', latitude);
      await prefs.setDouble('weather_longitude', longitude);
      await prefs.setString('weather_loc_name', locationName);
    } catch (_) {}
    await fetchCurrentWeather(forceRefresh: true);
  }

  /// Ambil cuaca dari Open-Meteo API (100% Gratis, tanpa API Key)
  static Future<WeatherData?> fetchCurrentWeather({bool forceRefresh = false}) async {
    // Cache selama 15 menit agar hemat kuota dan cepat
    if (!forceRefresh &&
        currentWeather.value != null &&
        _lastFetchTime != null &&
        DateTime.now().difference(_lastFetchTime!).inMinutes < 15) {
      return currentWeather.value;
    }

    try {
      final url = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=$latitude&longitude=$longitude&current=temperature_2m,relative_humidity_2m,weather_code,is_day&timezone=auto',
      );

      final res = await http.get(url).timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final current = data['current'];
        if (current != null) {
          final weather = WeatherData(
            temperature: (current['temperature_2m'] as num).toDouble(),
            humidity: (current['relative_humidity_2m'] as num).toInt(),
            weatherCode: (current['weather_code'] as num).toInt(),
            isDay: (current['is_day'] as num) == 1,
            timestamp: DateTime.now(),
          );
          currentWeather.value = weather;
          _lastFetchTime = DateTime.now();
          return weather;
        }
      }
    } catch (_) {
      // Diamkan error jaringan 3rd party agar aplikasi smart home tetap berjalan lancar
    }
    return currentWeather.value;
  }
}
