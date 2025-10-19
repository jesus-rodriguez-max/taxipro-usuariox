import 'package:flutter/material.dart';
import 'package:telephony/telephony.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class SmsRequestScreen extends StatefulWidget {
  const SmsRequestScreen({super.key});

  @override
  State<SmsRequestScreen> createState() => _SmsRequestScreenState();
}

class _SmsRequestScreenState extends State<SmsRequestScreen> {
  final Telephony telephony = Telephony.instance;
  final TextEditingController origenCtrl = TextEditingController();
  final TextEditingController destinoCtrl = TextEditingController();
  final String _dispatchNumber = '+521234567890';
  bool _sending = false;

  Future<bool> _hasInternet() async {
    final dynamic result = await Connectivity().checkConnectivity();
    if (result is List<ConnectivityResult>) {
      return !result.contains(ConnectivityResult.none);
    }
    if (result is ConnectivityResult) {
      return result != ConnectivityResult.none;
    }
    return true;
  }

  Future<void> _enviarSMS() async {
    if (_sending) return;
    setState(() => _sending = true);
    try {
      final hasNet = await _hasInternet();
      if (hasNet) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usa el modo normal, hay conexión.')),
        );
        return;
      }

      final granted = await telephony.requestSmsPermissions;
      if (granted != true) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permiso SMS denegado.')),
        );
        return;
      }

      final mensaje = 'TAXIPRO SOLICITUD:\nDesde: ${origenCtrl.text}\nHasta: ${destinoCtrl.text}';
      await telephony.sendSms(to: _dispatchNumber, message: mensaje);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Solicitud enviada por SMS.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error enviando SMS: $e')),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  void dispose() {
    origenCtrl.dispose();
    destinoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Solicitud Offline TaxiPro'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: origenCtrl,
              decoration: const InputDecoration(labelText: 'Origen'),
            ),
            TextField(
              controller: destinoCtrl,
              decoration: const InputDecoration(labelText: 'Destino'),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _sending ? null : _enviarSMS,
                child: Text(_sending ? 'Enviando...' : 'Enviar solicitud por SMS'),
              ),
            )
          ],
        ),
      ),
    );
  }
}
