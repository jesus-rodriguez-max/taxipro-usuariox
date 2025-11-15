
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Una pantalla que muestra una página web en un WebView, diseñada para el checkout de Stripe.
///
/// Escucha las redirecciones de URL para detectar los casos de éxito y cancelación del pago.
class PaymentWebviewScreen extends StatefulWidget {
  /// La URL de checkout de Stripe que se cargará en el WebView.
  final String checkoutUrl;

  const PaymentWebviewScreen({Key? key, required this.checkoutUrl}) : super(key: key);

  @override
  State<PaymentWebviewScreen> createState() => _PaymentWebviewScreenState();
}

class _PaymentWebviewScreenState extends State<PaymentWebviewScreen> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) {
            final url = request.url.toLowerCase();
            // Compatibilidad con URLs actuales del backend y genéricas
            final isSuccess = url.contains('pago-exitoso') || url.contains('success');
            final isCancel = url.contains('pago-cancelado') || url.contains('cancel');
            if (isSuccess) {
              Navigator.of(context).pop('success');
              return NavigationDecision.prevent;
            }
            if (isCancel) {
              Navigator.of(context).pop('cancel');
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.checkoutUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Completar Pago Seguro'),
        backgroundColor: Colors.white,
        elevation: 1,
        foregroundColor: Colors.black87,
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
