import 'package:flutter/material.dart';

class TermsAndConditionsScreen extends StatelessWidget {
  final VoidCallback onAccepted;

  const TermsAndConditionsScreen({super.key, required this.onAccepted});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Términos y Condiciones'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Text(
            'Aquí va el texto completo de los Términos y Condiciones...\n\n' 
            'Sed ut perspiciatis unde omnis iste natus error sit voluptatem. ...'
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: ElevatedButton(
            onPressed: onAccepted,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              minimumSize: const Size(double.infinity, 50),
            ),
            child: const Text(
              'He leído y acepto los Términos y Condiciones',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}
