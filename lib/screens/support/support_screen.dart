import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../faq_screen.dart';
import 'contact_form_screen.dart';
import 'chat_screen.dart';
import 'audio_recorder_screen.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final TextEditingController _message = TextEditingController();
  String? _attachedAudioUrl;
  String? _attachedImageUrl;
  bool _isLoading = false;

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Future<void> _openFAQ() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const FaqScreen()),
    );
  }

  Future<void> _openContact() async {
    final result = await Navigator.push(context,
      MaterialPageRoute(builder: (_) => const ContactFormScreen()));
    
    if (result != null && result is Map<String, dynamic>) {
      if (result['audioUrl'] != null) {
        setState(() => _attachedAudioUrl = result['audioUrl']);
      }
      if (result['imageUrl'] != null) {
        setState(() => _attachedImageUrl = result['imageUrl']);
      }
    }
  }

  Future<void> _openChat() async {
    await Navigator.push(context,
      MaterialPageRoute(builder: (_) => const ChatScreen()));
  }

  Future<void> _openVoiceMessage() async {
    final result = await Navigator.push(context,
      MaterialPageRoute(builder: (_) => const AudioRecorderScreen()));
    
    if (result != null && result is String) {
      setState(() => _attachedAudioUrl = result);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Audio adjuntado correctamente')),
      );
    }
  }

  Future<void> _contactSupport() async {
    final messageText = _message.text.trim();
    
    if (messageText.isEmpty && _attachedAudioUrl == null && _attachedImageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escribe un mensaje o adjunta contenido')),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Usuario no autenticado');

      // Crear ticket según especificación exacta
      final ticketRef = await FirebaseFirestore.instance
        .collection('support_tickets')
        .add({
          'userId': user.uid,
          'message': messageText,
          'createdAt': FieldValue.serverTimestamp(),
        });

      // Llamar a Cloud Function
      final callable = FirebaseFunctions.instance.httpsCallable('sendSupportMessageCallable');
      await callable.call({
        'ticketId': ticketRef.id,
        'message': messageText,
      });

      // Limpiar formulario
      _message.clear();
      setState(() {
        _attachedAudioUrl = null;
        _attachedImageUrl = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mensaje enviado correctamente')),
      );
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al enviar mensaje: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Soporte Técnico'),
        backgroundColor: const Color(0xFF1A73E8),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título principal
            const Text(
              'Estamos para ayudarte',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            
            // Texto descriptivo
            const Text(
              'Elige un canal de contacto o envíanos un mensaje describiendo tu problema.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 24),
            
            // Grid de botones 2x2 con altura fija para evitar overflow
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.8,
              children: [
                _buildSupportButton(
                  icon: Icons.help_outline,
                  title: 'Preguntas',
                  subtitle: 'Revisa respuestas a dudas comunes.',
                  onTap: _openFAQ,
                ),
                _buildSupportButton(
                  icon: Icons.email_outlined,
                  title: 'Contacto',
                  subtitle: 'Envía un mensaje por correo.',
                  onTap: _openContact,
                ),
                _buildSupportButton(
                  icon: Icons.chat_bubble_outline,
                  title: 'Chat',
                  subtitle: 'Habla con un asistente de TaxiPro.',
                  onTap: _openChat,
                ),
                _buildSupportButton(
                  icon: Icons.mic_outlined,
                  title: 'Micrófono',
                  subtitle: 'Envíanos un mensaje de voz.',
                  onTap: _openVoiceMessage,
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Campo de texto
            Container(
              height: 140,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _message,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: const InputDecoration(
                  hintText: 'Describe tu problema…',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(16),
                  hintStyle: TextStyle(color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // Botón principal
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _contactSupport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A73E8),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isLoading 
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                  : const Text(
                      'Contactar soporte TaxiPro',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
              ),
            ),
            
            // Indicadores de archivos adjuntos
            if (_attachedAudioUrl != null || _attachedImageUrl != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Archivos adjuntos:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    if (_attachedAudioUrl != null)
                      Row(
                        children: [
                          const Icon(Icons.audiotrack, size: 16),
                          const SizedBox(width: 4),
                          const Text('Audio grabado'),
                          const Spacer(),
                          IconButton(
                            onPressed: () => setState(() => _attachedAudioUrl = null),
                            icon: const Icon(Icons.close, size: 16),
                          ),
                        ],
                      ),
                    if (_attachedImageUrl != null)
                      Row(
                        children: [
                          const Icon(Icons.image, size: 16),
                          const SizedBox(width: 4),
                          const Text('Imagen adjunta'),
                          const Spacer(),
                          IconButton(
                            onPressed: () => setState(() => _attachedImageUrl = null),
                            icon: const Icon(Icons.close, size: 16),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSupportButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 150, // Altura fija para evitar overflow
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1A73E8),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min, // Evita overflow
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Flexible(
              child: Text(
                subtitle,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
                maxLines: 2, // Permite máximo 2 líneas
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

