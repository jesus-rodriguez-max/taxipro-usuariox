import 'package:flutter/material.dart';

  // Modelo para representar una tarjeta de pago de forma segura.
  class PaymentCard {
    final String id;
    final String brand;
    final String last4;
    final bool isDefault;

  PaymentCard({
    required this.id,
    required this.brand,
    required this.last4,
    required this.isDefault,
  });

  // Factory para crear una instancia desde un mapa (ej. JSON de la API)
  factory PaymentCard.fromMap(Map<String, dynamic> map) {
    return PaymentCard(
      id: map['id'] as String,
      brand: map['brand'] as String,
      last4: map['last4'] as String,
      isDefault: map['isDefault'] as bool? ?? false,
    );
  }
}

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  bool _isLoading = true;
  String? _error;
  List<PaymentCard> _paymentMethods = [];

  @override
  void initState() {
    super.initState();
    _loadPaymentMethods();
  }

  Future<void> _loadPaymentMethods() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // --- P L A C E H O L D E R ---
      // Aquí es donde llamarías a tu backend para obtener las tarjetas del usuario.
      // final backendService = BackendService();
      // final cardsData = await backendService.getPaymentMethodsForCurrentUser();
      // if (mounted) {
      //   setState(() {
      //     _paymentMethods = cardsData.map((data) => PaymentCard.fromMap(data)).toList();
      //     _isLoading = false;
      //   });
      // }
      // --- F I N   P L A C E H O L D E R ---

      // Simulando una llamada de red con datos de ejemplo
      await Future.delayed(const Duration(seconds: 1));
      final mockData = [
        {'id': 'pm_12345', 'brand': 'Visa', 'last4': '4242', 'isDefault': true},
        {'id': 'pm_67890', 'brand': 'Mastercard', 'last4': '5555', 'isDefault': false},
      ];

      if (mounted) {
        setState(() {
          _paymentMethods = mockData.map((data) => PaymentCard.fromMap(data)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = "Error al cargar métodos de pago. Inténtalo de nuevo.";
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Métodos de Pago'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _loadPaymentMethods,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Expanded(
                child: _buildContent(),
              ),

            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 10),
            ElevatedButton(onPressed: _loadPaymentMethods, child: const Text("Reintentar")),
          ],
        ),
      );
    }

    if (_paymentMethods.isEmpty) {
      return const Center(child: Text("No tienes métodos de pago guardados."));
    }

    return ListView.builder(
      itemCount: _paymentMethods.length,
      itemBuilder: (context, index) {
        final method = _paymentMethods[index];
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: const Icon(Icons.credit_card, size: 40), // TODO: Mostrar logo de la marca
            title: Text('${method.brand} terminada en ${method.last4}'),
            trailing: method.isDefault
                ? Chip(
                    label: const Text('Principal'),
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    labelStyle: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                  )
                : null,
            onTap: () {
              // TODO: Lógica para establecer como principal
            },
          ),
        );
      },
    );
  }
}
