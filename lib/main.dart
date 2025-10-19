import 'dart:ui';
import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:taxipro_usuariox/screens/animated_splash_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Logs y capturas globales
  FlutterError.onError = (FlutterErrorDetails details) {
    developer.log('🔥 FlutterError: ${details.exception}', name: 'TaxiPro');
    developer.log('${details.stack}', name: 'TaxiPro');
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    developer.log('🔥 Async error: $error', name: 'TaxiPro', stackTrace: stack);
    return true;
  };

  // Inicialización ordenada
  try {
    developer.log('🟡 Cargando dotenv...', name: 'TaxiPro');
    await dotenv.load();
  } catch (_) {}

  try {
    if (Firebase.apps.isEmpty) {
      developer.log('🟡 Inicializando Firebase...', name: 'TaxiPro');
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      developer.log('🟢 Firebase inicializado', name: 'TaxiPro');
    }
  } catch (e, st) {
    developer.log('💥 Error Firebase: $e', name: 'TaxiPro', stackTrace: st);
  }

  try {
    // GoogleSignIn v6 no requiere inicialización global aquí.
  } catch (_) {}

  try {
    final stripeKey = dotenv.env['STRIPE_PUBLISHABLE_KEY'];
    if (stripeKey != null && stripeKey.isNotEmpty) {
      Stripe.publishableKey = stripeKey;
      await Stripe.instance.applySettings();
    }
  } catch (_) {}

  runApp(const TaxiProApp());
}

class TaxiProApp extends StatelessWidget {
  const TaxiProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Taxi Pro UsuarioX',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Manrope',
        scaffoldBackgroundColor: Colors.black,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF206CFF),
          brightness: Brightness.dark,
          surface: const Color(0xFF121212),
        ),
      ),
      themeMode: ThemeMode.dark,
      home: const AnimatedSplashScreen(),
    );
  }
}
