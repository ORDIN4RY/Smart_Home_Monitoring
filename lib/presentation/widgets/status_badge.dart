import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

enum BadgeType { normal, active, warning, danger }

class StatusBadge extends StatelessWidget {
  final String label;
  final BadgeType type;
  final IconData? icon;

  const StatusBadge({
    super.key,
    required this.label,
    required this.type,
    this.icon,
  });

  Color get _color {
    switch (type) {
      case BadgeType.normal:
        return AppColors.normal;
      case BadgeType.active:
        return AppColors.primary;
      case BadgeType.warning:
        return AppColors.warning;
      case BadgeType.danger:
        return AppColors.danger;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF131315),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _color.withAlpha(60),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.neuDarkShadow.withAlpha(180),
            offset: const Offset(1.5, 1.5),
            blurRadius: 3,
          ),
          BoxShadow(
            color: AppColors.neuLightShadow.withAlpha(70),
            offset: const Offset(-1, -1),
            blurRadius: 2,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: _color),
            const SizedBox(width: 4),
          ] else ...[
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: _color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _color.withAlpha(120),
                    blurRadius: 3,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              color: _color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
