import 'dart:math' as math;
import 'dart:ui' show lerpDouble;
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../data/services/alert_manager.dart';
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

/// Slot terukur untuk setiap item navbar pada posisi transisi tertentu
class NavSlotLayout {
  final double left;
  final double width;
  final double expansion;
  final double textFactor;
  final double iconCenterX;

  const NavSlotLayout({
    required this.left,
    required this.width,
    required this.expansion,
    required this.textFactor,
    required this.iconCenterX,
  });
}

/// Menghitung layout slot dan path metaball gelembung air untuk posisi [pos].
/// Dipisahkan sebagai pure helper agar presisi dan mudah diuji.
class LiquidBubbleNavGeometry {
  static double smoothstep(double x) {
    final t = x.clamp(0.0, 1.0);
    return t * t * (3.0 - 2.0 * t);
  }

  static double textRevealFor(double expansion) {
    final raw = ((expansion - 0.52) / 0.48).clamp(0.0, 1.0);
    return smoothstep(raw);
  }

  static List<NavSlotLayout> computeSlots({
    required double totalWidth,
    required double pos,
    required List<double> labelWidths,
  }) {
    final count = labelWidths.length;
    final clampedPos = pos.clamp(0.0, (count - 1).toDouble());
    final baseIdx = clampedPos.floor().clamp(0, count - 1);
    final nextIdx = (baseIdx + 1).clamp(0, count - 1);
    final t = clampedPos - baseIdx;
    final s = smoothstep(t);

    final inactiveW = totalWidth * 0.195;
    final activeW = totalWidth - inactiveW * (count - 1);

    final slots = <NavSlotLayout>[];
    double cursor = 0.0;
    for (int i = 0; i < count; i++) {
      final double exp;
      if (baseIdx == nextIdx) {
        exp = i == baseIdx ? 1.0 : 0.0;
      } else if (i == baseIdx) {
        exp = 1.0 - s;
      } else if (i == nextIdx) {
        exp = s;
      } else {
        exp = 0.0;
      }

      final w = inactiveW + exp * (activeW - inactiveW);
      final tf = textRevealFor(exp);
      final contentW = 20.0 + (6.0 + labelWidths[i]) * tf;
      final iconX = cursor + (w - contentW) / 2.0 + 10.0;

      slots.add(NavSlotLayout(
        left: cursor,
        width: w,
        expansion: exp,
        textFactor: tf,
        iconCenterX: iconX,
      ));
      cursor += w;
    }
    return slots;
  }

  static Path buildBubblePath({
    required double totalWidth,
    required double barHeight,
    required double pos,
    required List<NavSlotLayout> slots,
  }) {
    final path = Path();
    if (slots.isEmpty || totalWidth <= 0 || barHeight <= 0) return path;

    final count = slots.length;
    final clampedPos = pos.clamp(0.0, (count - 1).toDouble());
    final leftIdx = clampedPos.floor().clamp(0, count - 1);
    final rightIdx = (leftIdx + 1).clamp(0, count - 1);
    final t = clampedPos - leftIdx;

    const double verticalMargin = 3.0;
    const double insetX = 3.0;
    final double baseR = ((barHeight - verticalMargin * 2) / 2.0).clamp(8.0, 24.0);
    final double cy = barHeight / 2.0;
    final double minCap = insetX + baseR;
    final double maxCap = math.max(minCap, totalWidth - insetX - baseR);

    if (leftIdx == rightIdx || t <= 0.001) {
      final slot = slots[leftIdx];
      final capL = (slot.left + insetX + baseR).clamp(minCap, maxCap);
      final capR = (slot.left + slot.width - insetX - baseR).clamp(capL, maxCap);
      _addLiquidDroplet(path, capL, capR, cy, baseR, baseR, 0.0);
      return path;
    }
    if (t >= 0.999) {
      final slot = slots[rightIdx];
      final capL = (slot.left + insetX + baseR).clamp(minCap, maxCap);
      final capR = (slot.left + slot.width - insetX - baseR).clamp(capL, maxCap);
      _addLiquidDroplet(path, capL, capR, cy, baseR, baseR, 0.0);
      return path;
    }

    final slotL = slots[leftIdx];
    final slotR = slots[rightIdx];

    final startL = (slotL.left + insetX + baseR).clamp(minCap, maxCap);
    final startR = (slotL.left + slotL.width - insetX - baseR).clamp(startL, maxCap);
    final endL = (slotR.left + insetX + baseR).clamp(minCap, maxCap);
    final endR = (slotR.left + slotR.width - insetX - baseR).clamp(endL, maxCap);

    final double iconL = slotL.iconCenterX.clamp(minCap, maxCap);
    final double iconR = slotR.iconCenterX.clamp(minCap, maxCap);
    final double anchorL = lerpDouble(startL, iconL, 0.5)!;

    // Kurva murni fungsi t (tanpa flip arah) agar balik arah di tengah geseran tetap mulus
    double capR;
    if (t < 0.42) {
      capR = lerpDouble(startR, iconR, smoothstep(t / 0.42))!;
    } else if (t < 0.62) {
      capR = iconR;
    } else {
      capR = lerpDouble(iconR, endR, smoothstep((t - 0.62) / 0.38))!;
    }

    double capL;
    if (t < 0.35) {
      capL = lerpDouble(startL, anchorL, smoothstep(t / 0.35))!;
    } else if (t < 0.68) {
      capL = lerpDouble(anchorL, endL, smoothstep((t - 0.35) / 0.33))!;
    } else {
      capL = endL;
    }

    final double travelSin = math.sin(t * math.pi);
    final double rL = baseR * (1.0 - 0.08 * travelSin);
    final double rR = baseR * (1.0 - 0.05 * travelSin);

    // Pastikan gelembung selalu membungkus teks + padding yang sedang tampil (tidak pernah keluar bubble)
    const double textPad = 10.0;
    if (slotL.textFactor > 0.01) {
      final halfContent = (slotL.iconCenterX - 10.0) - slotL.left;
      final contentRightL = (slotL.left + slotL.width) - halfContent;
      capL = math.min(capL, (slotL.iconCenterX - 10.0 - textPad + rL));
      capR = math.max(capR, (contentRightL + textPad - rR));
    }
    if (slotR.textFactor > 0.01) {
      final halfContent = (slotR.iconCenterX - 10.0) - slotR.left;
      final contentRightR = (slotR.left + slotR.width) - halfContent;
      capL = math.min(capL, (slotR.iconCenterX - 10.0 - textPad + rL));
      capR = math.max(capR, (contentRightR + textPad - rR));
    }

    final double safeCapL = capL.clamp(minCap, maxCap);
    final double safeCapR = capR.clamp(safeCapL, maxCap);

    final span = safeCapR - safeCapL;
    final double pinch = span > 4.0 ? math.min(4.0, span * 0.08) * travelSin : 0.0;

    _addLiquidDroplet(path, safeCapL, safeCapR, cy, rL, rR, pinch);
    return path;
  }

