import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class NeuSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final double width;
  final double height;

  const NeuSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.width = 50,
    this.height = 28,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onChanged != null ? () => onChanged!(!value) : null,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        width: width,
        height: height,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: AppColors.neuBase,
          borderRadius: BorderRadius.circular(height / 2),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: value
                ? [
                    const Color(0xFFD3DDEB),
                    const Color(0xFFE8EEF6),
                  ]
                : [
                    const Color(0xFFCFD8E5),
                    const Color(0xFFE4EBF4),
                  ],
          ),
          boxShadow: [
            // Sunken track shadow
            BoxShadow(
              color: AppColors.neuDarkShadow.withAlpha(180),
              offset: const Offset(1.5, 1.5),
              blurRadius: 3,
            ),
            const BoxShadow(
              color: Colors.white,
              offset: Offset(-1.5, -1.5),
              blurRadius: 3,
            ),
          ],
        ),
        child: Align(
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: height - 6,
            height: height - 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: value ? AppColors.textPrimary : const Color(0xFF8C9BAE),
              boxShadow: [
                BoxShadow(
                  color: (value ? Colors.black45 : AppColors.neuDarkShadow).withAlpha(140),
                  offset: const Offset(1, 1),
                  blurRadius: 3,
                ),
              ],
            ),
            child: value
                ? const Center(
                    child: Icon(Icons.check, size: 10, color: Color(0xFFE2E7EE)),
                  )
                : null,
          ),
        ),
      ),
    );
  }
}
