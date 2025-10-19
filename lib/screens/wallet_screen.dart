import 'package:flutter/material.dart';
import 'package:taxipro_usuariox/screens/payment_methods_screen.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  // Datos de ejemplo
  final double _walletBalance = 250.75;
  final List<Map<String, dynamic>> _transactions = [
    {
      'description': 'Recarga de saldo',
      'amount': 300.00,
      'date': '2023-10-26',
      'isCredit': true,
    },
    {
      'description': 'Viaje a Plaza del Carmen',
      'amount': -49.25,
      'date': '2023-10-25',
      'isCredit': false,
    },
    {
      'description': 'Viaje al Aeropuerto',
      'amount': -220.00,
      'date': '2023-10-20',
      'isCredit': false,
    },
    {
      'description': 'Recarga de saldo',
      'amount': 500.00,
      'date': '2023-10-15',
      'isCredit': true,
    },
  ];

  Future<void> _initPayment() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Debes iniciar sesión para recargar saldo')),
          );
        }
        return;
      }

      // Obtener token de autenticación
      final idToken = await user.getIdToken();

      // Llamar al backend de Firebase Functions para crear sesión de pago
      final response = await http.post(
        Uri.parse('https://us-central1-taxipro-usuariox.cloudfunctions.net/createCheckoutSession'),
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({'amount': 10000}), // Monto en centavos (100.00)
      );

      if (response.statusCode != 200) {
        throw Exception('Error al crear sesión de pago: ${response.body}');
      }

      final data = json.decode(response.body);
      final clientSecret = data['clientSecret'] as String?;

      if (clientSecret == null) {
        throw Exception('No se recibió clientSecret del servidor');
      }

      // Inicializar Payment Sheet de Stripe
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'TaxiPro',
          style: ThemeMode.dark, // Modo oscuro forzado
        ),
      );

      // Presentar Payment Sheet
      await Stripe.instance.presentPaymentSheet();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Pago exitoso! Tu saldo se actualizará pronto.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on StripeException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error de Stripe: ${e.error.localizedMessage ?? 'Error desconocido'}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al procesar el pago: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Cartera'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Saldo Actual
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Text('SALDO ACTUAL', style: TextStyle(color: Colors.white70, fontSize: 16)),
                  const SizedBox(height: 8),
                  Text('\$${_walletBalance.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Botones de Acción
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton.icon(
                  onPressed: _initPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('Recargar Saldo'),
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PaymentMethodsScreen()));
                  },
                  icon: const Icon(Icons.credit_card),
                  label: const Text('Métodos de Pago'),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Historial de Transacciones
            const Text('Historial de Transacciones', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: _transactions.length,
                itemBuilder: (context, index) {
                  final tx = _transactions[index];
                  final isCredit = tx['isCredit'] as bool;
                  return ListTile(
                    leading: Icon(
                      isCredit ? Icons.arrow_downward : Icons.arrow_upward,
                      color: isCredit ? Colors.green : Colors.red,
                    ),
                    title: Text(tx['description'] as String),
                    subtitle: Text(tx['date'] as String),
                    trailing: Text(
                      '\$${(tx['amount'] as double).abs().toStringAsFixed(2)}',
                      style: TextStyle(
                        color: isCredit ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
