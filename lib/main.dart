import 'dart:ui';
import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:taxipro_usuariox/screens/splash_screen.dart';
import 'package:taxipro_usuariox/screens/login_screen.dart';
import 'package:taxipro_usuariox/screens/auth/verify_account_screen.dart';
import 'package:taxipro_usuariox/screens/auth/reset_password_screen.dart';
import 'package:taxipro_usuariox/screens/auth/new_password_screen.dart';
import 'package:taxipro_usuariox/auth/auth_wrapper.dart';
import 'firebase_options.dart';
import 'package:taxipro_usuariox/theme.dart';
import 'package:taxipro_usuariox/services/app_config_service.dart';
import 'package:taxipro_usuariox/config/production_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taxipro_usuariox/widgets/terms_and_conditions_modal.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;
import 'package:flutter/foundation.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:taxipro_usuariox/screens/trip/select_destination_screen.dart';
import 'package:taxipro_usuariox/screens/trip/trip_estimate_screen.dart';
import 'package:taxipro_usuariox/screens/trip/driver_assigned_screen.dart';
import 'package:taxipro_usuariox/screens/trip/trip_safety_screen.dart';
import 'package:taxipro_usuariox/screens/info/illustrations_screen.dart';
import 'package:taxipro_usuariox/screens/wallet_screen.dart';
import 'package:taxipro_usuariox/screens/faq/faq_screen.dart';
import 'package:taxipro_usuariox/screens/support/support_screen.dart';
import 'package:taxipro_usuariox/screens/legal/legal_screen.dart';
import 'package:taxipro_usuariox/screens/settings/settings_screen.dart';
// (sin imports de rutas de depuración)
import 'package:taxipro_usuariox/screens/safety/safety_screen.dart';
import 'package:taxipro_usuariox/screens/home_map_screen.dart';
import 'package:taxipro_usuariox/screens/profile_screen.dart';
import 'package:taxipro_usuariox/screens/offline/offline_request_screen.dart';
import 'package:taxipro_usuariox/screens/offline/offline_confirm_screen.dart';
import 'package:taxipro_usuariox/screens/offline/offline_sent_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 🔥 MOSTRAR CONFIGURACIÓN DE PRODUCCIÓN
  print('🚀 TAXIPRO USUARIOX - ${AppConfig.configMessage}');
  print('🎯 Stripe Real: ${ProductionConfig.useRealStripe}');
  print('🎤 Audio Real: ${ProductionConfig.useRealAudioRecording}');
  print('🛡️ Shield Real: ${ProductionConfig.enableBackgroundRecording}');

  FlutterError.onError = (details) {
    developer.log(
      '❌ Flutter error: ${details.exception}',
      name: 'TaxiPro',
      stackTrace: details.stack,
      error: details.exception,
      level: 1000,
    );
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    developer.log('🔥 Async error: $error', name: 'TaxiPro', stackTrace: stack);
    return true;
  };

  // Inicialización centralizada de Firebase
  try {
    if (Firebase.apps.isEmpty) {
      developer.log('🟡 Inicializando Firebase en main...', name: 'TaxiPro');
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      await FirebaseAppCheck.instance.activate(
        androidProvider: AndroidProvider.playIntegrity,
      );
      
      developer.log('[FIREBASE_INIT_OK] Firebase inicializado correctamente', name: 'TaxiProUsuarioX');
    } else {
      developer.log('🟢 Firebase ya estaba inicializado (main).', name: 'TaxiPro');
      Firebase.app();
    }
  } catch (e, stack) {
    developer.log(
      '[FIREBASE_INIT_ERROR] $e',
      name: 'TaxiProUsuarioX',
      error: e,
      stackTrace: stack,
      level: 1000,
    );
  }

  try {
    print("🚀 runApp() se ejecuta AHORA. El splash animado debería aparecer.");
    // Iniciar cargas en background para no bloquear el splash nativo
    () async { 
      try { 
        await dotenv.load(fileName: ".env"); 
        developer.log('✅ .env cargado correctamente', name: 'TaxiPro');
      } catch (e) { 
        developer.log('🟡 .env no disponible: $e', name: 'TaxiPro');
      } 
    }();
    // ⚠️ NO ejecutar Cloud Functions en main() - mover a postFrameCallback después de login
    // Lanzar la app inmediatamente
    runApp(const TaxiProApp());
  } catch (e, stack) {
    developer.log(
      '🚨 FALLA CRÍTICA EN MAIN: No se pudo arrancar la app.',
      name: 'TaxiPro',
      error: e,
      stackTrace: stack,
    );
  }
}

