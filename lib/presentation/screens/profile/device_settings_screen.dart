import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/config/api_config.dart';
import '../../widgets/neu_box.dart';
import '../../widgets/neu_switch.dart';

class DeviceSettingsScreen extends StatefulWidget {
  const DeviceSettingsScreen({super.key});

  @override
  State<DeviceSettingsScreen> createState() => _DeviceSettingsScreenState();
}

class _DeviceSettingsScreenState extends State<DeviceSettingsScreen> {
  final _urlController = TextEditingController();
  bool _useMock = ApiConfig.useMockData;

  @override
  void initState() {
    super.initState();
    _urlController.text = ApiConfig.baseUrl;
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  void _saveSettings() {
    final url = _urlController.text.trim();
    if (url.isNotEmpty) {
      ApiConfig.updateBaseUrl(url);
    }
    setState(() {
      ApiConfig.useMockData = _useMock;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Pengaturan backend berhasil disimpan'),
        backgroundColor: AppColors.normal,
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan Server & Perangkat'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Konfigurasi REST API Flask',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Koneksi komunikasi antara aplikasi mobile dan server backend.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),

            // Base URL Input (Neumorphic Inset)
            NeuBox(
              isPressed: true,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              borderRadius: BorderRadius.circular(16),
              child: TextFormField(
                controller: _urlController,
                style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  hintText: 'https://192.168.1.100:5000',
                  icon: Icon(Icons.link, color: AppColors.textSecondary, size: 20),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Mock Data Toggle
            NeuBox(
              padding: const EdgeInsets.all(16),
              borderRadius: BorderRadius.circular(18),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Mode Simulasi (Mock Data)',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Gunakan data simulasi saat server Flask belum menyala.',
                          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
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
            ),
            const SizedBox(height: 24),

            const Text(
              'Batas Ambang Keamanan',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 12),

            _neuThresholdTile('Ambang Gas MQ-2 Bahaya', '>= 400 PPM (Buzzer)'),
            _neuThresholdTile('Ambang Gas MQ-2 Waspada', '>= 200 PPM (Peringatan)'),
            _neuThresholdTile('LDR Ambang Gelap', '< 30% (Lampu Nyala)'),
            _neuThresholdTile('Cooling Peltier Target', '24.0°C (Default)'),

            const SizedBox(height: 28),

            // Save Button
            NeuBox(
              onTap: _saveSettings,
              padding: const EdgeInsets.symmetric(vertical: 16),
              borderRadius: BorderRadius.circular(18),
              glowColor: AppColors.primary.withAlpha(45),
              glowRadius: 10,
              child: const Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.save_outlined, color: AppColors.primary, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Simpan Perubahan',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _neuThresholdTile(String title, String val) {
    return NeuBox(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      borderRadius: BorderRadius.circular(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
          Text(val, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
        ],
      ),
    );
  }
}
