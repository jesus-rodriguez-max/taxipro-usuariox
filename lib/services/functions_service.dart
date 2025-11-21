// lib/services/functions_service.dart

// Copia adaptada del servicio de Cloud Functions original de TaxiPro.
// Se anadió soporte para conectar con el emulador de Cloud Functions
// mediante variables de entorno definidas en `.env`.  Si la variable
// USE_FUNCTIONS_EMULATOR está establecida a `true`, el servicio
// redirige las llamadas al host/puerto configurados en
// FUNCTIONS_EMULATOR_HOST y FUNCTIONS_EMULATOR_PORT.  En producción
// estas variables pueden omitirse para usar el entorno de Firebase
// predeterminado.

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:async';
import 'dart:developer' as developer;

/// Servicio singleton seguro para llamar a Cloud Functions.
/// Evita inicializar FirebaseFunctions en el top-level para que NO
/// provoque `[core/duplicate-app]` por inicialización temprana.
class CloudFunctionsService {
  CloudFunctionsService._private();
  static final CloudFunctionsService instance = CloudFunctionsService._private();

  FirebaseFunctions? _functions;
  bool _emulatorConfigured = false;

  /// Obtiene una instancia de [FirebaseFunctions], configurando la
  /// región predeterminada (`us-central1`) y, opcionalmente, el
  /// emulador local si las variables de entorno lo indican.
  FirebaseFunctions get functions {
    // Si ya tenemos una instancia, retornarla inmediatamente.
    if (_functions != null) {
      return _functions!;
    }

    // Verificar que Firebase esté inicializado antes de usar Functions.
    if (Firebase.apps.isEmpty) {
      throw StateError(
        'Firebase no está inicializado. Llama a `await Firebase.initializeApp()`'
        ' en main() antes de usar CloudFunctionsService.',
      );
    }

    // Crear la instancia para la región configurada.
    _functions = FirebaseFunctions.instanceFor(region: 'us-central1');

    // Comprobar si se debe usar el emulador a partir de variables de entorno.
    final useEmulator = dotenv.maybeGet('USE_FUNCTIONS_EMULATOR') == 'true';
    if (useEmulator && !_emulatorConfigured) {
      final host = dotenv.maybeGet('FUNCTIONS_EMULATOR_HOST') ?? 'localhost';
      final portString = dotenv.maybeGet('FUNCTIONS_EMULATOR_PORT') ?? '5001';
      final port = int.tryParse(portString) ?? 5001;
      try {
        _functions!.useFunctionsEmulator(host, port);
        developer.log(
          'Conectando al emulador de Cloud Functions en $host:$port',
          name: 'CloudFunctionsService',
        );
        _emulatorConfigured = true;
      } catch (e) {
        developer.log(
          'Error configurando el emulador de Functions: $e',
          name: 'CloudFunctionsService',
        );
      }
    }
    return _functions!;
  }

