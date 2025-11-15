import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

class FaqScreen extends StatefulWidget {
  const FaqScreen({super.key});

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  Future<Map<String, dynamic>> _loadFaq() async {
    final raw = await rootBundle.loadString('assets/faq/faq_data.json');
    return json.decode(raw) as Map<String, dynamic>;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Preguntas Frecuentes')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _loadFaq(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snap.hasData || snap.hasError) {
            return const Center(child: Text('No se pudo cargar el FAQ.'));
          }
          final data = snap.data!;
          final sections = [
            {'title': 'Pasajeros', 'key': 'passengers'},
            {'title': 'Conductores', 'key': 'drivers'},
            {'title': 'General', 'key': 'general'},
          ];
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sections.length,
            itemBuilder: (context, i) {
              final sec = sections[i];
              final items = (data[sec['key']] as List<dynamic>).cast<Map<String, dynamic>>();
              return Card(
                child: ExpansionTile(
                  title: Text(sec['title'] as String, style: const TextStyle(fontWeight: FontWeight.w700)),
                  children: items.map((e) {
                    return ListTile(
                      title: Text(e['q'] as String),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(e['a'] as String),
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
