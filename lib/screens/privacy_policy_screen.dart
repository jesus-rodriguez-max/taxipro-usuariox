import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  final VoidCallback onAccepted;

  const PrivacyPolicyScreen({super.key, required this.onAccepted});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Permitir volver atrás temporalmente para evitar quedar atrapado si hay errores
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Aviso de Privacidad'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
        body: const Padding(
          padding: EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Text(
              'Aquí va el texto completo del Aviso de Privacidad...\n\n' 
              'Lorem ipsum dolor sit amet, consectetur adipiscing elit. ...'
            ),
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: ElevatedButton(
              onPressed: () {
                debugPrint('🟡 Botón Aceptar (Privacidad) presionado');
                onAccepted();
                debugPrint('🟢 Callback onAccepted ejecutado');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text(
                'He leído y acepto el Aviso de Privacidad',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
