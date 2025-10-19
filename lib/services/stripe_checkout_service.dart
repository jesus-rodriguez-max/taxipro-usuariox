
import 'dart:convert';
import 'package:http/http.dart' as http;

class StripeCheckoutService {
  // TODO: Reemplazar con la URL base de la API de producción
  static const String _apiBaseUrl = 'https://api.tudominio.com/v1';

  /// Llama al backend para crear una sesión de checkout de Stripe.
  ///
  /// El backend debe recibir los detalles del viaje y del pasajero,
  /// y devolver una URL de checkout (`checkoutUrl`) para ser abierta en un WebView.
  ///
  /// Parámetros:
  ///   - `tripId`: El ID del viaje para asociar la sesión de pago.
  ///   - `passengerId`: El ID del pasajero que realiza el pago.
  ///   - `amount`: El monto a cobrar en la unidad más pequeña (ej. centavos).
  ///   - `currency`: El código de la moneda (ej. 'mxn').
  ///
  /// Retorna:
  ///   Un `Future<String>` con la `checkoutUrl` si la operación es exitosa.
  ///   Lanza una excepción si ocurre un error.
  Future<String> createPassengerCheckoutSession({
    required String tripId,
    required String passengerId,
    required int amount,
    required String currency,
  }) async {
    // TODO: Construir la URL completa del endpoint del backend
    final url = Uri.parse('$_apiBaseUrl/createPassengerCheckoutSession');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          // TODO: Añadir cabeceras de autenticación si son necesarias
          // 'Authorization': 'Bearer TU_TOKEN_DE_AUTENTICACION',
        },
        body: json.encode({
          'tripId': tripId,
          'passengerId': passengerId,
          'amount': amount,
          'currency': currency,
        }),
      );

      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);
        
        // El backend debe devolver un JSON con la clave 'checkoutUrl'
        if (responseBody.containsKey('checkoutUrl')) {
          return responseBody['checkoutUrl'];
        } else {
          throw Exception('La respuesta del backend no contiene "checkoutUrl"');
        }
      } else {
        // Manejar respuestas de error del servidor
        final errorBody = json.decode(response.body);
        final errorMessage = errorBody['message'] ?? 'Error desconocido del servidor';
        throw Exception('Error al crear la sesión de checkout: ${response.statusCode} - $errorMessage');
      }
    } catch (e) {
      // Manejar errores de red u otros problemas
      print('Error en createPassengerCheckoutSession: $e');
      throw Exception('No se pudo conectar con el servicio de pago. Por favor, inténtalo de nuevo.');
    }
  }
}
