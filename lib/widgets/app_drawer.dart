import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:taxipro_usuariox/services/app_config_service.dart';
import 'package:taxipro_usuariox/utils/device_capabilities.dart';
import 'package:taxipro_usuariox/widgets/tx_icon.dart';
import 'package:taxipro_usuariox/widgets/app_icons.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final onBg = Theme.of(context).colorScheme.onBackground;
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              margin: EdgeInsets.zero,
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Image.asset('assets/branding/logo_complete.png', height: 72),
              ),
            ),
            // 1. Mapa
            _itemIcon(context, MissingIconsV2.map, 'Mapa', () {
              Navigator.of(context).pushNamedAndRemoveUntil('/map', (route) => false);
            }, onBg),
            // 2. Ilustraciones
            _itemIcon(context, MissingIconsV2.star, 'Ilustraciones', () {
              Navigator.of(context).pushNamed('/info/illustrations');
            }, onBg),
            // 3. Wallet
            _itemIcon(context, AppIcons.wallet, 'Wallet', () {
              Navigator.of(context).pushNamed('/wallet');
            }, onBg),
            // 4. Preguntas
            _itemIcon(context, MissingIconsV2.question, 'Preguntas', () {
              Navigator.of(context).pushNamed('/faq');
            }, onBg),
            // 5. Soporte
            _itemIcon(context, AppIcons.phone, 'Soporte', () {
              Navigator.of(context).pushNamed('/support');
            }, onBg),
            // 6. Escudo Taxi Pro (gated)
            if (AppConfigService.instance.shieldEnabled)
              _itemIcon(context, MissingIconsV2.shieldInfo, 'Escudo Taxi Pro', () {
                Navigator.of(context).pushNamed('/safety');
              }, onBg),
            // 7. Solicitud sin Internet (SMS) (gated por flag + capacidad)
            FutureBuilder<bool>(
              future: AppConfigService.instance.offlineRequestsEnabled ? DeviceCapabilities.canSendSms() : Future.value(false),
              builder: (context, snap) {
                final enabled = snap.data == true;
                final tile = ListTile(
                  leading: Opacity(
                    opacity: enabled ? 1 : 0.5,
                    child: TxIcon(MissingIconsV2.map, size: 22, semanticLabel: 'SMS'),
                  ),
                  title: Text('Solicitud sin Internet (SMS)', style: TextStyle(color: onBg.withOpacity(enabled ? 1 : 0.6))),
                  enabled: enabled,
                  onTap: enabled
                      ? () {
                          Navigator.of(context).pushNamed('/offline/request');
                        }
                      : null,
                );
                if (enabled) return tile;
                return Tooltip(message: 'No disponible en este dispositivo.', child: tile);
              },
            ),
            // 8. Aviso de Privacidad y Términos
            _itemIcon(context, AppIcons.search, 'Aviso de Privacidad y Términos', () {
              Navigator.of(context).pushNamed('/legal');
            }, onBg),
            // 9. Configuración
            _itemIcon(context, AppIcons.settings, 'Configuración', () {
              Navigator.of(context).pushNamed('/settings');
            }, onBg),
            const Divider(),
            // 10. Cerrar sesión
            _itemIcon(context, MissingIconsV2.exitDoor, 'Cerrar sesión', () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
              }
            }, onBg),
          ],
        ),
      ),
    );
  }

  Widget _itemIcon(BuildContext context, AppIcon icon, String title, VoidCallback onTap, Color onBg) {
    return ListTile(
      leading: TxIcon(icon, size: 22, semanticLabel: title),
      title: Text(title, style: TextStyle(color: onBg)),
      onTap: onTap,
    );
  }
}
