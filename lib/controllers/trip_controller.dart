
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/trip_model.dart'; // Asegúrate que la ruta al modelo es correcta

/// Un controlador que gestiona el estado y la lógica de un viaje (`Trip`).
///
/// Escucha en tiempo real las actualizaciones del documento del viaje en Firestore
/// y notifica a sus oyentes sobre los cambios, especialmente sobre el estado del pago.
class TripController with ChangeNotifier {
  final String tripId;
  StreamSubscription<DocumentSnapshot>? _tripSubscription;
  Trip? _currentTrip;

  Trip? get currentTrip => _currentTrip;

  bool get isPaid => _currentTrip?.paymentStatus == 'paid';

  TripController({required this.tripId}) {
    _listenToTripUpdates();
  }

  /// Se suscribe a los cambios del documento del viaje en Firestore.
  void _listenToTripUpdates() {
    _tripSubscription = FirebaseFirestore.instance
        .collection('trips')
        .doc(tripId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        _currentTrip = Trip.fromFirestore(snapshot);
        
        // Notificar a los oyentes (como la UI) que el viaje ha cambiado.
        notifyListeners();

      } else {
        // El documento del viaje fue eliminado o no existe.
        _currentTrip = null;
        notifyListeners();
      }
    }, onError: (error) {
      print("Error al escuchar actualizaciones del viaje: $error");
      // Considera una estrategia de reintento o notificar al usuario.
    });
  }

  @override
  void dispose() {
    _tripSubscription?.cancel();
    super.dispose();
  }
}