  /// Funcón privada para envolver llamadas a funciones con gestión de token y
  /// timeouts.  Permite indicar si la llamada requiere un usuario
  /// autenticado mediante [requireAuth].
  Future<Map<String, dynamic>> _callFunction(
    String name,
    Map<String, dynamic> data, {
    bool requireAuth = true,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (requireAuth) {
      if (user == null) {
        throw Exception('Usuario no autenticado.');
      }
      // Refrescar ID token para evitar 401s por expiración.
      try {
        await user.getIdToken(true).timeout(const Duration(seconds: 4));
      } catch (_) {
        // ignorar expiración de token; Functions se encargará del error.
      }
    }

    try {
      final callable = functions.httpsCallable(name);
      final result = await callable.call(data).timeout(const Duration(seconds: 12));
      final payload = result.data;
      // Normalizar payload a Map<String, dynamic> de manera segura
      if (payload is Map<String, dynamic>) return payload;
      if (payload is Map) {
        final normalized = <String, dynamic>{};
        payload.forEach((key, value) {
          final k = key?.toString() ?? '';
          normalized[k] = value;
        });
        return normalized;
      }
      // Si back-end devuelve otro formato, envolverlo
      return <String, dynamic>{'result': payload};
    } on FirebaseFunctionsException catch (e) {
      developer.log('Cloud Functions error: ${e.code} - ${e.message} (name=$name)',
          name: 'CloudFunctionsService');
      // Fallback: si la función no existe con este nombre, intenta con/sin sufijo 'Callable'
      if (e.code == 'not-found') {
        final alt = name.endsWith('Callable')
            ? name.substring(0, name.length - 'Callable'.length)
            : '${name}Callable';
        try {
          developer.log('Reintentando con nombre alterno: $alt',
              name: 'CloudFunctionsService');
          final callable2 = functions.httpsCallable(alt);
          final result2 = await callable2.call(data).timeout(const Duration(seconds: 12));
          final payload2 = result2.data;
          if (payload2 is Map<String, dynamic>) return payload2;
          if (payload2 is Map) {
            final normalized2 = <String, dynamic>{};
            payload2.forEach((key, value) {
              final k = key?.toString() ?? '';
              normalized2[k] = value;
            });
            return normalized2;
          }
          return <String, dynamic>{'result': payload2};
        } on FirebaseFunctionsException {
          rethrow; // Propaga el not-found si también falla el alterno
        }
      }
      rethrow;
    } catch (e) {
      developer.log('Unexpected Functions error: $e (name=$name)',
          name: 'CloudFunctionsService');
      rethrow;
    }
  }

  /// Ejemplo de llamada específica para crear un PaymentIntent.
  Future<String> createPaymentIntent({required String tripId}) async {
    final resp = await _callFunction('createPaymentIntentCallable', {'tripId': tripId});
    final clientSecret = resp['clientSecret'] as String?;
    if (clientSecret == null || clientSecret.isEmpty) {
      throw Exception('No se recibió clientSecret desde la Cloud Function.');
    }
    return clientSecret;
  }

  /// Método genérico para llamadas que devuelven mapa (requiere auth por defecto).
  Future<Map<String, dynamic>> callMap(String functionName,
      [Map<String, dynamic> data = const {}]) {
    return _callFunction(functionName, data, requireAuth: true);
  }

  /// Llamada pública que NO requiere usuario autenticado (por ejemplo, configuración de la app).
  Future<Map<String, dynamic>> callPublic(String functionName,
      [Map<String, dynamic> data = const {}]) {
    return _callFunction(functionName, data, requireAuth: false);
  }

  /// Exponer la instancia subyacente en caso de necesitar llamadas directas.
  FirebaseFunctions get rawFunctions => functions;

  /// Obtiene el perfil del pasajero autenticado.
  Future<Map<String, dynamic>> getPassengerProfile() async {
    final resp = await _callFunction('getPassengerProfileCallable', {});
    return resp;
  }

  /// Solicita un viaje con los parámetros requeridos.
  Future<Map<String, dynamic>> requestTrip({
    required double originLat,
    required double originLng,
    required String originAddress,
    required double destLat,
    required double destLng,
    required String destAddress,
    required double estimatedDistanceKm,
    required int estimatedDurationMin,
    bool isPhoneRequest = false,
  }) async {
    final payload = {
      'origin': {'lat': originLat, 'lng': originLng, 'address': originAddress},
      'destination': {'lat': destLat, 'lng': destLng, 'address': destAddress},
      'estimatedDistanceKm': estimatedDistanceKm,
      'estimatedDurationMin': estimatedDurationMin,
      'isPhoneRequest': isPhoneRequest,
    };
    return await _callFunction('requestTripCallable', payload);
  }

  /// Calcula la tarifa estimada sin requerir autenticación.
  Future<Map<String, dynamic>> quoteFare({
    required double estimatedDistanceKm,
    required int estimatedDurationMin,
    bool isPhoneRequest = false,
  }) async {
    final payload = {
      'estimatedDistanceKm': estimatedDistanceKm,
      'estimatedDurationMin': estimatedDurationMin,
      'isPhoneRequest': isPhoneRequest,
    };
    return await _callFunction('quoteFareCallable', payload, requireAuth: false);
  }
}
