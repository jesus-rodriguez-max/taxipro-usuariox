import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _sending = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      await FirebaseFirestore.instance.collection('support_messages').add({
        'uid': user?.uid,
        'email': user?.email,
        'subject': _subjectCtrl.text.trim(),
        'message': _messageCtrl.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'app': 'usuariox',
      });
      if (!mounted) return;
      _subjectCtrl.clear();
      _messageCtrl.clear();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mensaje enviado. ¡Gracias!')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al enviar: $e')));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Soporte Técnico'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('¿Tuviste un problema con la app, tu viaje o quieres hacer una sugerencia?\n', style: textStyle),
          Text('Contáctanos:', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('Teléfono de atención directa: 489 118 4467', style: textStyle),
          const SizedBox(height: 16),
          Text('Desde la app:', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('Llena el formulario de contacto y cuéntanos tu problema o sugerencia. Aunque no podemos garantizar respuesta inmediata, leemos todos los mensajes y damos seguimiento.\n', style: textStyle),
          const Divider(),
          const SizedBox(height: 8),
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _subjectCtrl,
                  decoration: const InputDecoration(labelText: 'Asunto', border: OutlineInputBorder()),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Escribe un asunto' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _messageCtrl,
                  maxLines: 5,
                  decoration: const InputDecoration(labelText: 'Mensaje', border: OutlineInputBorder()),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Describe tu problema o sugerencia' : null,
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _sending ? null : _send,
                  icon: _sending ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.send),
                  label: const Text('Enviar mensaje'),
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
