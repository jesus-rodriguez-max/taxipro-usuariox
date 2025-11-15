import 'package:flutter/material.dart';
import 'app_icons.dart';

class TxIconSize {
  static const double xs = 16;
  static const double s = 20;
  static const double m = 24;
  static const double l = 28;
  static const double xl = 32;
}

class TxIcon extends StatelessWidget {
  final AppIcon icon;
  final double size;
  final String? semanticLabel;

  const TxIcon(this.icon, {super.key, this.size = TxIconSize.m, this.semanticLabel});

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final path = isLight ? icon.light : icon.dark;
    final dpr = MediaQuery.of(context).devicePixelRatio;
    final int targetPx = (size * dpr).clamp(16.0, 256.0).toInt();
    final altPath = isLight ? icon.dark : icon.light;
    return Semantics(
      label: semanticLabel,
      child: Image.asset(
        path,
        width: size,
        height: size,
        fit: BoxFit.contain,
        cacheWidth: targetPx,
        cacheHeight: targetPx,
        errorBuilder: (context, error, stack) {
          // Log de diagnóstico: ruta del asset que falló
          // ignore: avoid_print
          debugPrint('TxIcon: Unable to load asset → ' + path + ' | error: ' + error.toString());
          // Intentar la variante alternativa (light/dark)
          return Image.asset(
            altPath,
            width: size,
            height: size,
            fit: BoxFit.contain,
            cacheWidth: targetPx,
            cacheHeight: targetPx,
            errorBuilder: (context, error2, stack2) {
              debugPrint('TxIcon: Also failed alternative asset → ' + altPath + ' | error: ' + error2.toString());
              return Icon(
                Icons.image_not_supported_outlined,
                size: size,
                color: Theme.of(context).iconTheme.color?.withOpacity(0.8),
              );
            },
          );
        },
      ),
    );
  }
}
