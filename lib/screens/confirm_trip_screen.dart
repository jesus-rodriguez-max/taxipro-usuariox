import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:taxipro_usuariox/services/functions_service.dart';

class ConfirmTripScreen extends StatefulWidget {
  final String originAddress;
  final String destinationAddress;
  final double distanceKm;
  final int durationMin;
  final double totalFare;
  final String currency;
  final LatLng origin;
  final LatLng destination;

  const ConfirmTripScreen({
    super.key,
    required this.originAddress,
    required this.destinationAddress,
    required this.distanceKm,
    required this.durationMin,
    required this.totalFare,
    this.currency = 'MXN',
    required this.origin,
    required this.destination,
  });

  @override
  State<ConfirmTripScreen> createState() => _ConfirmTripScreenState();
}

class _ConfirmTripScreenState extends State<ConfirmTripScreen> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirmar viaje'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoRow('Origen', widget.originAddress),
            const SizedBox(height: 8),
            _infoRow('Destino', widget.destinationAddress),
            const Divider(height: 24),
            _infoRow('Distancia', '${widget.distanceKm.toStringAsFixed(2)} km'),
            const SizedBox(height: 8),
            _infoRow('Duración estimada', '${widget.durationMin} min'),
            const SizedBox(height: 8),
            _infoRow('Precio estimado', '\$${widget.totalFare.toStringAsFixed(2)} ${widget.currency}'),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _loading ? null : () => Navigator.of(context).pop(null),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _loading ? null : _confirm,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFFFC107),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _loading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Confirmar viaje'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String title, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 140, child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600))),
        const SizedBox(width: 8),
        Expanded(child: Text(value)),
      ],
    );
  }

  Future<void> _confirm() async {
    setState(() => _loading = true);
    try {
      final resp = await CloudFunctionsService.instance.requestTrip(
        originLat: widget.origin.latitude,
        originLng: widget.origin.longitude,
        originAddress: widget.originAddress,
        destLat: widget.destination.latitude,
        destLng: widget.destination.longitude,
        destAddress: widget.destinationAddress,
        estimatedDistanceKm: widget.distanceKm,
        estimatedDurationMin: widget.durationMin,
      );
      if (!mounted) return;
      Navigator.of(context).pop<Map<String, dynamic>>(resp);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al crear viaje: $e')),
      );
    }
  }
}
