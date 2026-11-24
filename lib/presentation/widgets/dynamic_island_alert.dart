import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../data/services/alert_manager.dart';

class DynamicIslandAlert extends StatefulWidget {
  const DynamicIslandAlert({super.key});

  @override
  State<DynamicIslandAlert> createState() => _DynamicIslandAlertState();
}

class _DynamicIslandAlertState extends State<DynamicIslandAlert>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  late Animation<double> _scaleAnimation;
  DynamicAlert? _displayedAlert;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _slideAnimation = Tween<double>(begin: -70.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    AlertManager.currentAlert.addListener(_onAlertChanged);
    _onAlertChanged();
  }

  @override
  void dispose() {
    AlertManager.currentAlert.removeListener(_onAlertChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onAlertChanged() {
    final alert = AlertManager.currentAlert.value;
    if (alert != null) {
      setState(() {
        _displayedAlert = alert;
      });
      _controller.forward();
    } else {
      _controller.reverse().then((_) {
        if (mounted && AlertManager.currentAlert.value == null) {
          setState(() {
            _displayedAlert = null;
          });
        }
      });
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

  @override
  Widget build(BuildContext context) {
    if (_displayedAlert == null) return const SizedBox.shrink();

    final alert = _displayedAlert!;
    final alertColor = _getPriorityColor(alert.priority);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value),
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Opacity(
              opacity: _controller.value.clamp(0.0, 1.0),
              child: child,
            ),
          ),
        );
      },
      child: GestureDetector(
        onTap: () {
          alert.onTap?.call();
        },
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity != null && details.primaryVelocity! < 0) {
            // Geser ke atas untuk menutup
            AlertManager.clear(markDismissed: true);
          }
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.neuBase,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: alertColor.withAlpha(140),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.neuDarkShadow.withAlpha(180),
                offset: const Offset(4, 6),
                blurRadius: 14,
              ),
              const BoxShadow(
                color: AppColors.neuLightShadow,
                offset: Offset(-3, -3),
                blurRadius: 10,
              ),
              BoxShadow(
                color: alertColor.withAlpha(50),
                offset: const Offset(0, 3),
                blurRadius: 10,
              ),
            ],
          ),
          child: Row(
            children: [
              // Pulsing / glowing icon container
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: alertColor.withAlpha(25),
                  border: Border.all(color: alertColor.withAlpha(80)),
                ),
                child: Center(
                  child: Icon(
                    alert.icon,
                    size: 19,
                    color: alertColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Message Column
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alert.title,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      alert.message,
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Dismiss button
              GestureDetector(
                onTap: () => AlertManager.clear(markDismissed: true),
                child: Container(
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
            ],
          ),
        ),
      ),
    );
  }
}
