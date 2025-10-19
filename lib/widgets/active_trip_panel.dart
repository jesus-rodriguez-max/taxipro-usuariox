import 'package:flutter/material.dart';
  import 'package:taxipro_usuariox/models/trip_model.dart';
  import 'package:flutter/services.dart';

  class ActiveTripPanel extends StatelessWidget {
    final Trip trip;

    const ActiveTripPanel({super.key, required this.trip});

  void _showPanicDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmación de Pánico'),
          content: const Text('¿Estás seguro de que deseas activar la alerta de pánico? Esta acción no se puede deshacer.'),
          actions: [
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('ACTIVAR', style: TextStyle(color: Colors.red)),
              onPressed: () {
                // TODO: Enviar alerta a los servicios de emergencia y contactos de confianza
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Alerta de pánico activada. Se ha notificado a los servicios de emergencia.')),
                );
              },
            ),
          ],
        );
      },
    );
  }

  // Comparte los detalles del viaje
  void _shareTripDetails(BuildContext context) {
    // En el futuro, esta URL apuntará a una página web real con un mapa.
    final trackingUrl = 'https://track.taxipro.app/trip/${trip.id}';
    final shareText = 
      'Sigue mi viaje de Taxipro en tiempo real:\n'
      '$trackingUrl\n\n'
      'Conductor: ${trip.driver?.name ?? 'Cargando...'}\n' 
      'Vehículo: ${trip.driver?.carModel ?? ''} - ${trip.driver?.licensePlate ?? ''}';
    Clipboard.setData(const ClipboardData(text: ''));
    Clipboard.setData(ClipboardData(text: shareText));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Enlace copiado al portapapeles')),
    );
  }

  
  @override
  Widget build(BuildContext context) {
    // Si el pago es con tarjeta y aún no está pagado, mostrar un mensaje de espera.
    if (trip.paymentMethod == 'card' && trip.paymentStatus != 'paid') {
      return Positioned(
        bottom: 0,
        left: 0,
        right: 0,
        child: Container(
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: Colors.amber.shade50,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(color: Colors.amber.shade200, width: 2),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Esperando confirmación del pago...',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                'Tu viaje comenzará en cuanto el pago con tarjeta sea procesado.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
            ],
          ),
        ),
      );
    }

    // Si el pago es en efectivo o ya está pagado, mostrar el panel normal.
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Theme.of(context).canvasColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Información del conductor
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: (trip.driver?.photoUrl != null && trip.driver!.photoUrl.isNotEmpty)
                      ? NetworkImage(trip.driver!.photoUrl)
                      : null,
                  child: (trip.driver?.photoUrl == null || trip.driver!.photoUrl.isEmpty)
                      ? const Icon(Icons.person, size: 30)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(trip.driver?.name ?? 'Cargando...', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      const SizedBox(height: 4),
                      Text('${trip.driver?.carModel ?? 'Vehículo'} - ${trip.driver?.licensePlate ?? '...'}', style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Icon(Icons.star, color: const Color(0xFFC0C0C0)),
                    Text(trip.driver?.rating.toStringAsFixed(1) ?? '-'),
                  ],
                )
              ],
            ),
            const Divider(height: 24),
            // Botones de acción
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Botón de Pánico
                ElevatedButton.icon(
                  onPressed: () => _showPanicDialog(context),
                  icon: const Icon(Icons.warning, color: Colors.white),
                  label: const Text('Pánico'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                // Botón de Compartir Viaje
                TextButton.icon(
                  onPressed: () => _shareTripDetails(context),
                  icon: Icon(Icons.share, color: Theme.of(context).colorScheme.primary),
                  label: Text('Compartir Viaje', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
