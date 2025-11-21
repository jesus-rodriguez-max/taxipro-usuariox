import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../lib/firebase_options.dart';

void main() async {
  print('🔵 Test de Authentication');
  print('=' * 50);
  
  try {
    print('⏳ Inicializando Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase inicializado');
    
    final email = 'test-${DateTime.now().millisecondsSinceEpoch}@taxipro.com';
    final password = 'Test123456';
    
    print('📧 Email: $email');
    print('🔑 Password: $password');
    print('');
    
    print('⏳ Intentando crear usuario en Authentication...');
    
    final userCredential = await FirebaseAuth.instance
        .createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
    
    print('');
    print('✅ ÉXITO EN AUTHENTICATION');
    print('✅ UID: ${userCredential.user?.uid}');
    print('✅ Email verificado: ${userCredential.user?.emailVerified}');
    print('');
    print('🎯 Authentication funciona perfectamente');
    print('🎯 El problema NO es Authentication');
    print('🎯 El problema está en:');
    print('   - Firestore Rules');
    print('   - O en código que crea documento Firestore');
    
  } on FirebaseAuthException catch (e) {
    print('');
    print('❌ ERROR EN AUTHENTICATION');
    print('❌ Código: ${e.code}');
    print('❌ Mensaje: ${e.message}');
    print('');
    print('🎯 El problema ES Authentication');
    print('🎯 Posibles causas:');
    print('   - Email/Password no habilitado en Firebase');
    print('   - API Key incorrecta');
    print('   - google-services.json incorrecto');
    
  } catch (e) {
    print('');
    print('❌ ERROR GENERAL: $e');
    print('❌ Tipo: ${e.runtimeType}');
  }
  
  exit(0);
}
