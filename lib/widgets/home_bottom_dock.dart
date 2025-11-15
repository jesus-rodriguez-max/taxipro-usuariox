import 'package:flutter/material.dart';

class HomeBottomDock extends StatelessWidget {
  final VoidCallback onOpenMenu;
  final VoidCallback onOpenWallet;
  final VoidCallback onOpenShield;

  const HomeBottomDock({
    super.key,
    required this.onOpenMenu,
    required this.onOpenWallet,
    required this.onOpenShield,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: EdgeInsets.zero,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _DockItem(
              label: 'Menú',
              asset: 'assets/icon/taxipro_icons_pack_v1/dark/configuracion/engranaje.png',
              onTap: onOpenMenu,
            ),
            _DockItem(
              label: 'Wallet',
              asset: 'assets/icon/taxipro_icons_pack_v1/dark/pagos/tarjeta.png',
              onTap: onOpenWallet,
            ),
            _DockItem(
              label: 'Escudo',
              asset: 'assets/icon/taxipro_icons_pack_v1/dark/security/escudo_tp.png',
              onTap: onOpenShield,
            ),
          ],
        ),
      ),
    );
  }
}

class _DockItem extends StatelessWidget {
  final String label;
  final String asset;
  final VoidCallback onTap;

  const _DockItem({required this.label, required this.asset, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(asset, height: 48, filterQuality: FilterQuality.high),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.black87)),
        ],
      ),
    );
  }
}