  static void _addLiquidDroplet(
    Path path,
    double capL,
    double capR,
    double cy,
    double rL,
    double rR,
    double pinch,
  ) {
    final span = capR - capL;
    if (span <= 0.5 && (rL - rR).abs() <= 0.5) {
      path.addOval(Rect.fromCircle(center: Offset(capL, cy), radius: math.max(rL, rR)));
      return;
    }

    path.moveTo(capL, cy + rL);
    // Setengah lingkaran kiri (searah jarum jam: bawah -> atas)
    path.arcTo(
      Rect.fromCircle(center: Offset(capL, cy), radius: rL),
      math.pi / 2.0,
      math.pi,
      false,
    );

    // Tepi atas mengalir dengan sedikit cekungan tegangan permukaan saat meregang
    if (pinch > 0.05 && span > 1.0) {
      path.cubicTo(
        capL + span * 0.35,
        cy - rL + pinch,
        capR - span * 0.35,
        cy - rR + pinch,
        capR,
        cy - rR,
      );
    } else {
      path.lineTo(capR, cy - rR);
    }

    // Setengah lingkaran kanan (searah jarum jam: atas -> bawah)
    path.arcTo(
      Rect.fromCircle(center: Offset(capR, cy), radius: rR),
      -math.pi / 2.0,
      math.pi,
      false,
    );

    // Tepi bawah kembali ke kiri
    if (pinch > 0.05 && span > 1.0) {
      path.cubicTo(
        capR - span * 0.35,
        cy + rR - pinch,
        capL + span * 0.35,
        cy + rL - pinch,
        capL,
        cy + rL,
      );
    } else {
      path.lineTo(capL, cy + rL);
    }
    path.close();
  }
}

class _LiquidBubbleNavPainter extends CustomPainter {
  final double pos;
  final List<NavSlotLayout> slots;

  const _LiquidBubbleNavPainter({
    required this.pos,
    required this.slots,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bubblePath = LiquidBubbleNavGeometry.buildBubblePath(
      totalWidth: size.width,
      barHeight: size.height,
      pos: pos,
      slots: slots,
    );
    if (bubblePath.getBounds().isEmpty) return;

    // 1. Soft neumorphic elevation shadow (menjaga karakter gelembung air mengambang)
    final darkShadowPaint = Paint()
      ..color = AppColors.neuDarkShadow.withAlpha(185)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
    canvas.save();
    canvas.translate(2.0, 2.5);
    canvas.drawPath(bubblePath, darkShadowPaint);
    canvas.restore();

    final lightShadowPaint = Paint()
      ..color = Colors.white.withAlpha(235)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5);
    canvas.save();
    canvas.translate(-2.0, -2.0);
    canvas.drawPath(bubblePath, lightShadowPaint);
    canvas.restore();

    // 2. Isi gelembung air bening lembut (gradient porcelain-aqua halus)
    final bounds = bubblePath.getBounds();
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFFF6FAFF).withAlpha(245),
          const Color(0xFFE5EEF8).withAlpha(238),
          const Color(0xFFD6E3F2).withAlpha(235),
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(bounds);
    canvas.drawPath(bubblePath, fillPaint);

