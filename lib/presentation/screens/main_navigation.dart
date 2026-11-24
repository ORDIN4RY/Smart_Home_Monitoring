import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../widgets/neu_box.dart';
import '../widgets/lazy_keep_alive_gate.dart';
import '../widgets/dynamic_island_alert.dart';
import '../widgets/sync_status_indicator.dart';
import 'dashboard/dashboard_screen.dart';
import 'control/device_control_screen.dart';
import 'security/security_screen.dart';
import 'history/history_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  /// Navigasi ke tab tertentu dari mana saja di dalam widget tree
  static void switchTo(BuildContext context, int tabIndex) {
    final state = context.findAncestorStateOfType<_MainNavigationState>();
    if (state != null) {
      state.switchToTab(tabIndex);
    }
  }

  /// Kontrol swipe gesture PageView (untuk mencegah konflik saat slider suhu disentuh)
  static final ValueNotifier<bool> isSwipeEnabled = ValueNotifier<bool>(true);

  static void setSwipeEnabled(bool enabled) {
    if (isSwipeEnabled.value != enabled) {
      isSwipeEnabled.value = enabled;
    }
  }

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _NavItemData {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItemData({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

class _MainNavigationState extends State<MainNavigation> {
  late final PageController _pageController;
  int _currentIndex = 0;

  // Preload semua tab sejak awal agar instan saat digeser/pindah tanpa delay
  final Set<int> _loadedTabs = {0, 1, 2, 3};

  static const List<_NavItemData> _navItems = [
    _NavItemData(
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard,
      label: 'Dashboard',
    ),
    _NavItemData(
      icon: Icons.tune_outlined,
      activeIcon: Icons.tune,
      label: 'Kontrol',
    ),
    _NavItemData(
      icon: Icons.face_retouching_natural_outlined,
      activeIcon: Icons.face_retouching_natural,
      label: 'Keamanan',
    ),
    _NavItemData(
      icon: Icons.history_outlined,
      activeIcon: Icons.history,
      label: 'Histori',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void switchToTab(int index) {
    if (index < 0 || index >= _navItems.length) return;
    if (!_loadedTabs.contains(index)) {
      setState(() {
        _loadedTabs.add(index);
      });
    }
    setState(() {
      _currentIndex = index;
    });
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Widget _buildTopHeader() {
    Widget titleWidget;

    if (_currentIndex == 0) {
      titleWidget = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          NeuBox(
            isPressed: true,
            shape: BoxShape.circle,
            padding: const EdgeInsets.all(4),
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF242C38),
              ),
              child: const Center(
                child: Icon(Icons.person, color: Color(0xFFE2E7EE), size: 20),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Hi, Administrator',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
              SizedBox(height: 1),
              Text(
                'Smart Home Active',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      );
    } else {
      String title;
      String subtitle;
      IconData icon;

      switch (_currentIndex) {
        case 1:
          title = 'Kendali Perangkat';
          subtitle = 'Manajemen & Otomasi';
          icon = Icons.tune;
          break;
        case 2:
          title = 'Sistem Keamanan';
          subtitle = 'Face Recognition & Sensor';
          icon = Icons.shield_outlined;
          break;
        case 3:
        default:
          title = 'Histori & Aktivitas';
          subtitle = 'Log Sensor & Peringatan';
          icon = Icons.history;
          break;
      }

      titleWidget = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          NeuBox(
            isPressed: true,
            shape: BoxShape.circle,
            padding: const EdgeInsets.all(8),
            child: Icon(icon, size: 18, color: AppColors.textPrimary),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(child: titleWidget),
          const SizedBox(width: 12),
          // Indikator Sinkronisasi Permanen & Konsisten di 1 Tempat
          const SyncStatusIndicator(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                // ── PERMANENT UNIFIED TOP HEADER WITH SYNC INDICATOR ──
                _buildTopHeader(),

                // ── TAB PAGES VIEW ──
                Expanded(
                  child: ValueListenableBuilder<bool>(
                    valueListenable: MainNavigation.isSwipeEnabled,
                    builder: (context, canSwipe, _) {
                      return PageView(
                        controller: _pageController,
                        physics: canSwipe
                            ? const BouncingScrollPhysics()
                            : const NeverScrollableScrollPhysics(),
                        onPageChanged: (index) {
                          if (_currentIndex != index) {
                            setState(() {
                              _currentIndex = index;
                              _loadedTabs.add(index);
                            });
                          }
                        },
                        children: [
                          LazyKeepAliveGate(
                            shouldLoad: _loadedTabs.contains(0),
                            child: const DashboardScreen(),
                          ),
                          LazyKeepAliveGate(
                            shouldLoad: _loadedTabs.contains(1),
                            child: const DeviceControlScreen(),
                          ),
                          LazyKeepAliveGate(
                            shouldLoad: _loadedTabs.contains(2),
                            child: const SecurityScreen(),
                          ),
                          LazyKeepAliveGate(
                            shouldLoad: _loadedTabs.contains(3),
                            child: const HistoryScreen(),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
            // ── DYNAMIC ISLAND FLUID ALERT BUBBLE ──
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: DynamicIslandAlert(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        color: AppColors.neuBase,
        padding: EdgeInsets.only(
          left: 18,
          right: 18,
          top: 4,
          bottom: MediaQuery.paddingOf(context).bottom > 0
              ? MediaQuery.paddingOf(context).bottom + 4
              : 10,
        ),
        child: NeuBox(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
          borderRadius: BorderRadius.circular(24),
          child: AnimatedBuilder(
            animation: _pageController,
            builder: (context, _) {
              final pageOffset = (_pageController.hasClients && _pageController.page != null)
                  ? _pageController.page!
                  : _currentIndex.toDouble();

              return LayoutBuilder(
                builder: (context, constraints) {
                  final totalWidth = constraints.maxWidth;
                  final unit = totalWidth / 48.0;
                  final inactiveW = unit * 10.0;
                  final activeW = unit * 18.0;
                  const double barHeight = 44.0;

                  final currentLeft = (pageOffset * inactiveW).clamp(0.0, totalWidth - activeW);

                  return SizedBox(
                    height: barHeight,
                    child: Stack(
                      children: [
                        // ── FLUID SLIDING ACTIVE INDICATOR PILL ──
                        Positioned(
                          left: currentLeft,
                          width: activeW,
                          top: 0,
                          bottom: 0,
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.neuBase,
                              borderRadius: BorderRadius.circular(19),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.neuDarkShadow.withAlpha(200),
                                  offset: const Offset(2.0, 2.0),
                                  blurRadius: 4,
                                ),
                                const BoxShadow(
                                  color: Colors.white,
                                  offset: Offset(-2.0, -2.0),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                        ),

                        // ── NAV ITEMS INTERACTION LAYER ──
                        Row(
                          children: List.generate(_navItems.length, (index) {
                            final isSelected = _currentIndex == index;
                            return Expanded(
                              flex: isSelected ? 18 : 10,
                              child: _navItem(index, _navItems[index]),
                            );
                          }),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, _NavItemData item) {
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () => switchToTab(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: double.infinity,
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isSelected ? item.activeIcon : item.icon,
                    size: 20,
                    color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                  ),
                  AnimatedCrossFade(
                    firstChild: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(width: 6),
                        Text(
                          item.label,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                    secondChild: const SizedBox.shrink(),
                    crossFadeState: isSelected
                        ? CrossFadeState.showFirst
                        : CrossFadeState.showSecond,
                    duration: const Duration(milliseconds: 200),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
