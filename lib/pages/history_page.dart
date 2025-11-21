// lib/pages/history_page.dart

import 'package:flutter/material.dart';

/// Página de historial de viajes.
/// En esta plantilla se listan los viajes anteriores del usuario. Por
/// simplicidad, los datos son estáticos y deben reemplazarse con
/// información real proveniente del backend.
class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final trips = [
      {'fecha': '2025-10-21', 'origen': 'Centro', 'destino': 'Aeropuerto'},
      {'fecha': '2025-10-18', 'origen': 'Casa', 'destino': 'Oficina'},
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de viajes'),
      ),
      body: ListView.builder(
        itemCount: trips.length,
        itemBuilder: (context, index) {
          final trip = trips[index];
          return ListTile(
            leading: const Icon(Icons.local_taxi),
            title: Text('${trip['origen']} → ${trip['destino']}'),
            subtitle: Text('Fecha: ${trip['fecha']}'),
          );
        },
      ),
    );
  }
}
