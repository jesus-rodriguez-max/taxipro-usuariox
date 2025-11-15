class Driver {
  final String id;
  final String name;
  final String carModel;
  final String licensePlate;
  final double rating;
  final String photoUrl;

  Driver({
    required this.id,
    required this.name,
    required this.carModel,
    required this.licensePlate,
    required this.rating,
    required this.photoUrl,
  });

  // Factory to create a Driver from a map (e.g., from Firestore)
  factory Driver.fromMap(Map<String, dynamic> map) {
    return Driver(
      id: map['id'] ?? '',
      name: map['name'] ?? 'Nombre no disponible',
      carModel: map['carModel'] ?? 'Modelo no disponible',
      licensePlate: map['licensePlate'] ?? 'Placa no disponible',
      rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
      photoUrl: map['photoUrl'] ?? '',
    );
  }

  // Factory para crear un conductor de ejemplo
  factory Driver.sample() {
    return Driver(
      id: 'sample_driver_456',
      name: 'Javier Gómez',
      carModel: 'Toyota Corolla',
      licensePlate: 'SLP-43-21',
      rating: 4.9,
      photoUrl: 'https://firebasestorage.googleapis.com/v0/b/taxipro-chofer.firebasestorage.app/o/user_photos%2Fconductor_ejemplo.png?alt=media',
    );
  }
}
