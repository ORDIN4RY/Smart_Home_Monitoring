import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'neu_box.dart';
import 'neu_switch.dart';
import 'status_badge.dart';

class DeviceSwitchCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool isOn;
  final bool? isAutoMode;
  final ValueChanged<bool>? onToggle;
  final ValueChanged<bool>? onAutoModeChanged;
  final Widget? extraWidget;

  const DeviceSwitchCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.isOn,
    this.isAutoMode,
    this.onToggle,
    this.onAutoModeChanged,
    this.extraWidget,
  });

  @override
  Widget build(BuildContext context) {
    return NeuBox(
      padding: const EdgeInsets.all(18),
      borderRadius: BorderRadius.circular(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              NeuBox(
                isPressed: isOn,
                shape: BoxShape.circle,
                padding: const EdgeInsets.all(12),
                child: Icon(
                  icon,
                  color: isOn ? AppColors.textPrimary : AppColors.textMuted,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              NeuSwitch(
                value: isOn,
                onChanged: (isAutoMode == true) ? null : onToggle,
              ),
            ],
          ),
          if (isAutoMode != null) ...[
            const SizedBox(height: 14),
            NeuBox(
              isPressed: true,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              borderRadius: BorderRadius.circular(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Mode Kontrol:',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      StatusBadge(
                        label: isAutoMode! ? 'Otomatis' : 'Manual',
                        type: isAutoMode! ? BadgeType.active : BadgeType.warning,
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Auto',
                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                      const SizedBox(width: 8),
                      NeuSwitch(
                        width: 44,
                        height: 24,
                        value: isAutoMode!,
                        onChanged: onAutoModeChanged,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          if (extraWidget != null) ...[
            const SizedBox(height: 12),
            extraWidget!,
          ],
        ],
      ),
    );
  }
}
