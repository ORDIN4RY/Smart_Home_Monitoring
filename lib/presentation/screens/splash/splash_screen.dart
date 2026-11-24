import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/server_connection_manager.dart';
import '../../../data/services/sync_manager.dart';
import '../../widgets/neu_box.dart';
import '../main_navigation.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  String _loadingMessage = 'Menyiapkan sistem...';
  double _loadingProgress = 0.1;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
    );

    _opacityAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeIn,
    );

    _animController.forward();
    _startInitializationSequence();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _startInitializationSequence() async {
    // 1. Minimum logo presentation duration
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;

    // 2. Load Local Storage data
    setState(() {
      _loadingMessage = 'Memuat data lokal...';
      _loadingProgress = 0.35;
    });
    try {
      await SyncManager.initialize();
    } catch (_) {}

    await Future.delayed(const Duration(milliseconds: 250));
    if (!mounted) return;

    // 3. Connect to Server & Synchronize
    setState(() {
      _loadingMessage = 'Menghubungkan ke server IoT...';
      _loadingProgress = 0.65;
    });

    try {
      final isOnline = await ServerConnectionManager.checkConnection();
      if (!mounted) return;

      if (isOnline) {
        setState(() {
          _loadingMessage = 'Menyelaraskan data & kontrol...';
          _loadingProgress = 0.85;
        });
        await SyncManager.syncAll(silent: true);
      } else {
        setState(() {
          _loadingMessage = 'Server offline, menggunakan data lokal...';
          _loadingProgress = 0.85;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loadingMessage = 'Menggunakan profil offline...';
          _loadingProgress = 0.85;
        });
      }
    }

    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    // 4. Ready
    setState(() {
      _loadingMessage = 'Memulai Smart Home...';
      _loadingProgress = 1.0;
    });

    await Future.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;

    _navigateToHome();
  }

  void _navigateToHome() {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (context, anim, secAnim) => const MainNavigation(),
        transitionsBuilder: (context, anim, secAnim, child) {
          return FadeTransition(opacity: anim, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neuBase,
      body: SafeArea(
        child: Center(
          child: FadeTransition(
            opacity: _opacityAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 36),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Neumorphic Logo Icon
                    NeuBox(
                      shape: BoxShape.circle,
                      padding: const EdgeInsets.all(26),
                      glowColor: AppColors.primary.withAlpha(25),
                      glowRadius: 12,
                      child: const Icon(
                        Icons.home_outlined,
                        size: 48,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // App Title
                    const Text(
                      'Smart Home',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.6,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Subtitle
                    const Text(
                      'Monitoring & IoT System',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.1,
                      ),
                    ),
                    const SizedBox(height: 42),

                    // ── Neumorphic Inset Loading Bar ──
                    NeuBox(
                      isPressed: true,
                      padding: const EdgeInsets.all(4),
                      borderRadius: BorderRadius.circular(20),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          height: 8,
                          width: double.infinity,
                          color: const Color(0xFFD6E0EC),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: AnimatedFractionallySizedBox(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOutCubic,
                              widthFactor: _loadingProgress,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF384556),
                                      AppColors.primary,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Loading message & percentage
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _loadingMessage,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${(_loadingProgress * 100).toInt()}%',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
