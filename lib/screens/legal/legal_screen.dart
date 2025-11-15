import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:webview_flutter/webview_flutter.dart';

class LegalScreen extends StatefulWidget {
  const LegalScreen({super.key});

  @override
  State<LegalScreen> createState() => _LegalScreenState();
}

class _LegalScreenState extends State<LegalScreen> {
  String? _html;
  bool _loading = true;
  WebViewController? _controller;

  @override
  void initState() {
    super.initState();
    _loadHtml();
  }

  Future<void> _loadHtml() async {
    try {
      final html = await rootBundle.loadString('assets/legal/aviso_privacidad_terminos.html');
      setState(() {
        _html = html;
        _loading = false;
      });
      final c = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..loadHtmlString(html);
      setState(() => _controller = c);
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Aviso de Privacidad y Términos')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : (_controller != null
              ? WebViewWidget(controller: _controller!)
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: SelectableText(_html ?? 'Documento no disponible'),
                )),
    );
  }
}
