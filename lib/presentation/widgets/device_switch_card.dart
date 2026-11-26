import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'neu_box.dart';
import 'neu_switch.dart';

class DeviceSwitchCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool? isOn;
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
    final active = isOn == true;
    final available = isOn != null;

    return NeuBox(
      padding: const EdgeInsets.all(18),
      borderRadius: BorderRadius.circular(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              NeuBox(
                isPressed: active,
                shape: BoxShape.circle,
                padding: const EdgeInsets.all(12),
                child: Icon(
                  icon,
                  color: active
                      ? AppColors.textPrimary
                      : (available ? AppColors.textMuted : AppColors.textMuted),
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
                      style: TextStyle(
                        fontSize: 12,
                        color: available ? AppColors.textSecondary : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              NeuSwitch(
                value: active,
                onChanged: (isAutoMode == true) ? null : onToggle,
              ),
            ],
          ),
          if (isAutoMode != null) ...[
            const SizedBox(height: 12),
            NeuBox(
              isPressed: true,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              borderRadius: BorderRadius.circular(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.auto_mode,
                        size: 16,
                        color: isAutoMode! ? AppColors.activeBlue : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Mode Otomatis',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isAutoMode! ? AppColors.textPrimary : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  NeuSwitch(
                    width: 44,
                    height: 24,
                    value: isAutoMode!,
                    onChanged: onAutoModeChanged,
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
