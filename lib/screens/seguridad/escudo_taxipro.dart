import 'package:flutter/material.dart';
import 'package:taxipro_usuariox/services/emergency_service.dart';
import 'package:taxipro_usuariox/screens/profile_screen.dart';

class EscudoTaxiProScreen extends StatefulWidget {
  const EscudoTaxiProScreen({super.key});

  @override
  State<EscudoTaxiProScreen> createState() => _EscudoTaxiProScreenState();
}

class _EscudoTaxiProScreenState extends State<EscudoTaxiProScreen> {
  int _tapCount = 0;
  DateTime? _firstTapAt;

  void _handleShieldTap() {
    final now = DateTime.now();
    if (_firstTapAt == null || now.difference(_firstTapAt!).inMilliseconds > 1500) {
      _firstTapAt = now;
      _tapCount = 1;
      setState(() {});
      return;
    }
    _tapCount += 1;
    if (_tapCount >= 3) {
      _tapCount = 0;
      _firstTapAt = null;
      EmergencyService.activatePanic(context);
    } else {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escudo TaxiPro'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 8),
          Center(
            child: GestureDetector(
              onTap: _handleShieldTap,
              child: Column(
                children: [
                  Image.asset('assets/branding/escudo_modal.png', height: 180, fit: BoxFit.contain),
                  const SizedBox(height: 12),
                  Text('Toca 3 veces para activar emergencia (911 + WhatsApp)', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(child: Image.asset('assets/illustrations/compartir_viaje.png', height: 120)),
          const SizedBox(height: 12),
          Text('Escudo de Seguridad Taxi Pro', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Text('- Conductores verificados con licencia oficial.', style: textStyle),
          Text('- Viajes monitoreados en tiempo real.', style: textStyle),
          Text('- Política clara de cancelaciones.', style: textStyle),
          Text('- Protección legal y soporte directo.', style: textStyle),
          Text('- Pago seguro sin tarifas ocultas.', style: textStyle),
          Text('- Integración con grabación de emergencia en caso de incidente.', style: textStyle),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
            icon: const Icon(Icons.contact_phone),
            label: const Text('Configurar contacto de confianza'),
          ),
        ],
      ),
    );
  }
}
