import 'dart:developer' as developer;
import 'package:cloud_functions/cloud_functions.dart';
import 'package:taxipro_usuariox/services/functions_service.dart'; // Importar el servicio centralizado

class AppConfig {
  // Singleton pattern to ensure only one instance of the config exists
  static final AppConfig _instance = AppConfig._internal();
  factory AppConfig() => _instance;
  AppConfig._internal();

  String? stripePublishableKey;
  String? googleApiKey;

  bool get isInitialized => stripePublishableKey != null && googleApiKey != null;

  Future<void> initialize() async {
    if (isInitialized) return; // Already initialized

    try {
      final result = await CloudFunctionsService.instance.callMap('getPassengerAppConfig', {});
      final data = result is Map ? Map<String, dynamic>.from(result) : <String, dynamic>{};

      if (data != null) {
        stripePublishableKey = data['stripePublishableKey'] as String?;
        googleApiKey = data['googleApiKey'] as String?;
        developer.log('✅ Remote config fetched successfully.', name: 'AppConfig');
        developer.log('   - Stripe Key Loaded: ${stripePublishableKey != null && stripePublishableKey!.isNotEmpty}', name: 'AppConfig');
        developer.log('   - Google Key Loaded: ${googleApiKey != null && googleApiKey!.isNotEmpty}', name: 'AppConfig');
      } else {
        developer.log('❌ Remote config data is null.', name: 'AppConfig');
      }

      if (!isInitialized) {
        throw Exception('Failed to fetch one or more configuration keys from the backend.');
      }
    } on FirebaseFunctionsException catch (e, st) {
      developer.log('❌ FirebaseFunctionsException while fetching config: ${e.code} - ${e.message}', name: 'AppConfig', stackTrace: st);
      rethrow;
    } catch (e, st) {
      developer.log('❌ Unexpected error while fetching config: $e', name: 'AppConfig', stackTrace: st);
      rethrow;
    }
  }
}
