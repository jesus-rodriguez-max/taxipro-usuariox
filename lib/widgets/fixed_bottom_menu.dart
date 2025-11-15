import 'package:flutter/material.dart';
import 'package:taxipro_usuariox/widgets/tx_icon.dart';
import 'package:taxipro_usuariox/widgets/app_icons.dart';

class FixedBottomMenu extends StatelessWidget {
  const FixedBottomMenu({super.key, required this.onLeft, required this.onCenter, required this.onRight, this.leftLabel = 'Wallet', this.centerLabel = '¿A dónde?', this.rightLabel = 'Soporte'});

  final VoidCallback onLeft;
  final VoidCallback onCenter;
  final VoidCallback onRight;
  final String leftLabel;
  final String centerLabel;
  final String rightLabel;

  static const double height = 84.0;

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

class _Item extends StatelessWidget {
  const _Item({required this.icon, required this.label, required this.onTap, required this.textStyle, this.emphasize = false});
  final AppIcon icon;
  final String label;
  final VoidCallback onTap;
  final TextStyle textStyle;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = emphasize ? scheme.primary : scheme.onSurface;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 28, child: TxIcon(icon, size: 28, semanticLabel: label)),
            const SizedBox(height: 6),
            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: textStyle.copyWith(color: emphasize ? scheme.primary : scheme.onSurface.withOpacity(0.92))),
          ],
        ),
      ),
    );
  }
}
