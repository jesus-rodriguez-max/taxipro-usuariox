import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
// import 'package:taxipro_usuariox/widgets/app_drawer.dart'; // Drawer desactivado temporalmente
import 'package:taxipro_usuariox/ui/ui_constants.dart';

class OfflineSentScreen extends StatelessWidget {
  const OfflineSentScreen({super.key, required this.number});
  final String number;

  Future<void> _openSmsApp(BuildContext context) async {
    final uri = Uri(scheme: 'sms', path: number);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo abrir la app de SMS.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final onBg = Theme.of(context).colorScheme.onBackground;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          color: onBg,
          onPressed: () => Navigator.of(context).pushNamed('/map'),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('SMS enviado', style: TextStyle(color: onBg, fontWeight: FontWeight.w800, fontSize: 20)),
            const SizedBox(height: 8),
            Text('Revisa tus mensajes para la respuesta de TaxiPro.', style: TextStyle(color: onBg)),
            const SizedBox(height: 8),
            Text('Número de TaxiPro: $number', style: TextStyle(color: onBg.withOpacity(0.9))),
            const Spacer(),
            SizedBox(
              height: kButtonHeight,
              child: ElevatedButton(
                onPressed: () => _openSmsApp(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kCornerRadius)),
                ),
                child: const Text('Abrir app de SMS'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: kButtonHeight,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil('/map', (r) => false),
                child: const Text('Volver al mapa'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
