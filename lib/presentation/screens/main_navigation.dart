import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../widgets/neu_box.dart';
import 'dashboard/dashboard_screen.dart';
import 'control/device_control_screen.dart';
import 'security/security_screen.dart';
import 'history/history_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    DeviceControlScreen(),
    SecurityScreen(),
    HistoryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
      ),
      bottomNavigationBar: Container(
        color: AppColors.neuBase,
        padding: const EdgeInsets.only(left: 18, right: 18, bottom: 16, top: 8),
        child: NeuBox(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          borderRadius: BorderRadius.circular(26),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(0, Icons.dashboard_outlined, Icons.dashboard, 'Dashboard'),
              _navItem(1, Icons.tune_outlined, Icons.tune, 'Kontrol'),
              _navItem(2, Icons.face_retouching_natural_outlined, Icons.face_retouching_natural, 'Keamanan'),
              _navItem(3, Icons.history_outlined, Icons.history, 'Histori'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, IconData activeIcon, String label) {
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: isSelected
            ? BoxDecoration(
                color: AppColors.neuBase,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.neuDarkShadow.withAlpha(200),
                    offset: const Offset(2.5, 2.5),
                    blurRadius: 5,
                  ),
                  const BoxShadow(
                    color: Colors.white,
                    offset: Offset(-2.5, -2.5),
                    blurRadius: 5,
                  ),
                ],
              )
            : null,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              size: 20,
              color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
