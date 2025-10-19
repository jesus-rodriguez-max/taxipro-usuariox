import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:taxipro_usuariox/screens/privacy_policy_screen.dart';
import 'package:taxipro_usuariox/screens/terms_and_conditions_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  late final FirebaseAuth _auth;
  bool _firebaseInitialized = true; // Suponemos que Firebase está inicializado
  
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;
  bool _isLoading = false;
  bool _acceptTerms = false;

  @override
  void initState() {
    super.initState();
    // Inicializar Firebase Auth con manejo de errores
    try {
      _auth = FirebaseAuth.instance;
    } catch (e) {
      // Idealmente, usar un logger en lugar de print.
      _firebaseInitialized = false;
    }
  }
  
  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  // Validar que las contraseñas coincidan
  bool _validatePasswords() {
    return _passwordCtrl.text == _confirmPasswordCtrl.text;
  }

  // Registrar usuario
  Future<void> _registerUser() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final scaffoldMessenger = ScaffoldMessenger.of(context);

    if (!_validatePasswords()) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Las contraseñas no coinciden')),
      );
      return;
    }

    if (!_acceptTerms) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Debes aceptar los términos y condiciones')),
      );
      return;
    }
    
    // Verificar si Firebase está inicializado
    if (!_firebaseInitialized) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('El servicio de registro no está disponible en este momento')),
      );
      return;
    }

    final navigator = Navigator.of(context);

    setState(() {
      _isLoading = true;
    });

    try {
      // Crear usuario en Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );

      final user = userCredential.user;
      if (user == null) return; // Salir si el usuario es nulo

      // Crear documento de usuario en Firestore
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'name': _nameCtrl.text.trim(),
        'email': user.email,
        'createdAt': FieldValue.serverTimestamp(),
        'termsAccepted': true, // Ya aceptó en el registro
      });

      // Actualizar el perfil con el nombre del usuario
      await user.updateDisplayName(_nameCtrl.text.trim());
      
      // Enviar correo de verificación
      await user.sendEmailVerification();

      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Cuenta creada exitosamente. Se ha enviado un correo de verificación.')),
      );

      // Volver a la pantalla de login
      navigator.pop();
    } on FirebaseAuthException catch (e) {
      String message = 'Error al registrar usuario';
      if (e.code == 'weak-password') {
        message = 'La contraseña es demasiado débil';
      } else if (e.code == 'email-already-in-use') {
        message = 'Ya existe una cuenta con este correo electrónico';
      } else if (e.code == 'invalid-email') {
        message = 'El correo electrónico no es válido';
      }
      
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('Registro'),
        elevation: 0,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                children: [
                  const SizedBox(height: 24),
                  
                  // Logo completo TP + TAXI PRO
                  Center(child: Image.asset('assets/branding/logo_complete.png', height: 120)),
                  const SizedBox(height: 24),
                  
                  // Título
                  const Text('Crear cuenta',
                      textAlign: TextAlign.left,
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 24),
                  
                  // Nombre completo
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: InputDecoration(
                      labelText: 'Nombre completo',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.person),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingresa tu nombre';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Correo electrónico
                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Correo electrónico',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.email),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingresa tu correo';
                      }
                      if (!value.contains('@') || !value.contains('.')) {
                        return 'Ingresa un correo válido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Contraseña
                  TextFormField(
                    controller: _passwordCtrl,
                    obscureText: !_passwordVisible,
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _passwordVisible ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _passwordVisible = !_passwordVisible;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingresa una contraseña';
                      }
                      if (value.length < 8) {
                        return 'Debe tener al menos 8 caracteres';
                      }
                      if (!value.contains(RegExp(r'[A-Z]'))) {
                        return 'Debe contener al menos una mayúscula';
                      }
                      if (!value.contains(RegExp(r'[a-z]'))) {
                        return 'Debe contener al menos una minúscula';
                      }
                      if (!value.contains(RegExp(r'[0-9]'))) {
                        return 'Debe contener al menos un número';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Confirmar contraseña
                  TextFormField(
                    controller: _confirmPasswordCtrl,
                    obscureText: !_confirmPasswordVisible,
                    decoration: InputDecoration(
                      labelText: 'Confirmar contraseña',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_confirmPasswordVisible ? Icons.visibility_off : Icons.visibility),
                        onPressed: () {
                          setState(() {
                            _confirmPasswordVisible = !_confirmPasswordVisible;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor confirma tu contraseña';
                      }
                      if (value != _passwordCtrl.text) {
                        return 'Las contraseñas no coinciden';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Términos y condiciones
                  Row(
                    children: [
                      Checkbox(
                        value: _acceptTerms,
                        onChanged: (value) {
                          setState(() {
                            _acceptTerms = value ?? false;
                          });
                        },
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _acceptTerms = !_acceptTerms;
                            });
                          },
                          child: RichText(
                            text: TextSpan(
                              text: 'Acepto los ',
                              style: Theme.of(context).textTheme.bodyMedium,
                              children: [
                                TextSpan(
                                  text: 'términos y condiciones',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.primary,
                                    decoration: TextDecoration.underline,
                                  ),
                                  recognizer: (TapGestureRecognizer()
                                    ..onTap = () async {
                                      final accepted = await Navigator.push<bool>(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => TermsAndConditionsScreen(
                                            onAccepted: () => Navigator.pop(context, true),
                                          ),
                                        ),
                                      );
                                      if (accepted == true) {
                                        if (mounted) setState(() => _acceptTerms = true);
                                      }
                                    }),
                                ),
                                const TextSpan(
                                  text: ' y la ',
                                ),
                                TextSpan(
                                  text: 'política de privacidad',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.primary,
                                    decoration: TextDecoration.underline,
                                  ),
                                  recognizer: (TapGestureRecognizer()
                                    ..onTap = () async {
                                      final accepted = await Navigator.push<bool>(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => PrivacyPolicyScreen(
                                            onAccepted: () => Navigator.pop(context, true),
                                          ),
                                        ),
                                      );
                                      if (accepted == true) {
                                        if (mounted) setState(() => _acceptTerms = true);
                                      }
                                    }),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Botón de registro
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: (!_acceptTerms || _isLoading) ? null : _registerUser,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        backgroundColor: Theme.of(context).primaryColor,
                      ),
                      child: const Text(
                        'Registrarme',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          fontSize: 16
                        )
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
            
            // Indicador de carga
            if (_isLoading)
              Container(
                color: Colors.black.withAlpha(76),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