class TaxiProApp extends StatelessWidget {
  const TaxiProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Taxi Pro UsuarioX',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const AuthWrapper(),
        '/auth/verify': (context) => const VerifyAccountScreen(),
        '/auth/reset': (context) => const ResetPasswordScreen(),
        '/auth/new-password': (context) => const NewPasswordScreen(),
        '/map': (context) => const HomeMapScreen(),
        '/safety': (context) => const SafetyScreen(),
        '/safety/shield': (context) => const SafetyScreen(),
        '/faq': (context) => const FaqScreen(),
        '/profile/edit': (context) => const ProfileScreen(),
        '/offline/request': (context) => const OfflineRequestScreen(),
        '/offline/confirm': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          if (args == null) return const OfflineRequestScreen();
          return OfflineConfirmScreen(
            origin: args['origin'] as LatLng,
            originAddress: (args['originAddress'] as String?) ?? 'Mi ubicación actual',
            destination: args['destination'] as LatLng,
            destinationAddress: (args['destinationAddress'] as String?) ?? '',
          );
        },
        '/offline/sent': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          final number = (args?['number'] as String?) ?? '';
          return OfflineSentScreen(number: number);
        },
        '/trip/select': (context) => const SelectDestinationScreen(),
        '/trip/estimate': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          if (args == null) {
            // Fallback: regresa a select si faltan argumentos
            return const SelectDestinationScreen();
          }
          return TripEstimateScreen(
            origin: args['origin'] as LatLng,
            destination: args['destination'] as LatLng,
            originAddress: (args['originAddress'] as String?) ?? '',
            destinationAddress: (args['destinationAddress'] as String?) ?? '',
            distanceKm: (args['distanceKm'] as num).toDouble(),
            durationMin: (args['durationMin'] as num).toInt(),
            polylinePoints: (args['polylinePoints'] as List<dynamic>).cast<LatLng>(),
          );
        },
        '/trip/driver-assigned': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          if (args == null) {
            return const SelectDestinationScreen();
          }
          return DriverAssignedScreen(
            tripId: args['tripId'] as String,
            origin: args['origin'] as LatLng,
            destination: args['destination'] as LatLng,
          );
        },
        '/trip/safety': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          if (args == null) {
            return const SelectDestinationScreen();
          }
          return TripSafetyScreen(tripId: args['tripId'] as String);
        },
        // Drawer routes
        '/info/illustrations': (context) => const IllustrationsScreen(),
        '/wallet': (context) => const WalletScreen(),
        // '/help/faq' removida: usar '/faq'
        '/support': (context) => const SupportScreen(),
        '/legal': (context) => const LegalScreen(),
        '/settings': (context) => const SettingsScreen(),
        // (Sin rutas de depuración)
      },
    );
  }
}

class AnimatedSplashScreenLoader extends StatefulWidget {
  const AnimatedSplashScreenLoader({super.key});

  @override
  State<AnimatedSplashScreenLoader> createState() =>
      _AnimatedSplashScreenLoaderState();
}

class _AnimatedSplashScreenLoaderState
    extends State<AnimatedSplashScreenLoader> {
  late final Future<void> _initializationFuture;
  bool _navigated = false;
  Timer? _fallbackTimer;

  @override
  void initState() {
    super.initState();
    _initializationFuture = _initBackend();
    // Fallback: si algo del init tarda demasiado, navegar a /home para no bloquear
    _fallbackTimer = Timer(const Duration(seconds: 10), () {
      if (mounted && !_navigated) {
        Navigator.of(context).pushReplacementNamed('/home');
        _navigated = true;
      }
    });
  }

  Future<void> _initBackend() async {
    developer.log('⚡️ Iniciando inicialización asíncrona en el splash...',
        name: 'TaxiPro');
    try {
      // 1. Cargar .env
      await dotenv.load(fileName: ".env");
      developer.log("🧪 .env cargado en background.", name: 'TaxiPro');
      
      // 2. ⚡️ OPTIMIZACIÓN: Configurar Stripe SOLO desde .env (sin backend)
      try {
        final stripeKey = dotenv.env['STRIPE_PUBLISHABLE_KEY'];
        if (stripeKey != null && stripeKey.isNotEmpty) {
          stripe.Stripe.publishableKey = stripeKey;
          stripe.Stripe.merchantIdentifier = 'taxipro.usuariox';
          await stripe.Stripe.instance.applySettings();
          developer.log('⚡️ Stripe configurado desde .env (FAST INIT)', name: 'TaxiPro');
        } else {
          developer.log('🔴 STRIPE_PUBLISHABLE_KEY no encontrado en .env', name: 'TaxiPro');
        }
      } catch (e) {
        developer.log('🔴 Error configurando Stripe: $e', name: 'TaxiPro');
      }
      
      // 3. Simular tiempo de splash
      await Future.delayed(const Duration(milliseconds: 1200));

      // 4. Gate legal obligatorio antes de cualquier pantalla funcional
      final prefs = await SharedPreferences.getInstance();
      final accepted = prefs.getBool('legalAccepted') ?? false;
      if (mounted && !accepted) {
        final ok = await TermsAndConditionsModal.show(context);
        if (ok) {
          await prefs.setBool('legalAccepted', true);
        } else {
          // Reintentar hasta aceptar
          return await _initBackend();
        }
      }

      if (mounted) {
        final defaultRoute = WidgetsBinding.instance.platformDispatcher.defaultRouteName;
        final target = (defaultRoute.isNotEmpty && defaultRoute != '/') ? defaultRoute : '/home';
        Navigator.of(context).pushReplacementNamed(target);
        developer.log('🟢 Inicialización completa, navegando a $target', name: 'TaxiPro');
        _navigated = true;
        _fallbackTimer?.cancel();
      }
    } catch (e, stack) {
      developer.log(
        '❌ Error en _initBackend (Splash): $e',
        name: 'TaxiPro',
        error: e,
        stackTrace: stack,
        level: 1000,
      );
      // Evitar pantalla roja: continuar flujo a home
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
        _navigated = true;
        _fallbackTimer?.cancel();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initializationFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            !snapshot.hasError) {
          return const SizedBox.shrink();
        }

        if (snapshot.hasError) {
          return Container(
            color: Colors.red.shade900,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'ERROR FATAL DE INICIALIZACIÓN:\n\n${snapshot.error.toString()}',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}

