import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'neu_box.dart';

class HazardBanner extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final bool isDanger;

  const HazardBanner({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.warning_amber_rounded,
    this.isDanger = true,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDanger ? AppColors.danger : AppColors.warning;

    return NeuBox(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      borderRadius: BorderRadius.circular(20),
      glowColor: color.withAlpha(50),
      glowRadius: 14,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NeuBox(
            isPressed: true,
            shape: BoxShape.circle,
            padding: const EdgeInsets.all(10),
            glowColor: color.withAlpha(60),
            glowRadius: 8,
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: color,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: color.withAlpha(30),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: color.withAlpha(80)),
                      ),
                      child: Text(
                        isDanger ? 'BAHAYA' : 'WASPADA',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textPrimary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
