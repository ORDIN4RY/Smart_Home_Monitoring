import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class NeuBox extends StatelessWidget {
  final Widget? child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final bool isPressed;
  final BoxShape shape;
  final Color? color;
  final Color? glowColor;
  final double glowRadius;
  final VoidCallback? onTap;

  const NeuBox({
    super.key,
    this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius,
    this.isPressed = false,
    this.shape = BoxShape.rectangle,
    this.color,
    this.glowColor,
    this.glowRadius = 0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = borderRadius ?? BorderRadius.circular(22);
    final baseColor = color ?? AppColors.neuBase;

    BoxDecoration decoration;

    if (isPressed) {
      // Inset / Sunken effect in Light Neumorphism
      decoration = BoxDecoration(
        color: baseColor,
        shape: shape,
        borderRadius: shape == BoxShape.circle ? null : effectiveRadius,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFD2DCE8), // Sunken dark corner
            Color(0xFFEFF4FA), // Sunken light reflection
          ],
        ),
        boxShadow: [
          if (glowColor != null && glowRadius > 0)
            BoxShadow(
              color: glowColor!,
              offset: Offset.zero,
              blurRadius: glowRadius,
              spreadRadius: 1,
            ),
        ],
        border: Border.all(
          color: (glowColor != null)
              ? glowColor!.withAlpha(120)
              : const Color(0xFFC8D3E2).withAlpha(130),
          width: 1.0,
        ),
      );
    } else {
      // Extruded 3D soft tactile elevation
      decoration = BoxDecoration(
        color: baseColor,
        shape: shape,
        borderRadius: shape == BoxShape.circle ? null : effectiveRadius,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFE9EEF5), // Soft white highlight top-left
            Color(0xFFDCDEE5), // Soft base bottom-right
          ],
        ),
        boxShadow: AppColors.neuElevation(
          distance: 5.5,
          blur: 13.0,
          glowColor: glowColor,
          glowRadius: glowRadius,
        ),
      );
    }

    Widget content = Container(
      width: width,
      height: height,
      margin: margin,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: decoration,
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: content,
      );
    }

    return content;
  }
}
