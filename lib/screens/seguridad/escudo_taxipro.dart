import 'package:flutter/material.dart';

class EscudoTaxiProScreen extends StatelessWidget {
  const EscudoTaxiProScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escudo TaxiPro'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/branding/isotipo_tp.png',
                height: 120,
              ),
              const SizedBox(height: 24),
              const Text(
                'Protegido por Escudo TaxiPro',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Botón de seguridad y monitoreo de viaje. Próximamente se integrará la lógica avanzada de emergencia y contactos de confianza.',
                style: TextStyle(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
