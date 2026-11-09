import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/config/api_config.dart';
import '../../../data/models/user_model.dart';
import '../../../data/services/auth_service.dart';
import '../../widgets/neu_box.dart';
import '../auth/login_screen.dart';
import 'device_settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserModel? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = await AuthService.fetchProfile();
    if (mounted) {
      setState(() {
        _user = user;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.neuBase,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text('Konfirmasi Keluar', style: TextStyle(color: AppColors.textPrimary)),
        content: const Text(
          'Apakah Anda yakin ingin keluar dari sesi aplikasi?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Keluar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await AuthService.logout();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    final user = _user ??
        const UserModel(
          id: '',
          name: 'User',
          email: 'user@smarthome.id',
          role: 'Owner',
          token: '',
        );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Pengguna'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Column(
          children: [
            // Avatar & Name Card (Neumorphic)
            NeuBox(
              padding: const EdgeInsets.all(20),
              borderRadius: BorderRadius.circular(22),
              child: Row(
                children: [
                  NeuBox(
                    isPressed: true,
                    shape: BoxShape.circle,
                    padding: const EdgeInsets.all(16),
                    glowColor: AppColors.primary.withAlpha(40),
                    glowRadius: 8,
                    child: Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user.email,
                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.neuDarkShadow,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            user.role,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Settings & Actions
            NeuBox(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              borderRadius: BorderRadius.circular(22),
              child: Column(
                children: [
                  ListTile(
                    leading: NeuBox(
                      isPressed: true,
                      shape: BoxShape.circle,
                      padding: const EdgeInsets.all(8),
                      child: const Icon(Icons.settings_outlined, color: AppColors.primary, size: 20),
                    ),
                    title: const Text('Pengaturan Backend & Device', style: TextStyle(fontSize: 14)),
                    subtitle: Text('Base URL: ${ApiConfig.baseUrl}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 20),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const DeviceSettingsScreen()),
                      ).then((_) => setState(() {}));
                    },
                  ),
                  Container(height: 1, margin: const EdgeInsets.symmetric(horizontal: 16), color: AppColors.neuDarkShadow),
                  ListTile(
                    leading: NeuBox(
                      isPressed: true,
                      shape: BoxShape.circle,
                      padding: const EdgeInsets.all(8),
                      child: const Icon(Icons.security_outlined, color: AppColors.normal, size: 20),
                    ),
                    title: const Text('Protokol Komunikasi', style: TextStyle(fontSize: 14)),
                    subtitle: const Text('REST API via HTTPS + JSON', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    trailing: const Icon(Icons.lock_outline, size: 18, color: AppColors.normal),
                  ),
                  Container(height: 1, margin: const EdgeInsets.symmetric(horizontal: 16), color: AppColors.neuDarkShadow),
                  ListTile(
                    leading: NeuBox(
                      isPressed: true,
                      shape: BoxShape.circle,
                      padding: const EdgeInsets.all(8),
                      child: const Icon(Icons.palette_outlined, color: AppColors.accent, size: 20),
                    ),
                    title: const Text('Desain Antarmuka', style: TextStyle(fontSize: 14)),
                    subtitle: const Text('Neumorphic Soft UI (Dark Mode)', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Logout Tactile Button
            NeuBox(
              onTap: _handleLogout,
              padding: const EdgeInsets.symmetric(vertical: 16),
              borderRadius: BorderRadius.circular(18),
              glowColor: AppColors.danger.withAlpha(35),
              glowRadius: 10,
              child: const Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.logout, color: AppColors.danger, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Keluar dari Akun',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.danger,
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
}
