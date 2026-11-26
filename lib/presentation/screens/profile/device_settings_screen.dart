import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/config/api_config.dart';
import '../../../data/services/server_connection_manager.dart';
import '../../../data/services/weather_service.dart';
import '../../widgets/neu_box.dart';
import '../../widgets/neu_switch.dart';

class DeviceSettingsScreen extends StatefulWidget {
  const DeviceSettingsScreen({super.key});

  @override
  State<DeviceSettingsScreen> createState() => _DeviceSettingsScreenState();
}

class _DeviceSettingsScreenState extends State<DeviceSettingsScreen> {
  final _urlController = TextEditingController();
  final _latController = TextEditingController();
  final _lonController = TextEditingController();
  final _locNameController = TextEditingController();

  bool _useMock = ApiConfig.useMockData;
  bool _isLoadingGps = false;

  @override
  void initState() {
    super.initState();
    _urlController.text = ApiConfig.baseUrl;
    _latController.text = WeatherService.latitude.toString();
    _lonController.text = WeatherService.longitude.toString();
    _locNameController.text = WeatherService.locationName;
  }

  @override
  void dispose() {
    _urlController.dispose();
    _latController.dispose();
    _lonController.dispose();
    _locNameController.dispose();
    super.dispose();
  }

  Future<void> _fetchGpsCoordinates() async {
    setState(() => _isLoadingGps = true);
    final error = await WeatherService.updateLocationFromGps();
    if (!mounted) return;
    setState(() => _isLoadingGps = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: AppColors.danger,
          duration: const Duration(seconds: 4),
        ),
      );
    } else {
      _latController.text = WeatherService.latitude.toString();
      _lonController.text = WeatherService.longitude.toString();
      _locNameController.text = WeatherService.locationName;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Koordinat GPS berhasil dibaca dan diperbarui!'),
          backgroundColor: AppColors.normal,
        ),
      );
    }
  }

  void _saveSettings() {
    final url = _urlController.text.trim();
    if (url.isNotEmpty) {
      ApiConfig.updateBaseUrl(url);
    }

    final lat = double.tryParse(_latController.text.trim()) ?? WeatherService.latitude;
    final lon = double.tryParse(_lonController.text.trim()) ?? WeatherService.longitude;
    final name = _locNameController.text.trim().isNotEmpty
        ? _locNameController.text.trim()
        : WeatherService.locationName;

    WeatherService.saveManualCoordinates(lat, lon, name);

    setState(() {
      ApiConfig.useMockData = _useMock;
    });

    ServerConnectionManager.checkConnection();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Semua pengaturan backend & perangkat berhasil disimpan'),
        backgroundColor: AppColors.normal,
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neuBase,
      appBar: AppBar(
        backgroundColor: AppColors.neuBase,
        elevation: 0,
        title: const Text(
          'Pengaturan Server & Perangkat',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 1. REST API Flask Server ──
            NeuBox(
              padding: const EdgeInsets.all(18),
              borderRadius: BorderRadius.circular(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      NeuBox(
                        isPressed: true,
                        shape: BoxShape.circle,
                        padding: const EdgeInsets.all(10),
                        child: const Icon(Icons.dns_outlined, size: 18, color: AppColors.textPrimary),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Server REST API Flask',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Alamat IP backend IoT & Face Recognition',
                              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Input Base URL
                  NeuBox(
                    isPressed: true,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    borderRadius: BorderRadius.circular(16),
                    child: TextFormField(
                      controller: _urlController,
                      style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                      decoration: const InputDecoration(
                        hintText: 'http://157.66.34.38:8080',
                        icon: Icon(Icons.link, color: AppColors.textSecondary, size: 18),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Quick Preset Chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _presetChip('Server Cloud', 'http://157.66.34.38:8080'),
                      _presetChip('Localhost', 'http://127.0.0.1:8080'),
                      _presetChip('Wi-Fi LAN', 'http://192.168.1.100:8080'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Color(0xFFD5DFEC)),
                  const SizedBox(height: 12),
                  // Toggle Mock Data
                  Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Mode Simulasi (Mock Data)',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Gunakan data tiruan jika server Flask offline',
                              style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      NeuSwitch(
                        value: _useMock,
                        onChanged: (val) => setState(() => _useMock = val),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // ── 2. Lokasi Rumah & Cuaca (GPS & Koordinat) ──
            NeuBox(
              padding: const EdgeInsets.all(18),
              borderRadius: BorderRadius.circular(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      NeuBox(
                        isPressed: true,
                        shape: BoxShape.circle,
                        padding: const EdgeInsets.all(10),
                        child: const Icon(Icons.location_on_outlined, size: 18, color: AppColors.textPrimary),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Lokasi Rumah (Cuaca)',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Disimpan sekali untuk prakiraan cuaca Open-Meteo',
                              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: NeuBox(
                          isPressed: true,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                          borderRadius: BorderRadius.circular(14),
                          child: TextFormField(
                            controller: _latController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            decoration: const InputDecoration(
                              labelText: 'Latitude',
                              labelStyle: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: NeuBox(
                          isPressed: true,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                          borderRadius: BorderRadius.circular(14),
                          child: TextFormField(
                            controller: _lonController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            decoration: const InputDecoration(
                              labelText: 'Longitude',
                              labelStyle: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  NeuBox(
                    isPressed: true,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                    borderRadius: BorderRadius.circular(14),
                    child: TextFormField(
                      controller: _locNameController,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                        labelText: 'Label Lokasi',
                        labelStyle: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Tombol GPS
                  GestureDetector(
                    onTap: _isLoadingGps ? null : _fetchGpsCoordinates,
                    child: NeuBox(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      borderRadius: BorderRadius.circular(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_isLoadingGps)
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textPrimary),
                            )
                          else
                            const Icon(Icons.my_location_rounded, size: 16, color: AppColors.activeBlue),
                          const SizedBox(width: 8),
                          Text(
                            _isLoadingGps ? 'Membaca GPS HP...' : 'Ambil Koordinat via GPS HP',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // ── 3. Batas Ambang Keamanan Sensor (No More 22px Overflow!) ──
            NeuBox(
              padding: const EdgeInsets.all(18),
              borderRadius: BorderRadius.circular(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      NeuBox(
                        isPressed: true,
                        shape: BoxShape.circle,
                        padding: const EdgeInsets.all(10),
                        child: const Icon(Icons.tune_rounded, size: 18, color: AppColors.textPrimary),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Batas Ambang Keamanan',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Parameter pemicu alarm dan otomasi rumah',
                              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _thresholdRow(
                    icon: Icons.gas_meter_outlined,
                    iconColor: AppColors.danger,
                    title: 'Gas MQ-2 Bahaya',
                    description: 'Memicu buzzer darurat nyaring',
                    value: '>= 400 PPM',
                  ),
                  _thresholdRow(
                    icon: Icons.warning_amber_rounded,
                    iconColor: AppColors.warning,
                    title: 'Gas MQ-2 Waspada',
                    description: 'Notifikasi peringatan dini',
                    value: '>= 200 PPM',
                  ),
                  _thresholdRow(
                    icon: Icons.lightbulb_outline,
                    iconColor: AppColors.activeBlue,
                    title: 'Ambang Gelap LDR',
                    description: 'Lampu teras otomatis menyala',
                    value: '< 30% Lux',
                  ),
                  _thresholdRow(
                    icon: Icons.ac_unit,
                    iconColor: AppColors.activeBlue,
                    title: 'Target Default Pendingin',
                    description: 'Nilai awal set point suhu',
                    value: '24.0°C',
                    isLast: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── 4. Tombol Simpan Perubahan Utama ──
            GestureDetector(
              onTap: _saveSettings,
              child: NeuBox(
                padding: const EdgeInsets.symmetric(vertical: 16),
                borderRadius: BorderRadius.circular(22),
                glowColor: AppColors.normal.withAlpha(45),
                glowRadius: 10,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.save_rounded, color: AppColors.textPrimary, size: 20),
                    SizedBox(width: 10),
                    Text(
                      'Simpan Pengaturan',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _presetChip(String label, String url) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _urlController.text = url;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.neuBase,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
        ),
      ),
    );
  }

  Widget _thresholdRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required String value,
    bool isLast = false,
  }) {
    return Column(
      children: [
        Row(
          children: [
            NeuBox(
              isPressed: true,
              shape: BoxShape.circle,
              padding: const EdgeInsets.all(8),
              child: Icon(icon, size: 16, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  Text(
                    description,
                    style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.neuBase,
                borderRadius: BorderRadius.circular(10),
                boxShadow: const [
                  BoxShadow(color: Color(0x33A6B4C9), offset: Offset(1, 1), blurRadius: 2),
                  BoxShadow(color: Colors.white, offset: Offset(-1, -1), blurRadius: 2),
                ],
              ),
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        if (!isLast) const SizedBox(height: 12),
      ],
    );
  }
}
