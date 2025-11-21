// lib/services/functions_service.dart
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:developer' as developer;

/// Servicio singleton seguro para llamar a Cloud Functions.
/// Evita inicializar FirebaseFunctions en el top-level para que NO
/// provoque `[core/duplicate-app]` por inicialización temprana.
class CloudFunctionsService {
  CloudFunctionsService._private();
  static final CloudFunctionsService instance = CloudFunctionsService._private();

  FirebaseFunctions? _functions;
  FirebaseFunctions get functions {
    if (_functions != null) return _functions!;

    // Si Firebase no está inicializado, falla con mensaje claro.
    if (Firebase.apps.isEmpty) {
      throw StateError(
        'Firebase no está inicializado. Llama a `await Firebase.initializeApp()` en main() antes de usar CloudFunctionsService.'
      );
    }

    // Lazy init: crea la instancia aquí, después de que Firebase esté listo.
    _functions = FirebaseFunctions.instanceFor(region: 'us-central1');
    return _functions!;
  }

  Future<Map<String, dynamic>> _callFunction(
    String name,
    Map<String, dynamic> data, {
    bool requireAuth = true,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (requireAuth) {
      if (user == null) throw Exception('Usuario no autenticado.');
      // Refrescar ID token para evitar 401s por expiración
      await user.getIdToken(true).timeout(const Duration(seconds: 4), onTimeout: () => '');
    }

    try {
      developer.log('[CALLING_FUNCTION] $name data=$data', name: 'FunctionsService');
      final callable = functions.httpsCallable(name);
      final result = await callable.call(data).timeout(
        const Duration(seconds: 6),
        onTimeout: () {
          developer.log('[FUNCTION_TIMEOUT] $name', name: 'FunctionsService');
          throw Exception('Function timeout: $name');
        },
      );
      final payload = result.data;
      developer.log('[FUNCTION_RESPONSE] $name result=${payload.toString().length > 100 ? payload.toString().substring(0, 100) + '...' : payload}', name: 'FunctionsService');
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
      developer.log('Cloud Functions error: ${e.code} - ${e.message} (name=$name)', name: 'CloudFunctionsService');
      // Fallback: si la función no existe con este nombre, intenta con/sin sufijo 'Callable'
      if (e.code == 'not-found') {
        final alt = name.endsWith('Callable') ? name.substring(0, name.length - 'Callable'.length) : '${name}Callable';
        try {
          developer.log('Reintentando con nombre alterno: $alt', name: 'CloudFunctionsService');
          final callable2 = functions.httpsCallable(alt);
          final result2 = await callable2.call(data).timeout(
            const Duration(seconds: 6),
            onTimeout: () {
              developer.log('[FUNCTION_TIMEOUT] $alt', name: 'FunctionsService');
              throw Exception('Function timeout: $alt');
            },
          );
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
      developer.log('[FUNCTION_ERROR] $name error=$e', name: 'FunctionsService');
      rethrow;
    }
  }

  /// Ejemplo: crear PaymentIntent (ajusta el nombre de la función si tu backend usa otro)
  Future<String> createPaymentIntent({required String tripId}) async {
    print('[CALLABLE] createPaymentIntentCallable started');
    final resp = await _callFunction('createPaymentIntentCallable', {'tripId': tripId});
    print('[CALLABLE] createPaymentIntentCallable finished');
    final clientSecret = resp['clientSecret'] as String?;
    if (clientSecret == null || clientSecret.isEmpty) {
      throw Exception('No se recibió clientSecret desde la Cloud Function.');
    }
    return clientSecret;
  }

  /// Método genérico para llamadas que devuelven mapa (requiere auth por defecto)
  Future<Map<String, dynamic>> callMap(
    String functionName, [Map<String, dynamic> data = const {}]
  ) {
    return _callFunction(functionName, data, requireAuth: true);
  }

  /// Llamada pública que NO requiere usuario autenticado (por ejemplo, configuración de la app)
  Future<Map<String, dynamic>> callPublic(
    String functionName, [Map<String, dynamic> data = const {}]
  ) {
    return _callFunction(functionName, data, requireAuth: false);
  }

  /// Exponer la instancia si se necesita para llamadas directas
  FirebaseFunctions get rawFunctions => functions;

  Future<Map<String, dynamic>> getPassengerProfile() async {
    final resp = await _callFunction('getPassengerProfileCallable', {});
    return resp;
  }

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

