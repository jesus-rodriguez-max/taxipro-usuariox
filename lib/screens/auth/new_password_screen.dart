import 'package:flutter/material.dart';

class NewPasswordScreen extends StatefulWidget {
  const NewPasswordScreen({super.key});

  @override
  State<NewPasswordScreen> createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends State<NewPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _newVisible = false;
  bool _confirmVisible = false;

  @override
  void dispose() {
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final onBg = Theme.of(context).colorScheme.onBackground;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 0),
                Center(
                  child: Image.asset(
                    'assets/branding/logo_complete.png',
                    height: 240,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Contraseña nueva',
                  style: TextStyle(color: onBg, fontWeight: FontWeight.w700, fontSize: 16),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _newCtrl,
                  obscureText: !_newVisible,
                  style: TextStyle(color: onBg),
                  decoration: InputDecoration(
                    labelText: 'Contraseña nueva',
                    prefixIcon: const Icon(Icons.lock_outline),
                    filled: true,
                    fillColor: Theme.of(context).inputDecorationTheme.fillColor,
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => _newVisible = !_newVisible),
                      icon: Icon(_newVisible ? Icons.visibility_off : Icons.visibility),
                    ),
                  ),
                  validator: (v) {
                    final value = v ?? '';
                    if (value.length < 8) return 'Mínimo 8 caracteres';
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  'Confirmar contraseña',
                  style: TextStyle(color: onBg, fontWeight: FontWeight.w700, fontSize: 16),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _confirmCtrl,
                  obscureText: !_confirmVisible,
                  style: TextStyle(color: onBg),
                  decoration: InputDecoration(
                    labelText: 'Confirmar contraseña',
                    prefixIcon: const Icon(Icons.lock_outline),
                    filled: true,
                    fillColor: Theme.of(context).inputDecorationTheme.fillColor,
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => _confirmVisible = !_confirmVisible),
                      icon: Icon(_confirmVisible ? Icons.visibility_off : Icons.visibility),
                    ),
                  ),
                  validator: (v) {
                    final value = v ?? '';
                    if (value != _newCtrl.text) return 'No coincide con la nueva contraseña';
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ruleBullet(onBg, 'La contraseña debe tener al menos 8 caracteres.'),
                      _ruleBullet(onBg, 'No puede ser la misma que antes.'),
                      _ruleBullet(onBg, 'No puede ser muy común.'),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      if (!(_formKey.currentState?.validate() ?? false)) return;
                      if (_newCtrl.text == _confirmCtrl.text) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Contraseña cambiada')),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1565C0),
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text(
                      'CAMBIAR CONTRASEÑA',
                      style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.5),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _ruleBullet(Color onBg, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 6, height: 6, margin: const EdgeInsets.only(top: 8), decoration: BoxDecoration(color: onBg.withOpacity(0.8), shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(color: onBg.withOpacity(0.9))))
        ],
      ),
    );
  }
}
