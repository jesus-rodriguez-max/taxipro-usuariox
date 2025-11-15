import 'package:flutter/material.dart';
import 'package:taxipro_usuariox/screens/payment_methods_screen.dart';
import 'package:taxipro_usuariox/widgets/tx_icon.dart';
import 'package:taxipro_usuariox/widgets/app_icons.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  // Datos de ejemplo
  final List<Map<String, String>> _paymentMethods = [
    {'type': 'Visa', 'last4': '1234', 'expiry': '12/26'},
    {'type': 'MasterCard', 'last4': '5678', 'expiry': '08/25'},
  ];
  final List<Map<String, dynamic>> _transactions = [
    {
      'description': 'Viaje a Plaza del Carmen',
      'amount': -49.25,
      'date': '2023-10-25',
    },
    {
      'description': 'Viaje al Aeropuerto',
      'amount': -220.00,
      'date': '2023-10-20',
    },
  ];

  void dumpFirebaseDebug() async {
    // lista apps
    print('Firebase.apps: ${Firebase.apps.map((a)=>a.name + ":" + a.options.projectId).toList()}');
    final user = FirebaseAuth.instance.currentUser;
    print('Current user uid: ${user?.uid}');
    final token = user==null ? null : await user.getIdToken();
    print('ID token (primeros 40 chars): ${token==null?null:token.substring(0, token.length>40?40:token.length)}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Cartera'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

            // Botones de Acción
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PaymentMethodsScreen()));
                  },
                  icon: SizedBox(height: 20, width: 20, child: TxIcon(AppIcons.creditCard, size: 20, semanticLabel: 'Agregar método')), 
                  label: const Text('Agregar Método de Pago'),
                ),
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).pushNamed('/settings'),
                  icon: SizedBox(height: 20, width: 20, child: TxIcon(AppIcons.settings, size: 20, semanticLabel: 'Configuración')), 
                  label: const Text('Configuración'),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Métodos de Pago Guardados
            const Text('Métodos de Pago', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            ..._paymentMethods.map((method) => ListTile(
              leading: TxIcon(AppIcons.creditCard, size: 24, semanticLabel: 'Tarjeta'),
              title: Text('${method['type']} **** ${method['last4']}'),
              subtitle: Text('Expira ${method['expiry']}'),
              trailing: IconButton(
                icon: TxIcon(AppIcons.menu, size: 20, semanticLabel: 'Más'),
                onPressed: () {
                  // Lógica para eliminar método de pago
                },
              ),
            )),
            const SizedBox(height: 24),

            // Historial de Viajes
            const Text('Historial de Viajes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: _transactions.length,
                itemBuilder: (context, index) {
                  final tx = _transactions[index];
                  return ListTile(
                    leading: TxIcon(AppIcons.taxi, size: 24, semanticLabel: 'Taxi'),
                    title: Text(
                      tx['description'] as String,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(tx['date'] as String),
                    trailing: Text(
                      '\$${(tx['amount'] as double).abs().toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.red,
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
      ),
    );
  }
}
