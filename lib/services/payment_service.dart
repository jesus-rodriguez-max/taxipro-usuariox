import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:taxipro_usuariox/services/functions_service.dart';

// Esta clase encapsula toda la lógica relacionada con los pagos.
class PaymentService {
  
  // --- Placeholder para el Servicio de Backend ---
  // Idealmente, tendrías una clase que maneja la comunicación con tu API.
  // final BackendService _backendService = BackendService();
  // -------------------------------------------

  // Esta función maneja el flujo de pago completo para un viaje.
  Future<bool> processTripPayment({
    required BuildContext context, // Para mostrar feedback al usuario (SnackBars)
    required int amount, // Monto en la unidad más pequeña (ej. centavos)
    required String currency, // ej. 'mxn', 'usd'
    required String stripeCustomerId, // El ID del cliente de Stripe
    // También podrías pasar un paymentMethodId específico si el usuario tiene varias tarjetas
  }) async {
    try {
      // 1. Crear un PaymentIntent en tu servidor.
      // Tu endpoint de backend debe recibir el monto, la moneda y el ID del cliente.
      // Debe crear un PaymentIntent y devolver su client_secret.
      //
      // final Map<String, dynamic> paymentIntentData = await _backendService.createPaymentIntent(
      //   amount: amount,
      //   currency: currency,
      //   customerId: stripeCustomerId,
      // );
      // final clientSecret = paymentIntentData['clientSecret'];
      
      // --- P L A C E H O L D E R ---
      // Simulando la llamada al backend.
      // IMPORTANTE: DEBES reemplazar esto con una llamada real a tu backend.
      print('ADVERTENCIA: Usando un client_secret de placeholder para el pago. Debes conectar tu backend.');
      final String clientSecret = await _getPaymentIntentClientSecretFromBackend(amount, currency, stripeCustomerId);
      // --- F I N   P L A C E H O L D E R ---

      // 2. Confirmar el PaymentIntent en el cliente.
      // Esto presentará una hoja de pago al usuario si se requiere autenticación 3D Secure.
      final paymentIntent = await Stripe.instance.confirmPayment(
        paymentIntentClientSecret: clientSecret,
        data: const PaymentMethodParams.card(
          paymentMethodData: PaymentMethodData(), // No se necesitan detalles de la tarjeta aquí, ya que usamos una guardada a través del customer
        ),
      );

      // 3. Manejar el resultado del pago.
      if (paymentIntent.status == PaymentIntentsStatus.Succeeded) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('¡Viaje pagado con éxito!'),
              backgroundColor: Colors.green,
            ),
          );
        }
        return true; // El pago fue exitoso
      } else if (paymentIntent.status == PaymentIntentsStatus.Canceled) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('El pago fue cancelado.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return false;
      } else {
        // Manejar otros estados como Failed, RequiresConfirmation, etc.
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('El pago fue rechazado. Por favor, verifica tu método de pago.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return false;
      }

    } catch (e) {
      // Manejar excepciones del SDK de Stripe o errores de red.
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ocurrió un error inesperado durante el pago: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }
  }

  // Esta es una función de placeholder para simular la obtención del client secret.
  // DEBES REEMPLAZARLA con tu lógica de backend real.
  Future<String> _getPaymentIntentClientSecretFromBackend(int amount, String currency, String customerId) async {
    // Esto sería una llamada HTTP a tu servidor.
    // 🔥 PRODUCCIÓN: Usar CloudFunctions real para Stripe
    try {
      print('[CALLABLE] createPaymentIntent started');
      final result = await CloudFunctionsService.instance.createPaymentIntent(
        tripId: customerId, // Usamos customerId como tripId temporalmente
      );
      print('[CALLABLE] createPaymentIntent finished');
      return result; // Devuelve el clientSecret real de Stripe
    } catch (e) {
      print('[CALLABLE] createPaymentIntent error: $e');
      print('🔴 ERROR PaymentService: $e');
      throw Exception('Error creando PaymentIntent: $e');
    }
  }
}
