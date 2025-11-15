import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:taxipro_usuariox/screens/home_map_screen.dart';
import 'package:taxipro_usuariox/screens/login_screen.dart';
import 'package:taxipro_usuariox/services/functions_service.dart';
import 'package:taxipro_usuariox/screens/animated_splash_screen.dart';
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
    // Refrescar sesión en segundo plano, sin bloquear la UI
    _ensureFirebaseInitialized().timeout(const Duration(seconds: 8), onTimeout: () {});
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
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
      return;
    }
    try {
      final uid = user.uid;
      // Obtener últimos viajes del usuario y decidir según status
      final qs = await FirebaseFirestore.instance
          .collection('trips')
          .where('passengerId', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get()
          .timeout(const Duration(seconds: 4));

      Map<String, dynamic>? chosen;
      String chosenStatus = '';
      for (final d in qs.docs) {
        final data = d.data();
        final status = (data['status'] as String?) ?? '';
        if (status == 'active') { chosen = {'id': d.id, ...data}; chosenStatus = status; break; }
        if (status == 'assigned' && chosen == null) { chosen = {'id': d.id, ...data}; chosenStatus = status; }
        if (status == 'pending' && chosen == null) { chosen = {'id': d.id, ...data}; chosenStatus = status; }
      }

      if (!mounted) return;
      if (chosen == null) {
        Navigator.of(context).pushReplacement(_fadeTo(const SelectDestinationScreen()));
        return;
      }

      final id = chosen['id'] as String;
      LatLng? _getLatLngFrom(dynamic raw) {
        if (raw is! Map) return null;
        final m = raw.map((k, v) => MapEntry(k.toString(), v));
        double? lat;
        double? lng;
        if (m['point'] is Map) {
          final p = (m['point'] as Map).map((k, v) => MapEntry(k.toString(), v));
          lat = (p['lat'] as num?)?.toDouble();
          lng = (p['lng'] as num?)?.toDouble();
        }
        lat ??= (m['lat'] as num?)?.toDouble() ?? (m['latitude'] as num?)?.toDouble();
        lng ??= (m['lng'] as num?)?.toDouble() ?? (m['longitude'] as num?)?.toDouble();
        if (lat == null || lng == null) return null;
        return LatLng(lat, lng);
      }

      if (chosenStatus == 'active') {
        Navigator.of(context).pushReplacement(_fadeTo(TripSafetyScreen(tripId: id)));
        return;
      }

      // assigned o pending → pantalla de chofer/espera
      final origin = _getLatLngFrom(chosen['origin']);
      final dest = _getLatLngFrom(chosen['destination']);
      if (origin != null && dest != null) {
        Navigator.of(context).pushReplacement(_fadeTo(DriverAssignedScreen(tripId: id, origin: origin, destination: dest)));
      } else {
        Navigator.of(context).pushReplacement(
          _fadeTo(DriverAssignedScreen(
            tripId: id,
            origin: const LatLng(22.1565, -100.9855),
            destination: const LatLng(22.1565, -100.9855),
          )),
        );
      }
    } catch (_) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(_fadeTo(const SelectDestinationScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Mostrar inmediatamente la pantalla por defecto mientras decidimos (evita flicker de spinner)
    return const SelectDestinationScreen();
  }
}

