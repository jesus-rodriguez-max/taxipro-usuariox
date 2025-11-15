import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:webview_flutter/webview_flutter.dart';

class LegalDocumentScreen extends StatefulWidget {
  final String title;
  final String assetPath;
  const LegalDocumentScreen({super.key, required this.title, required this.assetPath});

  @override
  State<LegalDocumentScreen> createState() => _LegalDocumentScreenState();
}

class _LegalDocumentScreenState extends State<LegalDocumentScreen> {
  late final Future<String> _loader;

  @override
  void initState() {
    super.initState();
    _loader = _loadAsset();
  }

  Future<String> _loadAsset() async {
    try {
      return await rootBundle.loadString(widget.assetPath);
    } catch (_) {
      return 'Contenido no disponible. Asegúrate de incluir ${widget.assetPath} en assets.';
    }
  }

  bool get _isHtml => widget.assetPath.toLowerCase().endsWith('.html') || widget.assetPath.toLowerCase().endsWith('.htm');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title), backgroundColor: Theme.of(context).colorScheme.primary),
      body: FutureBuilder<String>(
        future: _loader,
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final content = snap.data ?? '';
          if (_isHtml) {
            final controller = WebViewController()
              ..setJavaScriptMode(JavaScriptMode.unrestricted)
              ..loadHtmlString(content);
            return WebViewWidget(controller: controller);
          }
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(child: Text(content)),
          );
        },
      ),
    );
  }
}
