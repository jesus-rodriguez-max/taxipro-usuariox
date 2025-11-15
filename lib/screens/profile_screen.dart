import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _trustedCtrl = TextEditingController();
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('No autenticado');
      final snap = await FirebaseFirestore.instance.collection('passengers').doc(user.uid).get();
      final data = snap.data() ?? <String, dynamic>{};
      _nameCtrl.text = (data['name'] as String?) ?? (user.displayName ?? '');
      _phoneCtrl.text = (data['phone'] as String?) ?? '';
      _trustedCtrl.text = (data['trustedContactPhone'] as String?) ?? '';

      // Cargar desde perfil de seguridad si existe
      final safety = await FirebaseFirestore.instance.collection('safety_profiles').doc(user.uid).get();
      final sdata = safety.data();
      if (sdata != null && (sdata['trustedContactPhone'] as String?) != null) {
        _trustedCtrl.text = sdata['trustedContactPhone'] as String;
      }
    } catch (_) {
      // Mostrar vacío si falla
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('No autenticado');
      await FirebaseFirestore.instance.collection('passengers').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email,
        'name': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'trustedContactPhone': _trustedCtrl.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await FirebaseFirestore.instance.collection('safety_profiles').doc(user.uid).set({
        'trustedContactPhone': _trustedCtrl.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Perfil actualizado')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _confirmDeleteAccount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final email = user.email ?? '';
    final methods = email.isNotEmpty ? await FirebaseAuth.instance.fetchSignInMethodsForEmail(email) : <String>[];

    String? password;
    bool processing = false;

    await showDialog(
      context: context,
      barrierDismissible: !processing,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setState) {
          return AlertDialog(
            title: const Text('Eliminar cuenta'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Esta acción es irreversible. Confirma tu identidad para continuar.'),
                const SizedBox(height: 12),
                if (methods.contains('password'))
                  TextField(
                    obscureText: true,
                    onChanged: (v) => password = v,
                    decoration: const InputDecoration(labelText: 'Contraseña', border: OutlineInputBorder()),
                  )
                else
                  const Text('Vas a reautenticarte con tu proveedor actual (Google).'),
              ],
            ),
            actions: [
              TextButton(onPressed: processing ? null : () => Navigator.of(ctx).pop(), child: const Text('Cancelar')),
              ElevatedButton(
                onPressed: processing
                    ? null
                    : () async {
                        setState(() => processing = true);
                        try {
                          // Reautenticación
                          if (methods.contains('password')) {
                            if (password == null || password!.isEmpty) throw Exception('Ingresa tu contraseña.');
                            final cred = EmailAuthProvider.credential(email: email, password: password!);
                            await user.reauthenticateWithCredential(cred);
                          } else {
                            // Google
                            final googleUser = await GoogleSignIn().signIn();
                            if (googleUser == null) throw Exception('Reautenticación cancelada');
                            final googleAuth = await googleUser.authentication;
                            final credential = GoogleAuthProvider.credential(
                              idToken: googleAuth.idToken,
                              accessToken: googleAuth.accessToken,
                            );
                            await user.reauthenticateWithCredential(credential);
                          }

                          // Eliminar datos en Firestore (perfil)
                          await FirebaseFirestore.instance.collection('passengers').doc(user.uid).delete().catchError((_) {});
                          // Registrar solicitud (opcional)
                          await FirebaseFirestore.instance.collection('account_deletion_requests').add({
                            'uid': user.uid,
                            'email': user.email,
                            'createdAt': FieldValue.serverTimestamp(),
                            'app': 'usuariox',
                          }).catchError((_) {});

                          // Eliminar cuenta
                          await user.delete();
                          if (ctx.mounted) Navigator.of(ctx).pop();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cuenta eliminada.')));
                            // Volver a la pantalla inicial
                            Navigator.of(context).pop();
                          }
                        } catch (e) {
                          setState(() => processing = false);
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('No se pudo eliminar: $e')));
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Eliminar definitivamente'),
              ),
            ],
          );
        });
      },
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _trustedCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Mi Perfil')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              if (user != null) ...[
                Text('Correo', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 4),
                SelectableText(user.email ?? '-', style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Nombre', border: OutlineInputBorder()),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Escribe tu nombre' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Teléfono', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _trustedCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Teléfono de confianza (WhatsApp)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save),
                label: const Text('Guardar cambios'),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: _confirmDeleteAccount,
                icon: const Icon(Icons.delete_forever, color: Colors.red),
                label: const Text('Eliminar cuenta definitivamente', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
