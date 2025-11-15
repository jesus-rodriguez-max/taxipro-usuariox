import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SphereButton extends StatefulWidget {
  final IconData icon;
  final Color c1;
  final Color c2;
  final bool active;
  final double opacity;
  final VoidCallback onTap;
  final String semantics;

  const SphereButton({
    super.key,
    required this.icon,
    required this.c1,
    required this.c2,
    required this.active,
    required this.opacity,
    required this.onTap,
    required this.semantics,
  });

  @override
  State<SphereButton> createState() => _SphereButtonState();
}

class _SphereButtonState extends State<SphereButton> {
  bool _pulse = false;
  Timer? _timer;

  Color _saturate(Color c, [double amount = 0.25]) {
    final hsl = HSLColor.fromColor(c);
    final s = (hsl.saturation * (1.0 + amount)).clamp(0.0, 1.0);
    return hsl.withSaturation(s).toColor();
  }

  @override
  void didUpdateWidget(covariant SphereButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.active && widget.active) {
      _triggerPulse();
      HapticFeedback.selectionClick();
    }
  }

  void _triggerPulse() {
    _timer?.cancel();
    setState(() => _pulse = true);
    _timer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _pulse = false);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c1Sat = _saturate(widget.c1, 0.25);
    final c2Sat = _saturate(widget.c2, 0.25);
    final iconContrastBase = c2Sat; // usar borde más profundo para contraste
    final iconColor = iconContrastBase.computeLuminance() > 0.6 ? Colors.black : Colors.white;

    return RepaintBoundary(
      child: Tooltip(
        message: widget.semantics,
        child: Semantics(
          label: widget.semantics,
          button: true,
          selected: widget.active,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 160),
            opacity: widget.opacity,
            child: AnimatedScale(
              duration: const Duration(milliseconds: 300),
              curve: Curves.elasticOut,
              scale: widget.active ? 1.20 : 1.0,
              child: GestureDetector(
                onTap: () {
                  if (widget.active) {
                    HapticFeedback.selectionClick();
                  }
                  widget.onTap();
                },
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Base sphere with electric RADIAL gradient and outer shadow
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Colors.white.withOpacity(0.40), // iluminación interior
                              c1Sat,
                              c2Sat, // borde profundo
                            ],
                            stops: const [0.0, 0.25, 1.0],
                            center: Alignment.topLeft,
                            radius: 1.05,
                          ),
                          boxShadow: [
                            const BoxShadow(color: Colors.black26, blurRadius: 10, spreadRadius: 1, offset: Offset(0, 4)),
                            if (widget.active) ...[
                              const BoxShadow(color: Colors.white30, blurRadius: 14, spreadRadius: 1),
                              BoxShadow(color: c1Sat.withOpacity(0.40), blurRadius: 25, spreadRadius: 2),
                            ],
                          ],
                        ),
                      ),
                      // Inner shadow overlay (suave) y highlight especular
                      IgnorePointer(
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                Colors.white.withOpacity(0.12), // highlight sutil
                                Colors.transparent,
                                Colors.black.withOpacity(0.18), // leve oscurecimiento en borde
                              ],
                              stops: const [0.0, 0.72, 1.0],
                              center: Alignment.topLeft,
                              radius: 1.0,
                            ),
                          ),
                        ),
                      ),
                      // Glossy top rim (crystal-like)
                      IgnorePointer(
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment(0.0, 0.35),
                              colors: [
                                Colors.white.withOpacity(0.18),
                                Colors.white.withOpacity(0.0),
                              ],
                              stops: const [0.0, 1.0],
                            ),
                          ),
                        ),
                      ),
                      // Pulse / wave light when becoming active
                      if (_pulse)
                        AnimatedOpacity(
                          opacity: 0.0,
                          duration: const Duration(milliseconds: 300),
                          child: AnimatedScale(
                            scale: 1.15,
                            duration: const Duration(milliseconds: 300),
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    Colors.white.withOpacity(0.35),
                                    Colors.white.withOpacity(0.0),
                                  ],
                                  stops: const [0.0, 1.0],
                                  center: Alignment.center,
                                  radius: 0.9,
                                ),
                              ),
                            ),
                          ),
                        ),
                      // Icon
                      Icon(widget.icon, size: 28, color: iconColor),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
