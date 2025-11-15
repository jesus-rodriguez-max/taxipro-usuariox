import 'package:flutter/material.dart';
import 'package:taxipro_usuariox/screens/legal_document_screen.dart';
import 'package:flutter/services.dart' show rootBundle;

class LegalConsentModal extends StatefulWidget {
  const LegalConsentModal({super.key});

  static Future<bool> show(BuildContext context) async {
    final r = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => SafeArea(
        child: Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.black.withOpacity(0.08)),
          ),
          child: const LegalConsentModal(),
        ),
      ),
    );
    return r == true;
  }

  @override
  State<LegalConsentModal> createState() => _LegalConsentModalState();
}

class _LegalConsentModalState extends State<LegalConsentModal> {
  bool _accepted = false;
  String _summary = '';

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    try {
      final html = await rootBundle.loadString('assets/legal/aviso_privacidad_terminos.html');
      final cleaned = html
          .replaceAll(RegExp(r'<style[^>]*>[\s\S]*?</style>', caseSensitive: false), ' ')
          .replaceAll(RegExp(r'<script[^>]*>[\s\S]*?</script>', caseSensitive: false), ' ')
          .replaceAll(RegExp(r'<[^>]+>'), ' ')
          .replaceAll(RegExp(r'&nbsp;|&#160;'), ' ')
          .replaceAll(RegExp(r'&amp;'), '&')
          .replaceAll(RegExp(r'&lt;'), '<')
          .replaceAll(RegExp(r'&gt;'), '>')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
      final plain = cleaned;
      setState(() {
        _summary = plain.length > 600 ? plain.substring(0, 600) + '…' : plain;
      });
    } catch (_) {
      setState(() {
        _summary = 'Contenido legal no disponible. Ver documento completo.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxH = MediaQuery.of(context).size.height * 0.85;
        return ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: SizedBox(
            height: maxH,
            child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.privacy_tip, color: Color(0xFF005CFF)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Términos y Aviso de Privacidad',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _summary.isEmpty ? 'Cargando…' : _summary,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5, color: Colors.black87),
                          textAlign: TextAlign.justify,
                          softWrap: true,
                          overflow: TextOverflow.visible,
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const LegalDocumentScreen(
                                    title: 'Aviso de Privacidad y Términos',
                                    assetPath: 'assets/legal/aviso_privacidad_terminos.html',
                                  ),
                                ),
                              );
                            },
                            child: const Text('Ver documento completo'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _accepted,
                  onChanged: (v) => setState(() => _accepted = v ?? false),
                  title: const Text('Acepto los Términos y Condiciones y el Aviso de Privacidad'),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _accepted ? () => Navigator.of(context).pop(true) : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF005CFF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Continuar'),
                  ),
                ),
              ],
            ),
          ),
          ),
        );
      },
    );
  }
}
