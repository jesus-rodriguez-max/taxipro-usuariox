import 'package:cloud_functions/cloud_functions.dart';
import 'package:taxipro_usuariox/services/functions_service.dart'; // Importar el servicio centralizado
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:developer' as developer;
import 'dart:async';

class AppConfigService {
  // Patrón Singleton
  AppConfigService._privateConstructor();
  static final AppConfigService instance = AppConfigService._privateConstructor();

  // Variables de configuración
  String? stripePublishableKey;
  String? googleApiKey;
  String? offlineSmsNumber;
  // Feature flags
  bool bottomCarouselEnabled = true; // default: habilitado
  bool drawerEnabled = false; // default: deshabilitado
  bool offlineRequestsEnabled = true; // default: habilitado
  bool shieldEnabled = true; // default: habilitado
  bool profileEnabled = true; // default: habilitado
  // Sesión local: permitir habilitar el drawer temporalmente por long-press
  bool drawerSessionEnabled = false;

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      developer.log('🟡 Obteniendo configuración del backend (pública)...', name: 'AppConfig');
      final result = await CloudFunctionsService.instance
          .callPublic('getPassengerAppConfigCallable', {})
          .timeout(const Duration(seconds: 15));

      stripePublishableKey = (result['stripePublishableKey'] as String?)?.trim();
      googleApiKey = (result['googleApiKey'] as String?)?.trim();
      offlineSmsNumber = (result['offlineSmsNumber'] as String?)?.trim();
      // Flags remotos
      bottomCarouselEnabled = (result['bottomCarouselEnabled'] as bool?) ?? bottomCarouselEnabled;
      drawerEnabled = (result['drawerEnabled'] as bool?) ?? drawerEnabled;
      offlineRequestsEnabled = (result['offlineRequestsEnabled'] as bool?) ?? offlineRequestsEnabled;
      shieldEnabled = (result['shieldEnabled'] as bool?) ?? shieldEnabled;
      profileEnabled = (result['profileEnabled'] as bool?) ?? profileEnabled;

      if (stripePublishableKey == null || stripePublishableKey!.isEmpty) {
        stripePublishableKey = dotenv.maybeGet('STRIPE_PUBLISHABLE_KEY');
      }
      if (googleApiKey == null || googleApiKey!.isEmpty) {
        googleApiKey = dotenv.maybeGet('MAPS_API_KEY') ?? dotenv.maybeGet('GOOGLE_MAPS_API_KEY');
      }
      offlineSmsNumber ??= dotenv.maybeGet('OFFLINE_SMS_NUMBER');
      // Flags por .env
      final envBottom = dotenv.maybeGet('BOTTOM_CAROUSEL_ENABLED');
      if (envBottom != null) bottomCarouselEnabled = _toBool(envBottom, bottomCarouselEnabled);
      final envDrawer = dotenv.maybeGet('DRAWER_ENABLED');
      if (envDrawer != null) drawerEnabled = _toBool(envDrawer, drawerEnabled);
      final envOffline = dotenv.maybeGet('OFFLINE_REQUESTS_ENABLED');
      if (envOffline != null) offlineRequestsEnabled = _toBool(envOffline, offlineRequestsEnabled);
      final envShield = dotenv.maybeGet('SHIELD_ENABLED');
      if (envShield != null) shieldEnabled = _toBool(envShield, shieldEnabled);
      final envProfile = dotenv.maybeGet('PROFILE_ENABLED');
      if (envProfile != null) profileEnabled = _toBool(envProfile, profileEnabled);

      if (stripePublishableKey == null || googleApiKey == null) {
        throw Exception('La configuración recibida está incompleta.');
      }

      // Fuerza de flags locales para QA del carrusel, sin depender de remoto/.env
      bottomCarouselEnabled = true;
      drawerEnabled = false;
      offlineRequestsEnabled = true;
      shieldEnabled = true;
      profileEnabled = true;

