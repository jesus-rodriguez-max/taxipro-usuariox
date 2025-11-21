import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Registrar usuario con email, contraseña y nombre visible
  Future<User?> register(String email, String password, String displayName) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );

    final user = cred.user;
    if (user == null) throw Exception("No se pudo crear el usuario.");

    // Crear documento en Firestore
    await _db.collection('passengers').doc(user.uid).set({
      'uid': user.uid,
      'email': email.trim(),
      'displayName': displayName.trim(),
      'createdAt': FieldValue.serverTimestamp(),
      'acceptedTerms': true,
      'acceptedPrivacy': true,
    });

    return user;
  }

  /// Iniciar sesión con email y contraseña
  Future<User?> login(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
    return cred.user;
  }

  /// Cerrar sesión
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Obtener usuario actual
  User? get currentUser => _auth.currentUser;
}

