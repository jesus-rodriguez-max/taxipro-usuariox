import 'package:cloud_firestore/cloud_firestore.dart';
  import 'package:taxipro_usuariox/models/driver_model.dart';
  
  class Trip {
  // Factory constructor to create a Trip object from a Firestore document
  factory Trip.fromFirestore(DocumentSnapshot doc) {
    final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // Backward compatibility: flat vs nested origin/destination
    String originAddress = data['originAddress'] ?? '';
    String destinationAddress = data['destinationAddress'] ?? '';
    double? originLat;
    double? originLng;
    double? destinationLat;
    double? destinationLng;

    if (data['origin'] is Map<String, dynamic>) {
      final o = data['origin'] as Map<String, dynamic>;
      originAddress = o['address'] ?? originAddress;
      originLat = (o['lat'] as num?)?.toDouble();
      originLng = (o['lng'] as num?)?.toDouble();
    }
    if (data['destination'] is Map<String, dynamic>) {
      final d = data['destination'] as Map<String, dynamic>;
      destinationAddress = d['address'] ?? destinationAddress;
      destinationLat = (d['lat'] as num?)?.toDouble();
      destinationLng = (d['lng'] as num?)?.toDouble();
    }

    return Trip(
      id: doc.id,
      userId: data['userId'] ?? '',
      driverId: data['driverId'],
      originAddress: originAddress,
      originLat: originLat,
      originLng: originLng,
      destinationAddress: destinationAddress,
      destinationLat: destinationLat,
      destinationLng: destinationLng,
      createdAt: data['createdAt'] ?? Timestamp.now(),
      status: data['status'] ?? 'unknown',
      // Safely create Driver object if driver data exists
      driver: data['driver'] != null ? Driver.fromMap(data['driver']) : null,
      fare: (data['fare'] as num?)?.toDouble(),
      currentLocation: data['currentLocation'] as GeoPoint?,
      paymentMethod: data['paymentMethod'] ?? 'cash', // Valor por defecto
      paymentStatus: data['paymentStatus'] ?? 'pending', // Valor por defecto
    );
  }

  final String id;
  final String userId;
  final String? driverId; // Nuevo: ID del conductor asignado
  final Driver? driver; // Nulable, ya que no hay conductor al inicio

  // Direcciones legibles
  final String originAddress;
  final String destinationAddress;

  // Coordenadas (opcionales si no están presentes)
  final double? originLat;
  final double? originLng;
  final double? destinationLat;
  final double? destinationLng;

  final Timestamp createdAt;
  final String status; // e.g., 'pending', 'assigned', 'active', 'completed', 'cancelled'
  final double? fare; // Nulable, se puede calcular después
  final String paymentMethod; // 'cash' o 'card'
  final String paymentStatus; // 'pending', 'paid', 'failed'
  final GeoPoint? currentLocation; // Ubicación del conductor, nulable al inicio

  Trip({
    required this.id,
    required this.userId,
    this.driverId,
    this.driver,
    required this.originAddress,
    this.originLat,
    this.originLng,
    required this.destinationAddress,
    this.destinationLat,
    this.destinationLng,
    required this.createdAt,
    required this.status,
    this.fare,
    this.currentLocation,
    this.paymentMethod = 'cash',
    this.paymentStatus = 'pending',
  });

  Trip copyWith({
    String? id,
    String? userId,
    String? driverId,
    Driver? driver,
    String? originAddress,
    double? originLat,
    double? originLng,
    String? destinationAddress,
    double? destinationLat,
    double? destinationLng,
    Timestamp? createdAt,
    String? status,
    double? fare,
    GeoPoint? currentLocation,
    String? paymentMethod,
    String? paymentStatus,
  }) {
    return Trip(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      driverId: driverId ?? this.driverId,
      driver: driver ?? this.driver,
      originAddress: originAddress ?? this.originAddress,
      originLat: originLat ?? this.originLat,
      originLng: originLng ?? this.originLng,
      destinationAddress: destinationAddress ?? this.destinationAddress,
      destinationLat: destinationLat ?? this.destinationLat,
      destinationLng: destinationLng ?? this.destinationLng,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      fare: fare ?? this.fare,
      currentLocation: currentLocation ?? this.currentLocation,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
    );
  }
}
