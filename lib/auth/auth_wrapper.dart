import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:taxipro_usuariox/screens/home_map_screen.dart';
import 'package:taxipro_usuariox/screens/login_screen.dart';
import 'package:taxipro_usuariox/screens/terms_and_conditions_screen.dart';
import 'package:taxipro_usuariox/screens/privacy_policy_screen.dart';
import 'package:taxipro_usuariox/firebase_options.dart';

// Bandera de aceptación previa (antes del login) durante la sesión actual
bool _preAcceptedTermsThisSession = false;

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _ensureFirebaseInitialized(),
      builder: (context, initSnapshot) {
        if (initSnapshot.connectionState != ConnectionState.done) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        return StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }

            if (snapshot.hasError) {
              return const Scaffold(body: Center(child: Text('Error cargando datos de usuario')));
            }

            // Si el usuario ha iniciado sesión, verificar termsAccepted
            if (snapshot.hasData) {
              final uid = snapshot.data!.uid;
              // Escucha en tiempo real el documento del usuario para reflejar la aceptación inmediatamente
              return StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
                builder: (context, userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return const Scaffold(body: Center(child: CircularProgressIndicator()));
                  }
                  if (userSnapshot.hasError) {
                    return const Scaffold(body: Center(child: Text('Error cargando datos de usuario')));
                  }

                  final exists = userSnapshot.data?.exists == true;
                  final data = exists ? userSnapshot.data!.data() as Map<String, dynamic>? : null;
                  final accepted = (data != null && data['termsAccepted'] == true);

                  if (!accepted) {
                    // Si el usuario aceptó términos antes del login en esta sesión,
                    // guardamos la aceptación ahora y navegamos al Home.
                    if (_preAcceptedTermsThisSession) {
                      return FutureBuilder<void>(
                        future: _saveAcceptanceAndProceed(uid, context),
                        builder: (_, __) => const Scaffold(body: Center(child: CircularProgressIndicator())),
                      );
                    }
                    return TermsAndConditionsScreen(
                      onAccepted: () {
                        // Mantener Terms en el stack para permitir volver atrás
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => PrivacyPolicyScreen(
                              onAccepted: () async {
                                try {
                                  debugPrint('Iniciando Firebase antes de guardar privacidad...');
                                  if (Firebase.apps.isEmpty) {
                                    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
                                  }
                                  debugPrint('Firebase inicializado correctamente.');

                                  final currentUser = FirebaseAuth.instance.currentUser;
                                  final currentUid = currentUser?.uid;
                                  if (currentUid == null) {
                                    debugPrint('UID nulo después de login. Cerrando sesión.');
                                    await FirebaseAuth.instance.signOut();
                                    return;
                                  }

                                  debugPrint('Guardando termsAccepted para uid=$currentUid ...');
                                  await FirebaseFirestore.instance.collection('users').doc(currentUid).set(
                                    {'termsAccepted': true},
                                    SetOptions(merge: true),
                                  );
                                  debugPrint('termsAccepted guardado. Navegando a Home...');
                                } catch (e, st) {
                                  debugPrint('Error guardando aceptación: $e\n$st');
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Error guardando aceptación: $e')),
                                    );
                                  }
                                }
                                if (context.mounted) {
                                  Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                                    MaterialPageRoute(builder: (_) => const HomeMapScreen()),
                                    (route) => false,
                                  );
                                }
                              },
                            ),
                          ),
                        );
                      },
                    );
                  }

                  return const HomeMapScreen();
                },
              );
            }

            // Si no hay sesión: flujo Terms -> Privacy -> Login (aceptación previa en memoria)
            return TermsAndConditionsScreen(
              onAccepted: () {
                // Mantener Terms en el stack para permitir volver atrás
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => PrivacyPolicyScreen(
                      onAccepted: () {
                        _preAcceptedTermsThisSession = true;
                        // Ir a Login limpiando el stack para evitar volver a legales
                        Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                          (route) => false,
                        );
                      },
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _ensureFirebaseInitialized() async {
    if (Firebase.apps.isEmpty) {
      try {
        await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      } catch (_) {}
    }
  }

  Future<void> _saveAcceptanceAndProceed(String uid, BuildContext context) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set(
        {'termsAccepted': true},
        SetOptions(merge: true),
      );
    } catch (_) {}
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeMapScreen()),
        (route) => false,
      );
    }
  }
}
