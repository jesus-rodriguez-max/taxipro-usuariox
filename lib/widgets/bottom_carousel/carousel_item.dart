import 'package:flutter/material.dart';

class CarouselItemData {
  final String keyId; // e.g., 'map', 'illustr', 'wallet'
  final IconData icon;
  final String semanticsLabel; // for accessibility/tooltips

  const CarouselItemData({
    required this.keyId,
    required this.icon,
    required this.semanticsLabel,
  });
}

class CarouselItem extends StatelessWidget {
  final CarouselItemData data;
  final bool isCenter;
  final double opacity;
  final double width;
  final double height;

  const CarouselItem({
    super.key,
    required this.data,
    required this.isCenter,
    this.opacity = 1.0,
    this.width = 68,
    this.height = 72,
  });

  @override
  Widget build(BuildContext context) {
    final onBg = Theme.of(context).colorScheme.onBackground;
    const premiumBlue = Color(0xFF007BFF);
    final double border = isCenter ? 2.0 : 0.0;
    final double w = width;
    final double h = height;

    return Tooltip(
      message: data.semanticsLabel,
      child: Semantics(
        label: data.semanticsLabel,
        button: true,
        selected: isCenter,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 160),
          opacity: opacity,
          child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          height: h,
          width: w,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withOpacity(0.92),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isCenter ? premiumBlue : Colors.transparent, width: border),
            boxShadow: [
              // sutil shadow base
              BoxShadow(color: Colors.black26, blurRadius: 8, offset: const Offset(0, 4)),
              if (isCenter)
                BoxShadow(
                  color: premiumBlue.withOpacity(0.35),
                  blurRadius: 14,
                  spreadRadius: 1,
                ),
            ],
          ),
          child: Center(
            child: Icon(
              data.icon,
              size: 28,
              color: onBg,
            ),
          ),
        ),
        ),
      ),
    );
  }
}
