import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'neu_box.dart';

class SceneCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isActive;
  final VoidCallback onTap;

  const SceneCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return NeuBox(
      onTap: onTap,
      isPressed: isActive,
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Circle icon exactly like reference
              NeuBox(
                isPressed: true,
                shape: BoxShape.circle,
                padding: const EdgeInsets.all(10),
                child: Icon(icon, size: 18, color: AppColors.textPrimary),
              ),
              // Double dots indicator exactly like reference
              const Row(
                children: [
                  Icon(Icons.circle, size: 5, color: AppColors.textMuted),
                  SizedBox(width: 3),
                  Icon(Icons.circle, size: 5, color: AppColors.textMuted),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 2),
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
      ),
    );
  }
}
