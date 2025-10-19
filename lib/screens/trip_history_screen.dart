import 'package:flutter/material.dart';
  import 'package:cloud_firestore/cloud_firestore.dart';
  import 'package:taxipro_usuariox/models/driver_model.dart';
  import 'package:taxipro_usuariox/models/trip_model.dart';

class TripHistoryScreen extends StatefulWidget {
  const TripHistoryScreen({super.key});

  @override
  State<TripHistoryScreen> createState() => _TripHistoryScreenState();
}

class _TripHistoryScreenState extends State<TripHistoryScreen> {
  String _formatDate(Timestamp ts) {
    final dt = ts.toDate();
    const months = [
      'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic'
    ];
    final dd = dt.day.toString().padLeft(2, '0');
    final mmm = months[dt.month - 1];
    final yyyy = dt.year.toString();
    int hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final mm = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$dd $mmm $yyyy, ${hour.toString().padLeft(2, '0')}:$mm $ampm';
  }
  // Lista de ejemplo de viajes. En una app real, vendría de una base de datos.
  final List<Trip> _trips = [
    Trip(
      id: 'trip_1',
      userId: 'user_123',
      originAddress: 'Av. Venustiano Carranza 123',
      destinationAddress: 'Plaza del Carmen, Centro Histórico',
      createdAt: Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 2))),
      fare: 85.50,
      status: 'completed',
      driver: Driver.sample(),
    ),
    Trip(
      id: 'trip_2',
      userId: 'user_123',
      originAddress: 'Parque Tangamanga I, Entrada Principal',
      destinationAddress: 'Aeropuerto Internacional Ponciano Arriaga',
      createdAt: Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 10))),
      fare: 220.00,
      status: 'completed',
      driver: Driver.sample(),
    ),
    Trip(
      id: 'trip_3',
      userId: 'user_123',
      originAddress: 'Morales, Saucito',
      destinationAddress: 'Plaza San Luis',
      createdAt: Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 25))),
      fare: 110.75,
      status: 'completed',
      driver: Driver.sample(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Viajes'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: _trips.isEmpty
          ? const Center(
              child: Text(
                'Aún no has realizado ningún viaje.',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: _trips.length,
              itemBuilder: (context, index) {
                final trip = _trips[index];
                return Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16.0),
                    leading: Icon(Icons.directions_car, color: Theme.of(context).colorScheme.primary, size: 40),
                    title: Text(
                      trip.destinationAddress,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text('Desde: ${trip.originAddress}', maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 8),
                        Text(_formatDate(trip.createdAt),
                            style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                    trailing: Text(
                      '\$${trip.fare?.toStringAsFixed(2) ?? 'N/A'}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    onTap: () {
                      // TODO: Mostrar detalles del viaje
                    },
                  ),
                );
              },
            ),
    );
  }
}
