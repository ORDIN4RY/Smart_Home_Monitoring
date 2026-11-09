import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'neu_box.dart';

class AcDialCard extends StatelessWidget {
  final double currentTemp;
  final double targetTemp;
  final bool isOn;
  final bool isAutoMode;
  final ValueChanged<bool> onToggle;
  final ValueChanged<double>? onTempChanged;

  const AcDialCard({
    super.key,
    required this.currentTemp,
    required this.targetTemp,
    required this.isOn,
    required this.isAutoMode,
    required this.onToggle,
    this.onTempChanged,
  });

  @override
  Widget build(BuildContext context) {
    return NeuBox(
      padding: const EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Snowflake + Titles + On/Off Pill Button
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              NeuBox(
                isPressed: isOn,
                shape: BoxShape.circle,
                padding: const EdgeInsets.all(10),
                child: const Icon(
                  Icons.ac_unit,
                  size: 20,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Air Conditioner',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Peltier Auto Cooling',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Neumorphic On/Off Pill exactly like image ("On. ⏻")
              NeuBox(
                onTap: () => onToggle(!isOn),
                isPressed: isOn,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                borderRadius: BorderRadius.circular(20),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isOn ? 'On. ' : 'Off. ',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Icon(
                      Icons.power_settings_new,
                      size: 14,
                      color: isOn ? AppColors.textPrimary : AppColors.textMuted,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Small Timer / Auto Badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.neuBase,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.neuDarkShadow.withAlpha(120),
                      offset: const Offset(1.5, 1.5),
                      blurRadius: 3,
                    ),
                    const BoxShadow(
                      color: AppColors.neuLightShadow,
                      offset: Offset(-1.5, -1.5),
                      blurRadius: 3,
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.alarm, size: 12, color: AppColors.textSecondary),
                    SizedBox(width: 4),
                    Text(
                      'Auto',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Semi-circular Dial Gauge with Radial Ticks & Pointer
          Center(
            child: SizedBox(
              width: 250,
              height: 155,
              child: CustomPaint(
                painter: _SemiCircleGaugePainter(
                  value: targetTemp,
                  minValue: 10,
                  maxValue: 40,
                ),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${targetTemp.toStringAsFixed(0)}°',
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                          letterSpacing: -1,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Temprature',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Quick Temperature Steppers / Adjustment Slider
          if (onTempChanged != null) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                NeuBox(
                  onTap: () {
                    if (targetTemp > 16) onTempChanged!(targetTemp - 1);
                  },
                  shape: BoxShape.circle,
                  padding: const EdgeInsets.all(8),
                  child: const Icon(Icons.remove, size: 16, color: AppColors.textPrimary),
                ),
                const SizedBox(width: 24),
                Text(
                  'Ruangan: ${currentTemp.toStringAsFixed(1)}°C',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                ),
                const SizedBox(width: 24),
                NeuBox(
                  onTap: () {
                    if (targetTemp < 32) onTempChanged!(targetTemp + 1);
                  },
                  shape: BoxShape.circle,
                  padding: const EdgeInsets.all(8),
                  child: const Icon(Icons.add, size: 16, color: AppColors.textPrimary),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _SemiCircleGaugePainter extends CustomPainter {
  final double value;
  final double minValue;
  final double maxValue;

  _SemiCircleGaugePainter({
    required this.value,
    required this.minValue,
    required this.maxValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height - 10);
    final radius = size.width / 2 - 16;

    const startAngle = pi;     // 180° (kiri)
    const sweepAngle = pi;     // 180° arc (sampai 0° / kanan)
    const totalTicks = 45;

    // Draw ticks around the perimeter
    for (int i = 0; i <= totalTicks; i++) {
      final tickAngle = startAngle + (sweepAngle * (i / totalTicks));
      final isMajor = i % 5 == 0;
      final tickLength = isMajor ? 14.0 : 8.0;

      final p1 = Offset(
        center.dx + (radius - tickLength) * cos(tickAngle),
        center.dy + (radius - tickLength) * sin(tickAngle),
      );

      final p2 = Offset(
        center.dx + radius * cos(tickAngle),
        center.dy + radius * sin(tickAngle),
      );

      // Past/active ticks have darker color, future ticks have softer grey
      final progressPercent = (value - minValue) / (maxValue - minValue);
      final tickFraction = i / totalTicks;
      final isReached = tickFraction <= progressPercent;

      final paint = Paint()
        ..color = isReached ? const Color(0xFF242C38) : const Color(0xFFB4C2D3)
        ..strokeWidth = isMajor ? 2.2 : 1.2
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(p1, p2, paint);
    }

    // Inner dashed guide arc
    final dashPaint = Paint()
      ..color = const Color(0xFFC5D2E2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 26),
      startAngle + 0.1,
      sweepAngle - 0.2,
      false,
      dashPaint,
    );

    // Draw needle pointer with small circular head pointing at the value
    final progress = ((value - minValue) / (maxValue - minValue)).clamp(0.0, 1.0);
    final needleAngle = startAngle + (sweepAngle * progress);
    final needleRadius = radius + 6;

    final needleTip = Offset(
      center.dx + needleRadius * cos(needleAngle),
      center.dy + needleRadius * sin(needleAngle),
    );

    final needleStart = Offset(
      center.dx + (radius - 22) * cos(needleAngle),
      center.dy + (radius - 22) * sin(needleAngle),
    );

    final needleLinePaint = Paint()
      ..color = const Color(0xFF242C38)
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(needleStart, needleTip, needleLinePaint);

    final needleCirclePaint = Paint()
      ..color = AppColors.neuBase
      ..style = PaintingStyle.fill;

    final needleCircleBorder = Paint()
      ..color = const Color(0xFF242C38)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;

    canvas.drawCircle(needleTip, 4.5, needleCirclePaint);
    canvas.drawCircle(needleTip, 4.5, needleCircleBorder);

    // Draw text labels: 10°, 20°, 40°
    _drawLabel(canvas, '10°', Offset(center.dx - radius + 22, center.dy - 12));
    _drawLabel(canvas, '20°', Offset(center.dx, center.dy - radius + 32));
    _drawLabel(canvas, '40°', Offset(center.dx + radius - 22, center.dy - 12));
  }

  void _drawLabel(Canvas canvas, String text, Offset position) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: Color(0xFF8695A8),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(position.dx - textPainter.width / 2, position.dy - textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _SemiCircleGaugePainter oldDelegate) {
    return oldDelegate.value != value;
  }
}
