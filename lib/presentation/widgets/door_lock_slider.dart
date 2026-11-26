import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';

/// Tactile Neumorphic Door Lock Toggle Switch
/// Mendukung status null (Tidak Terdeteksi) dan mode sibuk (sedang proses buka/tutup)
class DoorLockToggle extends StatefulWidget {
  final bool? isLocked;
  final ValueChanged<bool>? onChanged;
  final bool isLoading;
  final double width;
  final double height;

  const DoorLockToggle({
    super.key,
    required this.isLocked,
    required this.onChanged,
    this.isLoading = false,
    this.width = 68.0,
    this.height = 36.0,
  });

  @override
  State<DoorLockToggle> createState() => _DoorLockToggleState();
}

class _DoorLockToggleState extends State<DoorLockToggle>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _slideAnimation;
  bool _isDragging = false;
  double _dragValue = 0.0; // 0.0 = Terkunci (kiri), 0.5 = Tidak Terdeteksi, 1.0 = Terbuka (kanan)

  double _targetFor(bool? locked) {
    if (locked == null) return 0.5;
    return locked ? 0.0 : 1.0;
  }

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
      value: _targetFor(widget.isLocked),
    );
    _slideAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeOutCubic,
    );
    _dragValue = _animController.value;

    _animController.addListener(() {
      if (!_isDragging) {
        setState(() {
          _dragValue = _animController.value;
        });
      }
    });
  }

  @override
  void didUpdateWidget(covariant DoorLockToggle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isLocked != widget.isLocked && !_isDragging) {
      final target = _targetFor(widget.isLocked);
      if ((_animController.value - target).abs() > 0.01) {
        _animController.animateTo(target);
      }
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  bool get _isInteractive => !widget.isLoading && widget.onChanged != null;

  void _handleTap() {
    if (!_isInteractive || _isDragging) return;
    HapticFeedback.lightImpact();
    final newLocked = widget.isLocked == null ? false : !widget.isLocked!;
    final target = newLocked ? 0.0 : 1.0;

    _animController.animateTo(target).then((_) {
      if (mounted) {
        HapticFeedback.selectionClick();
        widget.onChanged?.call(newLocked);
      }
    });
  }

  void _onHorizontalDragStart(DragStartDetails details) {
    if (!_isInteractive) return;
    HapticFeedback.selectionClick();
    setState(() {
      _isDragging = true;
    });
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details, double maxTravel) {
    if (!_isInteractive || maxTravel <= 0) return;
    final delta = details.primaryDelta ?? 0;
    final newValue = (_dragValue + (delta / maxTravel)).clamp(0.0, 1.0);
    _animController.value = newValue;
    setState(() {
      _dragValue = newValue;
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (!_isInteractive) return;
    _isDragging = false;

    if (widget.isLocked == true) {
      if (_dragValue >= 0.45) {
        _animController.animateTo(1.0).then((_) {
          if (mounted) {
            HapticFeedback.selectionClick();
            widget.onChanged?.call(false);
          }
        });
      } else {
        _animController.animateTo(0.0);
      }
    } else if (widget.isLocked == false) {
      if (_dragValue <= 0.55) {
        _animController.animateTo(0.0).then((_) {
          if (mounted) {
            HapticFeedback.selectionClick();
            widget.onChanged?.call(true);
          }
        });
      } else {
        _animController.animateTo(1.0);
      }
    } else {
      if (_dragValue >= 0.65) {
        _animController.animateTo(1.0).then((_) {
          if (mounted) {
            HapticFeedback.selectionClick();
            widget.onChanged?.call(false);
          }
        });
      } else if (_dragValue <= 0.35) {
        _animController.animateTo(0.0).then((_) {
          if (mounted) {
            HapticFeedback.selectionClick();
            widget.onChanged?.call(true);
          }
        });
      } else {
        _animController.animateTo(0.5);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const padding = 3.0;
    final knobSize = widget.height - (padding * 2);
    final maxTravel = widget.width - knobSize - (padding * 2);

    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        final currentValue = _isDragging ? _dragValue : _slideAnimation.value;
        final knobOffset = currentValue * maxTravel;
        final isUnknown = widget.isLocked == null && !widget.isLoading;

        final Color activeColor;
        if (widget.isLoading) {
          activeColor = AppColors.activeBlue;
        } else if (isUnknown) {
          activeColor = AppColors.textMuted;
        } else {
          activeColor = Color.lerp(
            AppColors.normal,
            AppColors.warning,
            currentValue,
          )!;
        }

        final trackStart = isUnknown
            ? const Color(0xFFD5DDE8)
            : Color.lerp(
                const Color(0xFFCFD9E5),
                const Color(0xFFDFD6C9),
                currentValue,
              )!;
        final trackEnd = isUnknown
            ? const Color(0xFFE5ECF4)
            : Color.lerp(
                const Color(0xFFE8EEF6),
                const Color(0xFFF7EFE8),
                currentValue,
              )!;

        final isUnlockedVisually = currentValue > 0.5;

        return GestureDetector(
          onTap: _isInteractive ? _handleTap : null,
          onHorizontalDragStart: _isInteractive ? _onHorizontalDragStart : null,
          onHorizontalDragUpdate:
              _isInteractive ? (d) => _onHorizontalDragUpdate(d, maxTravel) : null,
          onHorizontalDragEnd: _isInteractive ? _onHorizontalDragEnd : null,
          behavior: HitTestBehavior.opaque,
          child: Opacity(
            opacity: _isInteractive || widget.isLoading ? 1.0 : 0.72,
            child: Container(
              width: widget.width,
              height: widget.height,
              padding: const EdgeInsets.all(padding),
              decoration: BoxDecoration(
                color: AppColors.neuBase,
                borderRadius: BorderRadius.circular(widget.height / 2),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [trackStart, trackEnd],
                ),
                boxShadow: [
                  BoxShadow(
                    color: activeColor.withAlpha((15 + (currentValue * 25)).toInt()),
                    offset: Offset.zero,
                    blurRadius: 6,
                  ),
                  BoxShadow(
                    color: AppColors.neuDarkShadow.withAlpha(160),
                    offset: const Offset(1.5, 1.5),
                    blurRadius: 3,
                  ),
                  const BoxShadow(
                    color: Colors.white,
                    offset: Offset(-1.5, -1.5),
                    blurRadius: 3,
                  ),
                ],
                border: Border.all(
                  color: Color.lerp(
                    const Color(0xFFC4D0E0),
                    activeColor.withAlpha(80),
                    0.35,
                  )!,
                  width: 1.0,
                ),
              ),
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  Positioned(
                    left: knobOffset,
                    child: Container(
                      width: knobSize,
                      height: knobSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.neuBase,
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFFFFFFFF),
                            Color(0xFFDBE2EC),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: activeColor.withAlpha(40),
                            offset: Offset.zero,
                            blurRadius: 4,
                          ),
                          BoxShadow(
                            color: AppColors.neuDarkShadow.withAlpha(140),
                            offset: const Offset(1.5, 1.5),
                            blurRadius: 3,
                          ),
                          const BoxShadow(
                            color: Colors.white,
                            offset: Offset(-1.5, -1.5),
                            blurRadius: 2.5,
                          ),
                        ],
                      ),
                      child: Center(
                        child: widget.isLoading
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.activeBlue,
                                ),
                              )
                            : AnimatedSwitcher(
                                duration: const Duration(milliseconds: 180),
                                transitionBuilder: (child, anim) => ScaleTransition(
                                  scale: anim,
                                  child: FadeTransition(opacity: anim, child: child),
                                ),
                                child: Icon(
                                  isUnknown
                                      ? Icons.help_outline_rounded
                                      : (isUnlockedVisually
                                          ? Icons.lock_open_rounded
                                          : Icons.lock_rounded),
                                  key: ValueKey<String>(
                                    isUnknown ? 'unknown' : (isUnlockedVisually ? 'open' : 'locked'),
                                  ),
                                  size: 15,
                                  color: activeColor,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

typedef DoorLockSlider = DoorLockToggle;
