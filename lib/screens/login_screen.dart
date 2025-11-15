import 'package:flutter/material.dart';
  import 'dart:math' as math;
  import 'package:firebase_auth/firebase_auth.dart';
  import 'package:google_sign_in/google_sign_in.dart';
  import 'package:cloud_firestore/cloud_firestore.dart';
  import 'package:taxipro_usuariox/screens/register_screen.dart';
  import 'package:taxipro_usuariox/screens/privacy_policy_screen.dart';
  import 'package:taxipro_usuariox/screens/terms_and_conditions_screen.dart';
  import 'package:flutter/gestures.dart';

// Clase para pintar el logo de Google según especificaciones oficiales
class GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // ...
    final double width = size.width;
    final double height = size.height;
    
    // Colores oficiales de Google
    final Paint bluePaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;
    
    final Paint redPaint = Paint()
      ..color = const Color(0xFFEA4335)
      ..style = PaintingStyle.fill;
    
    final Paint yellowPaint = Paint()
      ..color = const Color(0xFFFBBC05)
      ..style = PaintingStyle.fill;
    
    final Paint greenPaint = Paint()
      ..color = const Color(0xFF34A853)
      ..style = PaintingStyle.fill;
    
    // Centro
    final Offset center = Offset(width / 2, height / 2);
    
    // Radio del círculo
    final double radius = math.min(width, height) / 2;
    
    // Dibujar partes del logo
    // Parte azul
    final Path bluePath = Path()
      ..moveTo(center.dx, center.dy)
      ..lineTo(center.dx + radius * 0.6, center.dy - radius * 0.6)
      ..arcTo(
          Rect.fromCircle(center: center, radius: radius),
          -math.pi / 4, // Ángulo de inicio
          -math.pi / 2, // Ángulo de barrido
          false)
      ..close();
    canvas.drawPath(bluePath, bluePaint);
    
    // Parte roja
    final Path redPath = Path()
      ..moveTo(center.dx, center.dy)
      ..lineTo(center.dx + radius * 0.6, center.dy + radius * 0.6)
      ..arcTo(
          Rect.fromCircle(center: center, radius: radius),
          math.pi / 4, // Ángulo de inicio
          math.pi / 2, // Ángulo de barrido
          false)
      ..close();
    canvas.drawPath(redPath, redPaint);
    
    // Parte amarilla
    final Path yellowPath = Path()
      ..moveTo(center.dx, center.dy)
      ..lineTo(center.dx - radius * 0.6, center.dy + radius * 0.6)
      ..arcTo(
          Rect.fromCircle(center: center, radius: radius),
          3 * math.pi / 4, // Ángulo de inicio
          math.pi / 2, // Ángulo de barrido
          false)
      ..close();
    canvas.drawPath(yellowPath, yellowPaint);
    
    // Parte verde
    final Path greenPath = Path()
      ..moveTo(center.dx, center.dy)
      ..lineTo(center.dx - radius * 0.6, center.dy - radius * 0.6)
      ..arcTo(
          Rect.fromCircle(center: center, radius: radius),
          5 * math.pi / 4, // Ángulo de inicio
          math.pi / 2, // Ángulo de barrido
          false)
      ..close();
    canvas.drawPath(greenPath, greenPaint);
    
    // Círculo blanco en el centro
    final Paint whitePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.4, whitePaint);
  }
  
  @override
  bool shouldRepaint(GoogleLogoPainter oldDelegate) => false;
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // Para google_sign_in v6.x usamos una instancia directa
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  bool _rememberMe = false;
  bool _passwordVisible = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Las instancias de Auth y GoogleSignIn ahora se inicializan directamente en su declaración.
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _signInWithEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
      
      final user = userCredential.user;
      if (user != null) {
        await _ensurePassengerProfile(user);
        
        // Navegación directa después de login exitoso
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      }
    } on FirebaseAuthException catch (e) {
      final message = e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential'
          ? 'Credenciales incorrectas. Verifique su email y contraseña.'
          : 'Ocurrió un error al iniciar sesión.';
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ocurrió un error inesperado: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      // Flujo de autenticación para google_sign_in v6.x
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // Usuario canceló
        if (mounted) setState(() => _isLoading = false);
        return;
      }
      
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final authResult = await _auth.signInWithCredential(credential);
      final user = authResult.user;
      if (user == null) {
        throw Exception('No se pudo obtener el usuario después de signInWithCredential');
      }

      // Crear/actualizar perfil en passengers/{uid}
      await _ensurePassengerProfile(user);
      
      // NAVEGACIÓN CORRECTA (NAVEGAR AQUÍ MISMO):
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e, stackTrace) {
      debugPrint('Error en Google SignIn: $e\n$stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al iniciar sesión con Google')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _ensurePassengerProfile(User user) async {
    final docRef = FirebaseFirestore.instance.collection('passengers').doc(user.uid);
    final doc = await docRef.get();
    if (!doc.exists) {
      await docRef.set({
        'userId': user.uid,
        'email': user.email,
        'name': user.displayName,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      await docRef.update({
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  void _forgotPassword() async {
    if (_emailCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa tu correo para recuperar tu contraseña.')),
      );
      return;
    }
    try {
      await _auth.sendPasswordResetEmail(email: _emailCtrl.text.trim());
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Correo de recuperación enviado.')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al enviar correo: $e')));
    }
  }

  void _navigateToRegister() {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => const RegisterScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Stack(
          children: [
            Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                children: [
                  const SizedBox(height: 24),
                  Center(child: Image.asset('assets/branding/logo_complete.png', height: 140)), // Logo completo TP + TAXI PRO
                  const SizedBox(height: 48),
                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Correo electrónico',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.email),
                    ),
                    validator: (value) => (value == null || !value.contains('@')) ? 'Ingresa un correo válido' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordCtrl,
                    obscureText: !_passwordVisible,
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(_passwordVisible ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _passwordVisible = !_passwordVisible),
                      ),
                    ),
                    validator: (value) => (value == null || value.length < 6) ? 'La contraseña debe tener al menos 6 caracteres' : null,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(children: [Checkbox(value: _rememberMe, onChanged: (v) => setState(() => _rememberMe = v!)), const Text('Recordarme')]),
                      Flexible(
                        child: TextButton(
                          onPressed: _forgotPassword, 
                          child: const Text(
                            '¿Olvidaste tu contraseña?',
                            textAlign: TextAlign.right,
                          )
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _signInWithEmail,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Ingresar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 12),
                        children: [
                          const TextSpan(text: 'Al continuar, aceptas nuestros '),
                          TextSpan(
                            text: 'Términos de Servicio',
                            style: TextStyle(decoration: TextDecoration.underline, color: Theme.of(context).colorScheme.primary),
                            recognizer: TapGestureRecognizer()..onTap = () => Navigator.push(context, MaterialPageRoute(builder: (_) => TermsAndConditionsScreen(onAccepted: (){ Navigator.pop(context); }))),
                          ),
                          const TextSpan(text: ' y '),
                          TextSpan(
                            text: 'Política de Privacidad',
                            style: TextStyle(decoration: TextDecoration.underline, color: Theme.of(context).colorScheme.primary),
                            recognizer: TapGestureRecognizer()..onTap = () => Navigator.push(context, MaterialPageRoute(builder: (_) => PrivacyPolicyScreen(onAccepted: (){ Navigator.pop(context); }))),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Row(children: const [Expanded(child: Divider()), Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('o')), Expanded(child: Divider())]),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _signInWithGoogle,
                    icon: SizedBox(
                      height: 24,
                      width: 24,
                      child: CustomPaint(painter: GoogleLogoPainter()),
                    ),
                    label: const Text('Continuar con Google'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                      backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade300, width: 1),
                      ),
                      elevation: 1,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: null, // Facebook login no implementado
                    icon: Container(
                      height: 24,
                      width: 24,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text(
                          'f',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1877F2),
                          ),
                        ),
                      ),
                    ),
                    label: const Text('Continuar con Facebook'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: const Color(0xFF1877F2),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 1,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Text('¿No tienes cuenta?'), TextButton(onPressed: _navigateToRegister, child: const Text('Regístrate'))]),
                ],
              ),
            ),
            if (_isLoading)
              Container(color: Colors.black.withAlpha(76), child: const Center(child: CircularProgressIndicator())),
          ],
        ),
      ),
    );
  }
}
