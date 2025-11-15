import 'package:flutter/material.dart';

class IllustrationsScreen extends StatelessWidget {
  const IllustrationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ilustraciones'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          SizedBox(height: 8),
          Text('Vista de ilustraciones en desarrollo.'),
        ],
      ),
    );
  }
}