    // 3. Kilau meniskus air di tepi atas & dalam gelembung
    canvas.save();
    canvas.clipPath(bubblePath);
    final glossRect = Rect.fromLTWH(
      bounds.left,
      bounds.top,
      bounds.width,
      bounds.height * 0.48,
    );
    final glossPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withAlpha(165),
          Colors.white.withAlpha(0),
        ],
      ).createShader(glossRect);
    canvas.drawRect(glossRect, glossPaint);
    canvas.restore();

    // 4. Garis tepi tipis gelembung air (rim specular)
    final rimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withAlpha(220),
          const Color(0xFFB7C7DB).withAlpha(110),
        ],
      ).createShader(bounds);
    canvas.drawPath(bubblePath, rimPaint);
  }

  @override
  bool shouldRepaint(covariant _LiquidBubbleNavPainter oldDelegate) {
    return oldDelegate.pos != pos || oldDelegate.slots != slots;
  }
}

class _MainNavigationState extends State<MainNavigation>
    with SingleTickerProviderStateMixin {
  late final PageController _pageController;
  late final AnimationController _pillController;
  late Animation<double> _pillAnim;
  double _pillPos = 0.0;
  int _currentIndex = 0;
  bool _isProgrammaticScroll = false;
  bool _isIslandActive = false;

  // Muat Dashboard lebih dulu agar startup ringan, tab lain menyusul setelah frame pertama
  final Set<int> _loadedTabs = {0};

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

  late final List<double> _labelWidths;

  static const TextStyle _navLabelStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    letterSpacing: -0.2,
  );

  @override
  void initState() {
    super.initState();
    _labelWidths = _navItems.map((item) {
      final tp = TextPainter(
        text: TextSpan(text: item.label, style: _navLabelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      return tp.width;
    }).toList();

    _pageController = PageController(initialPage: _currentIndex)
      ..addListener(_onPageScroll);
    _pillController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    )..addListener(() {
        _pillPos = _pillAnim.value;
      });
    _pillAnim = AlwaysStoppedAnimation<double>(_currentIndex.toDouble());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 450), () {
        if (mounted && _loadedTabs.length < _navItems.length) {
          setState(() {
            _loadedTabs.addAll(const {1, 2, 3});
          });
        }
      });
    });
  }

  void _onPageScroll() {
    if (!_isProgrammaticScroll &&
        !_pillController.isAnimating &&
        _pageController.hasClients &&
        _pageController.page != null) {
      _pillPos = _pageController.page!;
    }
  }

  @override
  void dispose() {
    _pageController.removeListener(_onPageScroll);
    _pageController.dispose();
    _pillController.dispose();
    super.dispose();
  }

  void switchToTab(int index) {
    if (index < 0 || index >= _navItems.length || index == _currentIndex) return;
    final distance = (index - _currentIndex).abs();
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    setState(() {
      _currentIndex = index;
      _loadedTabs.add(index);
    });

    if (reduceMotion) {
      _pillController.stop();
      _pillPos = index.toDouble();
      _pillAnim = AlwaysStoppedAnimation<double>(_pillPos);
      if (_pageController.hasClients) {
        _pageController.jumpToPage(index);
      }
      return;
    }

    _pillController.duration = Duration(milliseconds: distance > 1 ? 720 : 560);
    _pillAnim = Tween<double>(
      begin: _pillPos,
      end: index.toDouble(),
    ).animate(CurvedAnimation(
      parent: _pillController,
      curve: Curves.easeInOutCubic,
    ));
    _pillController.forward(from: 0);

    if (_pageController.hasClients) {
      _isProgrammaticScroll = true;
      _pageController
          .animateToPage(
            index,
            duration: Duration(milliseconds: distance > 1 ? 680 : 520),
            curve: Curves.easeInOutCubic,
          )
          .whenComplete(() {
        _isProgrammaticScroll = false;
      });
    }
  }

  Widget _buildTopHeader() {
    Widget leftCircle;
    Widget textColumn;

    if (_currentIndex == 0) {
      leftCircle = NeuBox(
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
      );
      textColumn = const Column(
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
            'Homatix Smart Home',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
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

      leftCircle = NeuBox(
        isPressed: true,
        shape: BoxShape.circle,
        padding: const EdgeInsets.all(4),
        child: SizedBox(
          width: 36,
          height: 36,
          child: Center(
            child: Icon(icon, size: 19, color: AppColors.textPrimary),
          ),
        ),
      );
      textColumn = Column(
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
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 6),
      child: ValueListenableBuilder<DynamicAlert?>(
        valueListenable: AlertManager.currentAlert,
        builder: (context, activeAlert, _) {
          final hideRight = activeAlert != null;
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Saat Dynamic Island aktif, lingkaran kiri digantikan langsung oleh DynamicIslandAlert agar mulus tanpa tumpang tindih
              Visibility(
                visible: !_isIslandActive,
                maintainSize: true,
                maintainAnimation: true,
                maintainState: true,
                child: leftCircle,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 220),
                  opacity: hideRight ? 0.0 : 1.0,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    layoutBuilder: (currentChild, previousChildren) => Stack(
                      alignment: Alignment.centerLeft,
                      children: [
                        ...previousChildren,
                        ?currentChild,
                      ],
                    ),
                    transitionBuilder: (child, anim) =>
                        FadeTransition(opacity: anim, child: child),
                    child: KeyedSubtree(
                      key: ValueKey(_currentIndex),
                      child: textColumn,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 220),
                opacity: hideRight ? 0.0 : 1.0,
                child: const SyncStatusIndicator(),
              ),
            ],
          );
        },
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
                _buildTopHeader(),
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
                          if (!_isProgrammaticScroll && _currentIndex != index) {
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
            Positioned(
              top: 10,
              left: 18,
              right: 18,
              child: DynamicIslandAlert(
                originTabIndex: _currentIndex,
                onActiveChanged: (active) {
                  if (_isIslandActive != active && mounted) {
                    setState(() => _isIslandActive = active);
                  }
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        color: AppColors.neuBase,
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 4,
          bottom: MediaQuery.paddingOf(context).bottom > 0
              ? MediaQuery.paddingOf(context).bottom + 4
              : 10,
        ),
        child: NeuBox(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
          borderRadius: BorderRadius.circular(25),
          child: AnimatedBuilder(
            animation: Listenable.merge([_pillController, _pageController]),
            builder: (context, _) {
              final pos = _pillController.isAnimating
                  ? _pillAnim.value
                  : (!_isProgrammaticScroll &&
                          _pageController.hasClients &&
                          _pageController.page != null
                      ? _pageController.page!
                      : _pillPos);

              return LayoutBuilder(
                builder: (context, constraints) {
                  final totalWidth = constraints.maxWidth;
                  const double barHeight = 46.0;
                  final slots = LiquidBubbleNavGeometry.computeSlots(
                    totalWidth: totalWidth,
                    pos: pos,
                    labelWidths: _labelWidths,
                  );

                  return SizedBox(
                    height: barHeight,
                    child: Stack(
                      children: [
                        // ── GELEMBUNG AIR / METABALL LAYER ──
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _LiquidBubbleNavPainter(
                              pos: pos,
                              slots: slots,
                            ),
                          ),
                        ),

                        // ── NAV ITEMS (IKON + STRETCH TEKS + PADDING PROPORSIONAL) ──
                        Row(
                          children: List.generate(_navItems.length, (index) {
                            final slot = slots[index];
                            return SizedBox(
                              width: slot.width,
                              child: _navItem(
                                index,
                                _navItems[index],
                                slot.expansion,
                                slot.textFactor,
                              ),
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

  Widget _navItem(
    int index,
    _NavItemData item,
    double expansion,
    double textFactor,
  ) {
    final isActiveIcon = expansion > 0.5;
    final iconColor = Color.lerp(
      AppColors.textSecondary,
      AppColors.textPrimary,
      expansion,
    )!;
    final iconScale = 1.0 + (0.06 * expansion);
    final textOpacity = LiquidBubbleNavGeometry.smoothstep(
      ((textFactor - 0.12) / 0.88).clamp(0.0, 1.0),
    );
    final hPad = 4.0 + 6.0 * expansion;
    final labelAreaWidth = (6.0 + _labelWidths[index]) * textFactor;

    return GestureDetector(
      onTap: () => switchToTab(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: double.infinity,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: hPad),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Transform.scale(
                    scale: iconScale,
                    child: Icon(
                      isActiveIcon ? item.activeIcon : item.icon,
                      size: 20,
                      color: iconColor,
                    ),
                  ),
                  if (textFactor > 0.01)
                    SizedBox(
                      width: labelAreaWidth,
                      child: Opacity(
                        opacity: textOpacity,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(width: 6),
                              Text(
                                item.label,
                                maxLines: 1,
                                softWrap: false,
                                style: _navLabelStyle,
                              ),
                            ],
                          ),
                        ),
                      ),
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
