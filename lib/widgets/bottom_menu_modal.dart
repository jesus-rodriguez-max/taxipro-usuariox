import 'dart:ui';
import 'package:flutter/material.dart';
import '../screens/faq_screen.dart';
import '../screens/legal/legal_screen.dart';
import '../screens/support/support_screen.dart';
import '../screens/offline/offline_request_screen.dart';

class BottomMenuModal extends StatelessWidget {
  const BottomMenuModal({super.key});

  static Future<void> show(BuildContext context) async {
    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Menu',
      barrierColor: Colors.black.withOpacity(0.25),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, anim1, anim2) {
        return const SizedBox.shrink();
      },
      transitionBuilder: (context, anim, _, __) {
        final slide = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
            .chain(CurveTween(curve: Curves.easeOutCubic))
            .animate(anim);
        final fade = CurvedAnimation(parent: anim, curve: Curves.easeOut);
        return Stack(
          children: [
            // Blur + darken background
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.of(context).maybePop(),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(color: Colors.transparent),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: SlideTransition(
                position: slide,
                child: FadeTransition(
                  opacity: fade,
                  child: GestureDetector(
                    onVerticalDragEnd: (details) {
                      if (details.primaryVelocity != null && details.primaryVelocity! > 200) {
                        Navigator.of(context).maybePop();
                      }
                    },
                    child: const _BottomSheetContent(),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) => const _BottomSheetContent();
}

class _BottomSheetContent extends StatelessWidget {
  const _BottomSheetContent();

  @override
  Widget build(BuildContext context) {
    final items = <_MenuItem>[
      _MenuItem('Mapa', 'assets/icon/taxipro_icons_pack_v1/light/viajes/mapa_origen.png', () {
        Navigator.of(context).pop();
        Navigator.of(context).pushNamed('/map');
      }),
      _MenuItem('Favoritos', 'assets/icon/taxipro_icons_pack_v1/light/configuracion/estrella.png', () {
        Navigator.of(context).pop();
        Navigator.of(context).pushNamed('/info/illustrations');
      }),
      _MenuItem('Historial', 'assets/icon/taxipro_icons_pack_v1/light/viajes/reloj_auto.png', () {
        Navigator.of(context).pop();
        Navigator.of(context).pushNamed('/trips/history');
      }),
      _MenuItem('Preguntas', 'assets/icon/taxipro_icons_pack_v1/light/soporte/burbuja_pregunta.png', () async {
        Navigator.of(context).pop();
        await Navigator.of(context).push(MaterialPageRoute(builder: (context) => const FaqScreen()));
      }),
      _MenuItem('Soporte', 'assets/icon/taxipro_icons_pack_v1/light/soporte/soporte_persona.png', () async {
        Navigator.of(context).pop();
        await Navigator.of(context).push(MaterialPageRoute(builder: (context) => const SupportScreen()));
      }),
      _MenuItem('Modo Offline', 'assets/icon/taxipro_icons_pack_v1/light/soporte/sms.png', () async {
        Navigator.of(context).pop();
        await Navigator.of(context).push(MaterialPageRoute(builder: (context) => const OfflineRequestScreen()));
      }),
      _MenuItem('Legal', 'assets/icon/taxipro_icons_pack_v1/light/legal/lupa_documento.png', () async {
        Navigator.of(context).pop();
        await Navigator.of(context).push(MaterialPageRoute(builder: (context) => const LegalScreen()));
      }),
      _MenuItem('Configuración', 'assets/icon/taxipro_icons_pack_v1/light/configuracion/engranaje.png', () {
        Navigator.of(context).pop();
        Navigator.of(context).pushNamed('/settings');
      }),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        crossAxisSpacing: 24,
        mainAxisSpacing: 24,
        children: items.map((item) => _GridTile(item: item)).toList(),
      ),
    );
  }
}

class _GridTile extends StatelessWidget {
  final _MenuItem item;
  const _GridTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: item.onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(color: const Color(0x0F000000), borderRadius: BorderRadius.circular(16)),
            alignment: Alignment.center,
            child: Image.asset(item.asset, width: 56, height: 56, filterQuality: FilterQuality.medium),
          ),
          const SizedBox(height: 8),
          Text(
            item.label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF333333)),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _BottomPinnedAction extends StatelessWidget {
  final String label;
  final String asset;
  final VoidCallback onTap;
  const _BottomPinnedAction({required this.label, required this.asset, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          height: 72,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 8)]),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(asset, width: 28, height: 28),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF333333))),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuItem {
  final String label;
  final String asset;
  final VoidCallback onTap;
  _MenuItem(this.label, this.asset, this.onTap);
}
