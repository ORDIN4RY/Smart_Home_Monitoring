import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../screens/main_navigation.dart';
import 'neu_box.dart';

class AcDialCard extends StatefulWidget {
  final double currentTemp;
  final double targetTemp;
  final bool isOn;
  final bool isAutoMode;
  final int? peltierPwm;
  final ValueChanged<bool> onToggle;
  final ValueChanged<double>? onTempChanged;
  final ValueChanged<bool>? onAutoModeChanged;

  const AcDialCard({
    super.key,
    required this.currentTemp,
    required this.targetTemp,
    required this.isOn,
    required this.isAutoMode,
    this.peltierPwm,
    required this.onToggle,
    this.onTempChanged,
    this.onAutoModeChanged,
  });

  @override
  State<AcDialCard> createState() => _AcDialCardState();
}

class _AcDialCardState extends State<AcDialCard> {
  late double _stagedTemp;

  @override
  void initState() {
    super.initState();
    _stagedTemp = widget.targetTemp;
  }

  @override
  void didUpdateWidget(covariant AcDialCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.targetTemp != widget.targetTemp) {
      _stagedTemp = widget.targetTemp;
    }
  }

  void _updateTempFromPosition(Offset localPos, Size size) {
    final center = Offset(size.width / 2, size.height - 10);
    final dx = localPos.dx - center.dx;
    final dy = localPos.dy - center.dy;

    // Hitung sudut sentuhan dalam busur setengah lingkaran atas
    double angle = atan2(dy, dx);
    if (angle > 0) {
      angle = dx < 0 ? -pi : 0;
    }

    // Pemetaan sudut (-pi s/d 0) ke rentang suhu 16°C - 32°C secara linear tanpa area kosong
    const minTemp = 16.0;
    const maxTemp = 32.0;
    final fraction = ((angle + pi) / pi).clamp(0.0, 1.0);
    final calculatedTemp = (minTemp + fraction * (maxTemp - minTemp)).roundToDouble();
    final clampedTemp = calculatedTemp.clamp(minTemp, maxTemp);

    if (_stagedTemp != clampedTemp) {
      setState(() {
        _stagedTemp = clampedTemp;
      });
      widget.onTempChanged?.call(clampedTemp);
    }
  }

  void _stepTemp(double delta) {
    final newTemp = (_stagedTemp + delta).clamp(16.0, 32.0);
    if (_stagedTemp != newTemp) {
      setState(() {
        _stagedTemp = newTemp;
      });
      widget.onTempChanged?.call(newTemp);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pwmValue = (widget.isOn ? (widget.peltierPwm ?? 0) : 0).clamp(0, 100);

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
                isPressed: widget.isOn,
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
                      'Pendingin Peltier',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Kontrol Modul MOSFET PWM',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Neumorphic On/Off Pill ("On. ⏻" / "Off. ⏻")
              NeuBox(
                onTap: () => widget.onToggle(!widget.isOn),
                isPressed: widget.isOn,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                borderRadius: BorderRadius.circular(20),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.isOn ? 'On. ' : 'Off. ',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Icon(
                      Icons.power_settings_new,
                      size: 14,
                      color: widget.isOn ? AppColors.textPrimary : AppColors.textMuted,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Auto Mode Badge / Toggle & Target Info
          Row(
            children: [
              GestureDetector(
                onTap: widget.onAutoModeChanged != null
                    ? () => widget.onAutoModeChanged!(!widget.isAutoMode)
                    : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.neuBase,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.neuDarkShadow.withAlpha(widget.isAutoMode ? 160 : 100),
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
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        widget.isAutoMode ? Icons.auto_awesome : Icons.tune,
                        size: 12,
                        color: widget.isAutoMode ? AppColors.activeBlue : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        widget.isAutoMode ? 'Auto Suhu ON' : 'Manual Mode',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: widget.isAutoMode ? AppColors.textPrimary : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              Text(
                'Suhu Ruang: ${widget.currentTemp.toStringAsFixed(1)}°C',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Semi-circular Dial Gauge with Interactive Drag Gesture
          Center(
            child: SizedBox(
              width: 250,
              height: 155,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final size = Size(constraints.maxWidth, constraints.maxHeight);
                  return Listener(
                    onPointerDown: (e) {
                      MainNavigation.setSwipeEnabled(false);
                      _updateTempFromPosition(e.localPosition, size);
                    },
                    onPointerMove: (e) {
                      _updateTempFromPosition(e.localPosition, size);
                    },
                    onPointerUp: (_) {
                      MainNavigation.setSwipeEnabled(true);
                    },
                    onPointerCancel: (_) {
                      MainNavigation.setSwipeEnabled(true);
                    },
                    behavior: HitTestBehavior.opaque,
                    child: CustomPaint(
                      painter: _SemiCircleGaugePainter(
                        value: _stagedTemp,
                        minValue: 16,
                        maxValue: 32,
                      ),
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${_stagedTemp.toStringAsFixed(0)}°C',
                              style: const TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                                letterSpacing: -1,
                                height: 1.0,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Target Suhu',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 6),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Quick Temperature Steppers / Adjustment
          if (widget.onTempChanged != null) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                NeuBox(
                  onTap: () => _stepTemp(-1),
                  shape: BoxShape.circle,
                  padding: const EdgeInsets.all(9),
                  child: const Icon(Icons.remove, size: 16, color: AppColors.textPrimary),
                ),
                const SizedBox(width: 18),
                Text(
                  'Set Target: ${_stagedTemp.toStringAsFixed(0)}°C',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(width: 18),
                NeuBox(
                  onTap: () => _stepTemp(1),
                  shape: BoxShape.circle,
                  padding: const EdgeInsets.all(9),
                  child: const Icon(Icons.add, size: 16, color: AppColors.textPrimary),
                ),
              ],
            ),
          ],

          const SizedBox(height: 16),

          // Modul MOSFET PWM Duty Cycle Box
          NeuBox(
            isPressed: true,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            borderRadius: BorderRadius.circular(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.bolt,
                          size: 15,
                          color: widget.isOn ? AppColors.activeBlue : AppColors.textMuted,
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Modul MOSFET PWM:',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      widget.isOn ? '$pwmValue%' : 'OFF (0%)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: widget.isOn ? AppColors.textPrimary : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Neumorphic Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    height: 6,
                    color: const Color(0xFFD3DCE8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        width: MediaQuery.of(context).size.width * (pwmValue / 100),
                        color: widget.isOn ? const Color(0xFF242C38) : Colors.transparent,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.isOn
                      ? (widget.isAutoMode
                          ? 'Otomatis menyesuaikan duty cycle PWM sesuai suhu.'
                          : 'Peltier beroperasi pada daya manual.')
                      : 'Peltier mati.',
                  style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
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
