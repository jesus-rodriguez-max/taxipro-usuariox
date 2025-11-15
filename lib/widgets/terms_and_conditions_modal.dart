import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:taxipro_usuariox/screens/legal_document_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TermsAndConditionsModal extends StatefulWidget {
  const TermsAndConditionsModal({super.key});

  static Future<bool> show(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const TermsAndConditionsModal(),
    );
    return result == true;
  }

  @override
  State<TermsAndConditionsModal> createState() => _TermsAndConditionsModalState();
}

class _TermsAndConditionsModalState extends State<TermsAndConditionsModal> {
  bool _accepted = false;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 560,
                maxHeight: size.height * 0.92,
              ),
              child: Material(
                color: Colors.white,
                elevation: 6,
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(24, 22, 24, 22 + MediaQuery.of(context).viewInsets.bottom),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minHeight: constraints.maxHeight - 44),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 60),
                              SizedBox(
                                height: size.height * 0.35,
                                child: Image.asset(
                                  'assets/branding/escudo_modal.png',
                                  alignment: Alignment.center,
                                  fit: BoxFit.scaleDown,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Aceptación y Legalidad',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: Colors.black87,
                                    ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Tu seguridad es nuestra prioridad. Por favor, revisa y acepta nuestros términos para acceder a la única plataforma de transporte legal en S.L.P.',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black87, height: 1.4),
                              ),
                              const SizedBox(height: 10),
                              Center(
                                child: TextButton(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => const LegalDocumentScreen(
                                          title: 'Aviso de Privacidad y Términos de Uso',
                                          assetPath: 'assets/legal/aviso_privacidad_terminos.html',
                                        ),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    'Ver Aviso de Privacidad y Términos de Uso',
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.primary,
                                      fontWeight: FontWeight.w700,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Theme(
                                data: Theme.of(context).copyWith(
                                  checkboxTheme: Theme.of(context).checkboxTheme.copyWith(
                                    side: MaterialStateBorderSide.resolveWith((states) => BorderSide(color: Colors.grey.shade500, width: 1.6)),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                    fillColor: MaterialStateProperty.resolveWith((states) {
                                      if (states.contains(MaterialState.selected)) {
                                        return Theme.of(context).colorScheme.primary;
                                      }
                                      return Colors.white;
                                    }),
                                    checkColor: MaterialStateProperty.all(Colors.white),
                                  ),
                                ),
                                child: CheckboxListTile(
                                  contentPadding: EdgeInsets.zero,
                                  value: _accepted,
                                  onChanged: (v) => setState(() => _accepted = v ?? false),
                                  title: const Text(
                                    'He leído y acepto el acuerdo legal de TaxiPro.',
                                    style: TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w400),
                                  ),
                                  controlAffinity: ListTileControlAffinity.leading,
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _accepted
                                      ? () async {
                                          final prefs = await SharedPreferences.getInstance();
                                          await prefs.setBool('legalAccepted', true);
                                          if (mounted) Navigator.of(context).pop(true);
                                        }
                                      : null,
                                  style: ButtonStyle(
                                    backgroundColor: MaterialStateProperty.resolveWith<Color?>((states) {
                                      if (states.contains(MaterialState.disabled)) {
                                        return Colors.grey.shade300;
                                      }
                                      return Theme.of(context).colorScheme.primary;
                                    }),
                                    foregroundColor: MaterialStateProperty.resolveWith<Color?>((states) {
                                      if (states.contains(MaterialState.disabled)) {
                                        return Colors.grey.shade600;
                                      }
                                      return Colors.white;
                                    }),
                                    padding: MaterialStateProperty.all(const EdgeInsets.symmetric(vertical: 14)),
                                    shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                                    elevation: MaterialStateProperty.all(0),
                                  ),
                                  child: const Text(
                                    'CONTINUAR',
                                    style: TextStyle(fontFamily: 'Manrope', fontWeight: FontWeight.w700, letterSpacing: 0.5),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Center(
                                child: TextButton(
                                  onPressed: () => Navigator.of(context).pop(false),
                                  child: const Text('Cancelar / Salir'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
