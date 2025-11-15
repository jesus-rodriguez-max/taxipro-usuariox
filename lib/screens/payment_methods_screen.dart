import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:taxipro_usuariox/services/functions_service.dart'; // Importar el servicio centralizado
import 'package:flutter_stripe/flutter_stripe.dart' hide Card;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';

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
  String? _defaultPaymentMethodId;

  @override
  void initState() {
    super.initState();
    _loadPaymentMethods();
  }

  Future<void> _loadPaymentMethods() async {
    developer.log('🔵 [Wallet] Iniciando _loadPaymentMethods...', name: 'PaymentMethodsScreen');
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception('Usuario no autenticado para cargar métodos de pago.');

      developer.log('🔵 [Wallet] Obteniendo token de usuario...', name: 'PaymentMethodsScreen');
      await FirebaseAuth.instance.currentUser!.getIdToken(true);
      developer.log('🔵 [Wallet] Llamando a listPassengerPaymentMethodsCallable...', name: 'PaymentMethodsScreen');
      final result = await CloudFunctionsService.instance.callMap('listPassengerPaymentMethodsCallable', {'userId': uid});
      final data = result;
      developer.log('🟢 [Wallet] Respuesta de listPassengerPaymentMethods: $result', name: 'PaymentMethodsScreen');

      final methods = (data['methods'] as List? ?? []).cast<dynamic>();
      final defaultPm = data['defaultPaymentMethodId'] as String?;
      if (!mounted) return;
      setState(() {
        _paymentMethods = methods
            .map((m) => PaymentCard.fromMap({
                  'id': m['id'] ?? '',
                  'brand': m['brand'] ?? 'card',
                  'last4': m['last4'] ?? '****',
                  'isDefault': defaultPm != null && defaultPm == (m['id'] ?? ''),
                }))
            .toList();
        _defaultPaymentMethodId = defaultPm;
        _isLoading = false;
      });
    } on FirebaseFunctionsException catch (e) {
      developer.log('🟠 [Wallet] FirebaseFunctionsException en _loadPaymentMethods: code=${e.code}, message=${e.message}', name: 'PaymentMethodsScreen');
      if (e.code == 'not-found') {
        developer.log('🟡 [Wallet] Cliente de Stripe no encontrado. Intentando crear uno...', name: 'PaymentMethodsScreen');
        // Pasar un parámetro para evitar el bucle infinito.
        await _createStripeCustomer(retryLoad: true);
      } else {
        if (!mounted) return;
        setState(() {
          _error = 'Error al cargar tus tarjetas: ${e.message}';
          _isLoading = false;
        });
      }
    } catch (e) {
      developer.log('🔴 [Wallet] Error inesperado en _loadPaymentMethods: $e', name: 'PaymentMethodsScreen');
      if (!mounted) return;
      setState(() {
        _error = 'Ocurrió un error inesperado: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _addCard() async {
    // Guard clause para esperar la restauración del estado de autenticación
    if (FirebaseAuth.instance.currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verificando sesión...')),
        );
      }
      await FirebaseAuth.instance.authStateChanges().firstWhere((user) => user != null);
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo verificar la sesión. Por favor, reinicia la app.')),
        );
      }
      return;
    }

    final uid = user.uid;
    try {
      // Asegurar publishableKey desde .env antes de usar Stripe
      final stripeKey = dotenv.env['STRIPE_PUBLISHABLE_KEY'];
      if (stripeKey == null || stripeKey.isEmpty) {
        throw Exception('Stripe no está configurado (STRIPE_PUBLISHABLE_KEY ausente en .env).');
      }
      Stripe.publishableKey = stripeKey;
      await Stripe.instance.applySettings();

      await user.getIdToken(true);
      final res = await CloudFunctionsService.instance.callMap('createPassengerSetupIntentCallable', {'userId': uid});
      final clientSecret = res['clientSecret'] as String?;
      final setupIntentId = res['setupIntentId'] as String?;
      if (clientSecret == null || clientSecret.isEmpty) throw Exception('No se pudo iniciar SetupIntent.');

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          setupIntentClientSecret: clientSecret,
          merchantDisplayName: 'TaxiPro',
          style: ThemeMode.dark,
        ),
      );
      await Stripe.instance.presentPaymentSheet();

      // Recuperar el SetupIntent para obtener el PM si es necesario
      final si = await Stripe.instance.retrieveSetupIntent(clientSecret);
      final siId = si.id ?? setupIntentId;
      if (siId == null || siId.isEmpty) throw Exception('No se pudo recuperar el SetupIntent.');

      await CloudFunctionsService.instance.callMap('savePassengerPaymentMethodCallable', {'userId': uid, 'setupIntentId': siId});

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tarjeta guardada correctamente.')));
      await _loadPaymentMethods();
    } on StripeException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Stripe: ${e.error.localizedMessage ?? e.toString()}')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al agregar tarjeta: $e')));
    }
  }

  Future<void> _createStripeCustomer({bool retryLoad = false}) async {
    developer.log('🔵 [Wallet] Iniciando _createStripeCustomer...', name: 'PaymentMethodsScreen');
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      developer.log('🔴 [Wallet] Error: Usuario nulo al intentar crear cliente de Stripe.', name: 'PaymentMethodsScreen');
      if (!mounted) return;
      setState(() {
        _error = 'Error de autenticación al crear cartera.';
        _isLoading = false;
      });
      return;
    }

    try {
      developer.log('🔵 [Wallet] Llamando a createPassengerCustomerCallable...', name: 'PaymentMethodsScreen');
      final result = await CloudFunctionsService.instance.callMap('createPassengerCustomerCallable', {'email': user.email, 'userId': user.uid, 'name': user.displayName});
      developer.log('🟢 [Wallet] Respuesta de createPassengerCustomer: $result', name: 'PaymentMethodsScreen');

      if (retryLoad) {
        developer.log('🔵 [Wallet] Cliente creado, reintentando cargar métodos de pago...', name: 'PaymentMethodsScreen');
        _loadPaymentMethods();
      } else {
        // Si no se debe reintentar, simplemente actualizamos el estado para reflejar que ya no hay error.
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _error = null; // Limpiar error anterior
          // Podríamos incluso mostrar un SnackBar de éxito aquí.
        });
      }
    } on FirebaseFunctionsException catch (e) {
      developer.log('🔴 [Wallet] FirebaseFunctionsException en _createStripeCustomer: code=${e.code}, message=${e.message}', name: 'PaymentMethodsScreen');
      if (!mounted) return;
      setState(() {
        // Mostramos el error definitivo que rompe el bucle.
        _error = 'Error al inicializar tu cartera: ${e.message}. Por favor, intenta de nuevo.';
        _isLoading = false;
      });
    }
  }

  Future<void> _setDefault(String paymentMethodId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      await FirebaseAuth.instance.currentUser?.getIdToken(true);
      await CloudFunctionsService.instance.callMap('savePassengerPaymentMethodCallable', {'userId': uid, 'paymentMethodId': paymentMethodId});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Método de pago establecido como principal.')));
      await _loadPaymentMethods();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al establecer principal: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Métodos de Pago'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadPaymentMethods,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _addCard,
                  icon: const Icon(Icons.add_card),
                  label: const Text('Agregar nueva tarjeta'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
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
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 16),
            ),
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
          color: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: const Icon(Icons.credit_card, size: 40), // TODO: Mostrar logo de la marca
            title: Text('${method.brand} terminada en ${method.last4}'),
            trailing: method.isDefault
                ? Chip(
                    label: const Text('Principal'),
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    labelStyle: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : TextButton(
                    onPressed: () => _setDefault(method.id),
                    child: const Text('Hacer principal'),
                  ),
          ),
        );
      },
    );
  }
}
