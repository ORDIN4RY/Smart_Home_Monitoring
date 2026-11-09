import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'neu_box.dart';
import 'status_badge.dart';

class SensorMetricCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String unit;
  final String statusText;
  final BadgeType statusType;
  final Color accentColor;
  final double? progressPercent;

  const SensorMetricCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.unit,
    required this.statusText,
    required this.statusType,
    required this.accentColor,
    this.progressPercent,
  });

  @override
  Widget build(BuildContext context) {
    return NeuBox(
      padding: const EdgeInsets.all(14),
      borderRadius: BorderRadius.circular(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top: Tactile recessed icon socket + status pill
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              NeuBox(
                isPressed: true,
                shape: BoxShape.circle,
                padding: const EdgeInsets.all(8),
                glowColor: accentColor.withAlpha(25),
                glowRadius: 3,
                child: Icon(icon, color: accentColor, size: 18),
              ),
              StatusBadge(label: statusText, type: statusType),
            ],
          ),
          const SizedBox(height: 10),

          // Middle: Numerical Value & Unit in Soft Off-White
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  if (unit.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Text(
                      unit,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          // Bottom: Soft recessed progress track
          if (progressPercent != null) ...[
            const SizedBox(height: 6),
            Container(
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.neuDarkShadow,
                borderRadius: BorderRadius.circular(4),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progressPercent!.clamp(0.0, 1.0),
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                  minHeight: 4,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
