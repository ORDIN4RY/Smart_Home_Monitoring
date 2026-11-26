import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../screens/main_navigation.dart';
import 'neu_box.dart';

class AcDialCard extends StatefulWidget {
  final double? currentTemp;
  final double? targetTemp;
  final bool? isOn;
  final bool isAutoMode;
  final int? peltierPwm;
  final bool readOnly;
  final VoidCallback? onTapToControl;
  final ValueChanged<bool>? onInteractionChanged;
  final ValueChanged<bool>? onToggle;
  final ValueChanged<double>? onTempChanged;
  final ValueChanged<bool>? onAutoModeChanged;

  const AcDialCard({
    super.key,
    required this.currentTemp,
    required this.targetTemp,
    required this.isOn,
    required this.isAutoMode,
    this.peltierPwm,
    this.readOnly = false,
    this.onTapToControl,
    this.onInteractionChanged,
    required this.onToggle,
    this.onTempChanged,
    this.onAutoModeChanged,
  });

  @override
  State<AcDialCard> createState() => _AcDialCardState();
}

class _AcDialCardState extends State<AcDialCard> {
  double? _stagedTemp;
  bool _isDraggingDial = false;

  @override
  void initState() {
    super.initState();
    _stagedTemp = widget.targetTemp;
  }

  bool _isNearDialArc(Offset localPos, Size size) {
    final center = Offset(size.width / 2, size.height - 10);
    final radius = size.width / 2 - 16;
    final dist = (localPos - center).distance;
    return dist >= (radius - 30) &&
        dist <= (radius + 22) &&
        localPos.dy <= (center.dy + 16);
  }

