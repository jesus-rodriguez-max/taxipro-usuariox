import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:taxipro_usuariox/screens/home_map_screen.dart';
import 'package:taxipro_usuariox/screens/login_screen.dart';
import 'package:taxipro_usuariox/services/functions_service.dart';
import 'package:taxipro_usuariox/services/app_config_service.dart';
import 'package:taxipro_usuariox/screens/animated_splash_screen.dart';
import 'dart:developer' as developer;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taxipro_usuariox/widgets/legal_consent_modal.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:taxipro_usuariox/screens/trip/select_destination_screen.dart';
import 'package:taxipro_usuariox/screens/trip/driver_assigned_screen.dart';
import 'package:taxipro_usuariox/screens/trip/trip_safety_screen.dart';

// Bandera de aceptación previa (antes del login) durante la sesión actual
bool _preAcceptedTermsThisSession = false;

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    // ⚡️ OPTIMIZACIÓN: Solo refrescar sesión, SIN ejecutar Cloud Functions
    _ensureFirebaseInitialized().timeout(const Duration(seconds: 8), onTimeout: () {});
    
    // ❌ ELIMINADO: No más llamadas automáticas a Cloud Functions en init
    // Las funciones se ejecutarán bajo demanda cuando el usuario las necesite
  }

  // 🔧 MÉTODO MANUAL para inicializar backend cuando se necesite
  Future<void> initializeBackendServicesOnDemand() async {
    try {
      print('[CALLABLE] getPassengerAppConfigCallable started');
      developer.log('[TEST_BACKEND] calling getPassengerAppConfigCallable', name: 'TaxiProUsuarioX');
      
      final result = await CloudFunctionsService.instance
          .callPublic('getPassengerAppConfigCallable', {})
          .timeout(const Duration(seconds: 6));
      
      print('[CALLABLE] getPassengerAppConfigCallable finished');
      developer.log('[TEST_BACKEND_OK] ${result.toString().length > 100 ? result.toString().substring(0, 100) + '...' : result}', name: 'TaxiProUsuarioX');
      
      await AppConfigService.instance.initialize();
      developer.log('✅ Backend conectado exitosamente', name: 'TaxiPro');
    } catch (e) {
      print('[CALLABLE] getPassengerAppConfigCallable error: $e');
      developer.log('[TEST_BACKEND_ERROR] $e', name: 'TaxiProUsuarioX');
      developer.log('🔴 ERROR CRÍTICO - Backend no conecta: $e', name: 'TaxiPro');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Si ya hay sesión, no esperes el stream; procede de inmediato
    if (FirebaseAuth.instance.currentUser != null) {
      return const _LaunchDecider();
    }
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.idTokenChanges(),
      initialData: FirebaseAuth.instance.currentUser,
      builder: (context, snapshot) {
        // Mientras se determina el estado de autenticación, mostrar el splash
        if (snapshot.connectionState == ConnectionState.waiting) {
          return AnimatedSplashScreen();
        }

        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(child: Text('Error cargando datos de usuario')),
          );
        }

        // Si el usuario ha iniciado sesión: decidir a dónde ir según estado del viaje
        if (snapshot.hasData) {
          return const _LaunchDecider();
        }

        // Si no hay sesión: ir a Login directamente (legal modal ya fue mostrado en main)
        return const LoginScreen();
      },
    );
  }

  Future<void> _ensureFirebaseInitialized() async {
    // Asegurar que, si existe un usuario, su sesión esté fresca antes de construir el StreamBuilder
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.reload().timeout(const Duration(seconds: 5));
        await user.getIdToken(true).timeout(const Duration(seconds: 5));
      }
    } catch (_) {}
  }

  Future<void> _ensureLegalAccepted(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final accepted = prefs.getBool('legalAccepted_v2') ?? false;
    if (!accepted) {
      final ok = await LegalConsentModal.show(context);
      if (ok) {
        await prefs.setBool('legalAccepted_v2', true);
      } else {
        // Reintentar hasta aceptar
        return _ensureLegalAccepted(context);
      }
    }
  }

  Future<void> _saveAcceptanceAndProceed(
      String uid, BuildContext context) async {
    try {
      await FirebaseFirestore.instance
          .collection('passengers')
          .doc(uid)
          .set({'termsAccepted': true}, SetOptions(merge: true));
    } catch (_) {}
    if (context.mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/trip/select', (route) => false);
    }
  }
}

class _LaunchDecider extends StatefulWidget {
  const _LaunchDecider();
  @override
  State<_LaunchDecider> createState() => _LaunchDeciderState();
}

class _LaunchDeciderState extends State<_LaunchDecider> {
  Route _fadeTo(Widget child) => PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (_, __, ___) => child,
        transitionsBuilder: (_, animation, __, child) => FadeTransition(opacity: animation, child: child),
      );
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _decide());
  }

  Future<void> _decide() async {
    debugPrint('[AUTH_WRAPPER] _decide start');
    final user = FirebaseAuth.instance.currentUser;
    
    if (user == null) {
      debugPrint('[AUTH_WRAPPER] No user, going to LoginScreen');
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
      return;
    }
    
    // ⚡️ ULTRA-RÁPIDO: Ir directo al HomeMapScreen
    // La lógica de viajes se hará después, dentro del mapa
    debugPrint('[AUTH_WRAPPER] User found, going directly to HomeMapScreen');
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      _fadeTo(HomeMapScreen()),
    );
    
    // ✅ LISTO: Sin consultas a Firestore, sin calls pesadas
  }

  @override
  Widget build(BuildContext context) {
    // Mostrar loader simple mientras decidimos
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

