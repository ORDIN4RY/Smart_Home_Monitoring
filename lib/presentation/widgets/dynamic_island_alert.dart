import 'dart:math' as math;
import 'dart:ui' show lerpDouble;
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../data/services/alert_manager.dart';

class DynamicIslandAlert extends StatefulWidget {
  final int originTabIndex;
  final ValueChanged<bool>? onActiveChanged;

  const DynamicIslandAlert({
    super.key,
    this.originTabIndex = 0,
    this.onActiveChanged,
  });

  @override
  State<DynamicIslandAlert> createState() => _DynamicIslandAlertState();
}

class _DynamicIslandAlertState extends State<DynamicIslandAlert>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  List<DynamicAlert> _displayedAlerts = [];
  List<DynamicAlert>? _queuedAlerts;

  static const TextStyle _titleStyle = TextStyle(
    fontSize: 12.5,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    letterSpacing: -0.2,
    height: 1.25,
  );

  static const TextStyle _msgStyle = TextStyle(
    fontSize: 11,
    color: AppColors.textSecondary,
    height: 1.3,
  );

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 620),
      reverseDuration: const Duration(milliseconds: 420),
    )..addStatusListener(_onAnimationStatus);

    AlertManager.activeAlerts.addListener(_onAlertsChanged);
    _onAlertsChanged();
  }

  @override
  void dispose() {
    _controller.removeStatusListener(_onAnimationStatus);
    AlertManager.activeAlerts.removeListener(_onAlertsChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onAnimationStatus(AnimationStatus status) {
    if (status != AnimationStatus.dismissed || !mounted) return;
    if (_queuedAlerts != null && _queuedAlerts!.isNotEmpty) {
      final next = _queuedAlerts!;
      _queuedAlerts = null;
      setState(() => _displayedAlerts = next);
      widget.onActiveChanged?.call(true);
      _controller.forward();
    } else if (AlertManager.activeAlerts.value.isEmpty &&
        _displayedAlerts.isNotEmpty) {
      setState(() => _displayedAlerts = []);
      widget.onActiveChanged?.call(false);
    }
  }

  void _onAlertsChanged() {
    final alerts = AlertManager.activeAlerts.value;
    if (alerts.isNotEmpty) {
      if (_displayedAlerts.isEmpty) {
        _queuedAlerts = null;
        setState(() => _displayedAlerts = alerts);
        widget.onActiveChanged?.call(true);
        _controller.forward();
      } else if (_controller.status == AnimationStatus.reverse) {
        _queuedAlerts = alerts;
      } else {
        _queuedAlerts = null;
        setState(() => _displayedAlerts = alerts);
      }
    } else {
      _queuedAlerts = null;
      if (_displayedAlerts.isNotEmpty) {
        _controller.reverse();
      }
    }
  }

  Color _getPriorityColor(AlertPriority p) {
    switch (p) {
      case AlertPriority.danger:
        return AppColors.danger;
      case AlertPriority.warning:
        return AppColors.warning;
      case AlertPriority.info:
        return AppColors.activeBlue;
    }
  }

  IconData _originIcon() {
    switch (widget.originTabIndex) {
      case 0:
        return Icons.person;
      case 1:
        return Icons.tune;
      case 2:
        return Icons.shield_outlined;
      case 3:
      default:
        return Icons.history;
    }
  }

  double _measureItemHeight(
    DynamicAlert alert,
    double maxWidth,
    TextScaler textScaler, {
    required bool isFirst,
  }) {
    final textWidth = (maxWidth - 100.0).clamp(120.0, double.infinity);

    final titlePainter = TextPainter(
      text: TextSpan(text: alert.title, style: _titleStyle),
      textDirection: TextDirection.ltr,
      textScaler: textScaler,
      maxLines: 2,
    )..layout(maxWidth: textWidth);

    final double msgHeight;
    if (alert.message.isEmpty) {
      msgHeight = 0.0;
    } else {
      final msgPainter = TextPainter(
        text: TextSpan(text: alert.message, style: _msgStyle),
        textDirection: TextDirection.ltr,
        textScaler: textScaler,
        maxLines: 3,
      )..layout(maxWidth: textWidth);
      msgHeight = 2.0 + msgPainter.height;
    }

    final headerHeight =
        math.max(isFirst ? 46.0 : 38.0, titlePainter.height + msgHeight + (isFirst ? 18.0 : 8.0));
    final photoHeight = alert.imageUrl != null ? 256.0 : 0.0;
    return headerHeight + photoHeight;
  }

  double _measureExpandedHeight(
    List<DynamicAlert> alerts,
    double maxWidth,
    TextScaler textScaler,
    double maxAllowedHeight,
  ) {
    double total = 0.0;
    for (int i = 0; i < alerts.length; i++) {
      total += _measureItemHeight(
        alerts[i],
        maxWidth,
        textScaler,
        isFirst: i == 0,
      );
      if (i > 0) {
        total += 17.0;
      }
    }
    return total.clamp(46.0, maxAllowedHeight);
  }

  @override
  Widget build(BuildContext context) {
    if (_displayedAlerts.isEmpty) return const SizedBox.shrink();

    final alert = _displayedAlerts.first;
    final alertColor = _getPriorityColor(alert.priority);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final textScaler = MediaQuery.textScalerOf(context);
    final maxAllowedHeight =
        (MediaQuery.sizeOf(context).height * 0.68).clamp(260.0, 620.0);
    final isDashboardOrigin = widget.originTabIndex == 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        const double originSize = 46.0;
        final double maxWidth =
            constraints.maxWidth.clamp(originSize, double.infinity);
        final double targetHeight = _measureExpandedHeight(
          _displayedAlerts,
          maxWidth,
          textScaler,
          maxAllowedHeight,
        );

        return TweenAnimationBuilder<double>(
          tween: Tween<double>(end: targetHeight),
          duration: reduceMotion
              ? Duration.zero
              : const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          builder: (context, smoothTargetHeight, _) {
            return AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final rawT = _controller.value.clamp(0.0, 1.0);
                final double widthT = reduceMotion
                    ? 1.0
                    : Curves.easeOutCubic.transform((rawT / 0.78).clamp(0.0, 1.0));
                final double heightT = reduceMotion
                    ? 1.0
                    : Curves.easeOutCubic
                        .transform(((rawT - 0.30) / 0.70).clamp(0.0, 1.0));
                final double morphT =
                    reduceMotion ? 1.0 : Curves.easeOut.transform((rawT / 0.45).clamp(0.0, 1.0));
                final double contentOpacity = reduceMotion
                    ? 1.0
                    : Curves.easeOut.transform(((rawT - 0.42) / 0.58).clamp(0.0, 1.0));

                final double currentWidth = lerpDouble(originSize, maxWidth, widthT)!;
                final double currentHeight =
                    lerpDouble(originSize, smoothTargetHeight, heightT)!;

            // Morph mulus dari NeuBox recessed (rawT=0) -> pill neumorphic terangkat (rawT=1)
            final gradTopLeft = Color.lerp(
              const Color(0xFFD2DCE8),
              const Color(0xFFE9EEF5),
              morphT,
            )!;
            final gradBottomRight = Color.lerp(
              const Color(0xFFEFF4FA),
              const Color(0xFFDCDEE5),
              morphT,
            )!;
            final borderColor = Color.lerp(
              const Color(0xFFC8D3E2).withAlpha(130),
              Colors.transparent,
              morphT,
            )!;

            // Morph lingkaran dalam dari lingkaran profil/tab -> lingkaran icon notif
            final innerCircleColor = Color.lerp(
              isDashboardOrigin ? const Color(0xFF242C38) : Colors.transparent,
              alertColor.withAlpha(24),
              morphT,
            )!;
            final originIconColor = isDashboardOrigin
                ? const Color(0xFFE2E7EE)
                : AppColors.textPrimary;
            final showAlertIcon = rawT > 0.12;

            return Align(
              alignment: Alignment.topLeft,
              child: GestureDetector(
                onTap: () {
                  if (alert.onTap != null) {
                    alert.onTap!.call();
                  } else if (alert.imageUrl != null) {
                    _showImagePreview(context, alert);
                  }
                },
                onHorizontalDragEnd: (details) {
                  if (details.primaryVelocity != null &&
                      details.primaryVelocity! < -150) {
                    AlertManager.clear(markDismissed: true);
                  }
                },
                onVerticalDragEnd: (details) {
                  if (details.primaryVelocity != null &&
                      details.primaryVelocity! < -150) {
                    AlertManager.clear(markDismissed: true);
                  }
                },
                child: Container(
                  width: currentWidth,
                  height: currentHeight,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.neuBase,
                    borderRadius: BorderRadius.circular(originSize / 2),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [gradTopLeft, gradBottomRight],
                    ),
                    border: Border.all(color: borderColor, width: 1.0),
                    boxShadow: [
                      if (morphT > 0.01) ...[
                        BoxShadow(
                          color: AppColors.neuDarkShadow
                              .withAlpha((160 * morphT).round()),
                          offset: Offset(5.0 * morphT, 5.0 * morphT),
                          blurRadius: 12.0 * morphT,
                        ),
                        BoxShadow(
                          color: AppColors.neuLightShadow
                              .withAlpha((240 * morphT).round()),
                          offset: Offset(-5.0 * morphT, -5.0 * morphT),
                          blurRadius: 12.0 * morphT,
                        ),
                      ],
                    ],
                  ),
                  child: SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: innerCircleColor,
                        ),
                        child: Center(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 240),
                            transitionBuilder: (child, anim) => ScaleTransition(
                              scale: anim,
                              child: FadeTransition(opacity: anim, child: child),
                            ),
                            child: showAlertIcon
                                ? Icon(
                                    alert.icon,
                                    key: ValueKey('alert_${alert.id}'),
                                    size: 18,
                                    color: alertColor,
                                  )
                                : Icon(
                                    _originIcon(),
                                    key: ValueKey('origin_${widget.originTabIndex}'),
                                    size: isDashboardOrigin ? 20 : 19,
                                    color: originIconColor,
                                  ),
                          ),
                        ),
                      ),
                      if (contentOpacity > 0.01 && currentWidth > 125) ...[
                        const SizedBox(width: 10),
                        Expanded(
                          child: Opacity(
                            opacity: contentOpacity,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(minHeight: 36),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 220),
                                  switchInCurve: Curves.easeOut,
                                  switchOutCurve: Curves.easeIn,
                                  layoutBuilder: (currentChild, previousChildren) =>
                                      Stack(
                                    alignment: Alignment.centerLeft,
                                    children: [
                                      ...previousChildren,
                                      if (currentChild != null) currentChild,
                                    ],
                                  ),
                                  child: Column(
                                    key: ValueKey('content_${alert.id}'),
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        alert.title,
                                        style: _titleStyle,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (alert.message.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          alert.message,
                                          style: _msgStyle,
                                          maxLines: 3,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Opacity(
                          opacity: contentOpacity,
                          child: SizedBox(
                            height: 36,
                            child: Center(
                              child: GestureDetector(
                                onTap: () => AlertManager.dismiss(alert.id),
                                child: Container(
                                  margin: const EdgeInsets.only(right: 4),
                                  padding: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.neuBase,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.neuDarkShadow.withAlpha(120),
                                        offset: const Offset(1, 1),
                                        blurRadius: 2,
                                      ),
                                      const BoxShadow(
                                        color: AppColors.neuLightShadow,
                                        offset: Offset(-1, -1),
                                        blurRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    size: 13,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                      if (alert.imageUrl != null &&
                          contentOpacity > 0.01 &&
                          heightT > 0.45 &&
                          currentWidth > 140) ...[
                        const SizedBox(height: 10),
                        Opacity(
                          opacity: contentOpacity,
                          child: Center(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.network(
                                alert.imageUrl!,
                                height: 240,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) =>
                                    const SizedBox.shrink(),
                              ),
                            ),
                          ),
                        ),
                      ],
                      if (contentOpacity > 0.01 && currentWidth > 140)
                        for (final extra in _displayedAlerts.skip(1)) ...[
                          Opacity(
                            opacity: contentOpacity,
                            child: Divider(
                              height: 17,
                              thickness: 1,
                              color: AppColors.border.withAlpha(110),
                            ),
                          ),
                          Opacity(
                            opacity: contentOpacity,
                            child: _buildStackedAlertItem(context, extra),
                          ),
                        ],
                    ],
                  ),
                ),
                ),
              ),
            );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildStackedAlertItem(BuildContext context, DynamicAlert item) {
    final itemColor = _getPriorityColor(item.priority);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (item.onTap != null) {
          item.onTap!.call();
        } else if (item.imageUrl != null) {
          _showImagePreview(context, item);
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: itemColor.withAlpha(24),
                ),
                child: Center(
                  child: Icon(item.icon, size: 18, color: itemColor),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 36),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: _titleStyle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (item.message.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            item.message,
                            style: _msgStyle,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              SizedBox(
                height: 36,
                child: Center(
                  child: GestureDetector(
                    onTap: () => AlertManager.dismiss(item.id),
                    child: Container(
                      margin: const EdgeInsets.only(right: 4),
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.neuBase,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.neuDarkShadow.withAlpha(120),
                            offset: const Offset(1, 1),
                            blurRadius: 2,
                          ),
                          const BoxShadow(
                            color: AppColors.neuLightShadow,
                            offset: Offset(-1, -1),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (item.imageUrl != null) ...[
            const SizedBox(height: 10),
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  item.imageUrl!,
                  height: 240,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showImagePreview(BuildContext context, DynamicAlert alert) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.neuBase,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      alert.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: _getPriorityColor(alert.priority),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 360),
                  child: Image.network(
                    alert.imageUrl!,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const SizedBox(
                      height: 150,
                      child: Center(child: Text('Foto gagal dimuat')),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                alert.message,
                style: const TextStyle(fontSize: 12.5, color: AppColors.textPrimary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