      developer.log('🟢 Configuración obtenida correctamente.', name: 'AppConfig');
      _isInitialized = true;
    } on FirebaseFunctionsException catch (e) {
      developer.log('💥 Error al obtener config (Functions): ${e.code} - ${e.message}', name: 'AppConfig');
      stripePublishableKey = dotenv.maybeGet('STRIPE_PUBLISHABLE_KEY');
      googleApiKey = dotenv.maybeGet('MAPS_API_KEY') ?? dotenv.maybeGet('GOOGLE_MAPS_API_KEY');
      offlineSmsNumber = dotenv.maybeGet('OFFLINE_SMS_NUMBER');
      final envBottom = dotenv.maybeGet('BOTTOM_CAROUSEL_ENABLED');
      if (envBottom != null) bottomCarouselEnabled = _toBool(envBottom, bottomCarouselEnabled);
      final envDrawer = dotenv.maybeGet('DRAWER_ENABLED');
      if (envDrawer != null) drawerEnabled = _toBool(envDrawer, drawerEnabled);
      final envOffline = dotenv.maybeGet('OFFLINE_REQUESTS_ENABLED');
      if (envOffline != null) offlineRequestsEnabled = _toBool(envOffline, offlineRequestsEnabled);
      final envShield = dotenv.maybeGet('SHIELD_ENABLED');
      if (envShield != null) shieldEnabled = _toBool(envShield, shieldEnabled);
      final envProfile = dotenv.maybeGet('PROFILE_ENABLED');
      if (envProfile != null) profileEnabled = _toBool(envProfile, profileEnabled);
      // Fuerza de flags locales para QA del carrusel, sin depender de remoto/.env
      bottomCarouselEnabled = true;
      drawerEnabled = false;
      offlineRequestsEnabled = true;
      shieldEnabled = true;
      profileEnabled = true;
      _isInitialized = true;
    } on TimeoutException catch (_) {
      developer.log('⏳ Timeout obteniendo config, usando .env', name: 'AppConfig');
      stripePublishableKey = dotenv.maybeGet('STRIPE_PUBLISHABLE_KEY');
      googleApiKey = dotenv.maybeGet('MAPS_API_KEY') ?? dotenv.maybeGet('GOOGLE_MAPS_API_KEY');
      offlineSmsNumber = dotenv.maybeGet('OFFLINE_SMS_NUMBER');
      final envBottom = dotenv.maybeGet('BOTTOM_CAROUSEL_ENABLED');
      if (envBottom != null) bottomCarouselEnabled = _toBool(envBottom, bottomCarouselEnabled);
      final envDrawer = dotenv.maybeGet('DRAWER_ENABLED');
      if (envDrawer != null) drawerEnabled = _toBool(envDrawer, drawerEnabled);
      final envOffline = dotenv.maybeGet('OFFLINE_REQUESTS_ENABLED');
      if (envOffline != null) offlineRequestsEnabled = _toBool(envOffline, offlineRequestsEnabled);
      final envShield = dotenv.maybeGet('SHIELD_ENABLED');
      if (envShield != null) shieldEnabled = _toBool(envShield, shieldEnabled);
      final envProfile = dotenv.maybeGet('PROFILE_ENABLED');
      if (envProfile != null) profileEnabled = _toBool(envProfile, profileEnabled);
      // Fuerza de flags locales para QA del carrusel, sin depender de remoto/.env
      bottomCarouselEnabled = true;
      drawerEnabled = false;
      offlineRequestsEnabled = true;
      shieldEnabled = true;
      profileEnabled = true;
      _isInitialized = true;
    } catch (e) {
      developer.log('💥 Error inesperado al obtener config: $e', name: 'AppConfig');
      stripePublishableKey = dotenv.maybeGet('STRIPE_PUBLISHABLE_KEY');
      googleApiKey = dotenv.maybeGet('MAPS_API_KEY') ?? dotenv.maybeGet('GOOGLE_MAPS_API_KEY');
      offlineSmsNumber = dotenv.maybeGet('OFFLINE_SMS_NUMBER');
      final envBottom = dotenv.maybeGet('BOTTOM_CAROUSEL_ENABLED');
      if (envBottom != null) bottomCarouselEnabled = _toBool(envBottom, bottomCarouselEnabled);
      final envDrawer = dotenv.maybeGet('DRAWER_ENABLED');
      if (envDrawer != null) drawerEnabled = _toBool(envDrawer, drawerEnabled);
      final envOffline = dotenv.maybeGet('OFFLINE_REQUESTS_ENABLED');
      if (envOffline != null) offlineRequestsEnabled = _toBool(envOffline, offlineRequestsEnabled);
      final envShield = dotenv.maybeGet('SHIELD_ENABLED');
      if (envShield != null) shieldEnabled = _toBool(envShield, shieldEnabled);
      final envProfile = dotenv.maybeGet('PROFILE_ENABLED');
      if (envProfile != null) profileEnabled = _toBool(envProfile, profileEnabled);
      // Fuerza de flags locales para QA del carrusel, sin depender de remoto/.env
      bottomCarouselEnabled = true;
      drawerEnabled = false;
      offlineRequestsEnabled = true;
      shieldEnabled = true;
      profileEnabled = true;
      _isInitialized = true;
    }
  }

  bool _toBool(String raw, bool current) {
    final v = raw.toLowerCase().trim();
    if (v == 'true' || v == '1' || v == 'yes' || v == 'on') return true;
    if (v == 'false' || v == '0' || v == 'no' || v == 'off') return false;
    return current;
  }

  // Habilitar Drawer para la sesión actual (no persistente)
  void enableDrawerForSession() {
    drawerSessionEnabled = true;
  }
}
