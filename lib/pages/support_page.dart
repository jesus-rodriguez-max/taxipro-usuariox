// lib/pages/support_page.dart

import 'package:flutter/material.dart';

/// Página de soporte para la app de pasajeros.
/// Incluye un formulario sencillo para enviar solicitudes de ayuda.
class SupportPage extends StatefulWidget {
  const SupportPage({super.key});

  @override
  State<SupportPage> createState() => _SupportPageState();
}

class _SupportPageState extends State<SupportPage> {
  final TextEditingController _messageController = TextEditingController();
  bool _sending = false;

  Future<void> _sendRequest() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;
    setState(() {
      _sending = true;
    });
    // Aquí se llamaría a un servicio para enviar la solicitud de soporte.
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      _sending = false;
    });
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Solicitud de soporte enviada.')),
      );
    }
    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Soporte'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Describe tu problema o duda y nuestro equipo de soporte '
              'te responderá lo antes posible.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _messageController,
              maxLines: 4,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Escribe tu mensaje aquí',
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _sending ? null : _sendRequest,
              child: _sending
                  ? const CircularProgressIndicator()
                  : const Text('Enviar'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}