  @override
  void didUpdateWidget(covariant AcDialCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.targetTemp != widget.targetTemp) {
      _stagedTemp = widget.targetTemp;
    }
  }

  void _updateTempFromPosition(Offset localPos, Size size) {
    if (widget.readOnly || _stagedTemp == null) return;
    final center = Offset(size.width / 2, size.height - 10);
    final dx = localPos.dx - center.dx;
    final dy = localPos.dy - center.dy;

    double angle = atan2(dy, dx);
    if (angle > 0) {
      angle = dx < 0 ? -pi : 0;
    }

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
    if (widget.readOnly || _stagedTemp == null) return;
    final newTemp = (_stagedTemp! + delta).clamp(16.0, 32.0);
    if (_stagedTemp != newTemp) {
      setState(() {
        _stagedTemp = newTemp;
      });
      widget.onTempChanged?.call(newTemp);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasCoolingState = widget.isOn != null;
    final coolingActive = widget.isOn == true;
    final pwmValue = (coolingActive && widget.peltierPwm != null)
        ? widget.peltierPwm!.clamp(0, 100)
        : 0;

    final String topBadgeText = widget.readOnly
        ? (_stagedTemp != null
            ? 'Target Suhu: ${_stagedTemp!.toStringAsFixed(0)}°C'
            : 'Target Suhu: --')
        : (widget.currentTemp != null
            ? 'Suhu Ruang: ${widget.currentTemp!.toStringAsFixed(1)}°C'
            : 'Suhu Ruang: Tidak Terdeteksi');
    final bool topBadgeActive =
        widget.readOnly ? _stagedTemp != null : widget.currentTemp != null;

    final String powerPillLabel = !hasCoolingState
        ? '-- '
        : (coolingActive ? 'On. ' : 'Off. ');

    final String pwmDisplayText;
    if (!hasCoolingState) {
      pwmDisplayText = 'Tidak Terdeteksi';
    } else if (!coolingActive) {
      pwmDisplayText = 'OFF (0%)';
    } else if (widget.peltierPwm == null) {
      pwmDisplayText = 'Tidak Terdeteksi';
    } else {
      pwmDisplayText = '$pwmValue%';
    }

    final String pwmSubtitle;
    if (!hasCoolingState) {
      pwmSubtitle = 'Status pendingin tidak terdeteksi.';
    } else if (!coolingActive) {
      pwmSubtitle = 'Pendingin nonaktif.';
    } else if (widget.currentTemp == null) {
      pwmSubtitle = 'Suhu ruang tidak terdeteksi.';
    } else {
      pwmSubtitle = widget.isAutoMode
          ? 'Otomatis menyesuaikan daya pendingin sesuai suhu.'
          : 'Pendingin beroperasi pada daya manual.';
    }

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
                isPressed: coolingActive,
                shape: BoxShape.circle,
                padding: const EdgeInsets.all(10),
                child: Icon(
                  Icons.ac_unit,
                  size: 20,
                  color: hasCoolingState ? AppColors.textPrimary : AppColors.textMuted,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pendingin Ruangan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Kontrol Suhu & Pendingin',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              NeuBox(
                onTap: widget.onToggle != null
                    ? () => widget.onToggle!(!coolingActive)
                    : null,
                isPressed: coolingActive,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                borderRadius: BorderRadius.circular(20),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      powerPillLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: hasCoolingState ? AppColors.textPrimary : AppColors.textMuted,
                      ),
                    ),
                    Icon(
                      Icons.power_settings_new,
                      size: 14,
                      color: coolingActive ? AppColors.textPrimary : AppColors.textMuted,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Info Target Suhu (Dashboard shortcut) / Suhu Ruang (Control)
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: widget.readOnly ? widget.onTapToControl : null,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.neuBase,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.neuDarkShadow.withAlpha(110),
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
                      Icons.thermostat_outlined,
                      size: 14,
                      color: topBadgeActive
                          ? AppColors.textSecondary
                          : AppColors.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      topBadgeText,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: topBadgeActive
                            ? AppColors.textSecondary
                            : AppColors.textMuted,
                      ),
                    ),
                    if (widget.readOnly) ...[
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ],
                ),
              ),
            ),
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
                      if (!widget.readOnly && _stagedTemp != null && _isNearDialArc(e.localPosition, size)) {
                        _isDraggingDial = true;
                        widget.onInteractionChanged?.call(true);
                        MainNavigation.setSwipeEnabled(false);
                        _updateTempFromPosition(e.localPosition, size);
                      }
                    },
                    onPointerMove: (e) {
                      if (!widget.readOnly && _isDraggingDial) {
                        _updateTempFromPosition(e.localPosition, size);
                      }
                    },
                    onPointerUp: (_) {
                      if (!widget.readOnly && _isDraggingDial) {
                        _isDraggingDial = false;
                        widget.onInteractionChanged?.call(false);
                        MainNavigation.setSwipeEnabled(true);
                      }
                    },
                    onPointerCancel: (_) {
                      if (!widget.readOnly && _isDraggingDial) {
                        _isDraggingDial = false;
                        widget.onInteractionChanged?.call(false);
                        MainNavigation.setSwipeEnabled(true);
                      }
                    },
                    behavior: HitTestBehavior.opaque,
                    child: GestureDetector(
                      onTap: widget.readOnly ? widget.onTapToControl : null,
                      child: CustomPaint(
                        painter: _SemiCircleGaugePainter(
                          value: widget.readOnly
                              ? widget.currentTemp?.clamp(16.0, 32.0)
                              : _stagedTemp,
                          minValue: 16,
                          maxValue: 32,
                        ),
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.readOnly
                                    ? (widget.currentTemp != null
                                        ? '${widget.currentTemp!.toStringAsFixed(1)}°C'
                                        : '--°C')
                                    : (_stagedTemp != null
                                        ? '${_stagedTemp!.toStringAsFixed(0)}°C'
                                        : '--°C'),
                                style: TextStyle(
                                  fontSize: 34,
                                  fontWeight: FontWeight.bold,
                                  color: (widget.readOnly
                                              ? widget.currentTemp != null
                                              : _stagedTemp != null)
                                      ? AppColors.textPrimary
                                      : AppColors.textMuted,
                                  letterSpacing: -1,
                                  height: 1.0,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  widget.readOnly
                                      ? (widget.currentTemp != null
                                          ? 'Suhu Ruang'
                                          : 'Tidak Terdeteksi')
                                      : (_stagedTemp != null
                                          ? 'Target Suhu'
                                          : 'Tidak Terdeteksi'),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Quick Temperature Steppers / Adjustment (Hanya tampil di Control Screen!)
          if (!widget.readOnly && widget.onTempChanged != null) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                NeuBox(
                  onTap: _stagedTemp != null ? () => _stepTemp(-1) : null,
                  shape: BoxShape.circle,
                  padding: const EdgeInsets.all(9),
                  child: Icon(
                    Icons.remove,
                    size: 16,
                    color: _stagedTemp != null ? AppColors.textPrimary : AppColors.textMuted,
                  ),
                ),
                const SizedBox(width: 18),
                Text(
                  _stagedTemp != null
                      ? 'Set Target: ${_stagedTemp!.toStringAsFixed(0)}°C'
                      : 'Target: Tidak Terdeteksi',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: _stagedTemp != null ? AppColors.textPrimary : AppColors.textMuted,
                  ),
                ),
                const SizedBox(width: 18),
                NeuBox(
                  onTap: _stagedTemp != null ? () => _stepTemp(1) : null,
                  shape: BoxShape.circle,
                  padding: const EdgeInsets.all(9),
                  child: Icon(
                    Icons.add,
                    size: 16,
                    color: _stagedTemp != null ? AppColors.textPrimary : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 16),

          // Daya Pendingin Box
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
                          Icons.speed,
                          size: 15,
                          color: coolingActive ? AppColors.activeBlue : AppColors.textMuted,
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Daya Pendingin:',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      pwmDisplayText,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: (coolingActive && widget.peltierPwm != null)
                            ? AppColors.textPrimary
                            : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    height: 6,
                    color: const Color(0xFFD3DCE8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        width: MediaQuery.of(context).size.width * (pwmValue / 100),
                        color: coolingActive ? const Color(0xFF242C38) : Colors.transparent,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  pwmSubtitle,
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
  final double? value;
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

    const startAngle = pi;
    const sweepAngle = pi;
    const totalTicks = 45;

    final hasValue = value != null;
    final progressPercent = hasValue ? ((value! - minValue) / (maxValue - minValue)).clamp(0.0, 1.0) : -1.0;

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

      final tickFraction = i / totalTicks;
      final isReached = hasValue && tickFraction <= progressPercent;

      final paint = Paint()
        ..color = isReached ? const Color(0xFF242C38) : const Color(0xFFB4C2D3)
        ..strokeWidth = isMajor ? 2.2 : 1.2
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(p1, p2, paint);
    }

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

    if (hasValue) {
      final needleAngle = startAngle + (sweepAngle * progressPercent);
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
    }

    _drawLabel(canvas, '16°', Offset(center.dx - radius + 22, center.dy - 12));
    _drawLabel(canvas, '24°', Offset(center.dx, center.dy - radius + 32));
    _drawLabel(canvas, '32°', Offset(center.dx + radius - 22, center.dy - 12));
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
