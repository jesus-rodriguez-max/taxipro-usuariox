import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:taxipro_usuariox/models/trip_model.dart';
import 'package:taxipro_usuariox/services/emergency_service.dart';
import 'package:url_launcher/url_launcher.dart';
// import 'package:taxipro_usuariox/widgets/app_drawer.dart'; // Drawer desactivado temporalmente
import 'package:taxipro_usuariox/ui/ui_constants.dart';

class TripSafetyScreen extends StatefulWidget {
  final String tripId;
  const TripSafetyScreen({super.key, required this.tripId});

  @override
  State<TripSafetyScreen> createState() => _TripSafetyScreenState();
}

class _TripSafetyScreenState extends State<TripSafetyScreen> {
  final Completer<GoogleMapController> _controller = Completer<GoogleMapController>();
  StreamSubscription<DocumentSnapshot>? _sub;
  Trip? _trip;
  Set<Marker> _markers = {};
  bool _recordAudio = true;
  bool _sharing = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _listenTrip();
  }

  void _listenTrip() {
    _sub?.cancel();
    _sub = FirebaseFirestore.instance.collection('trips').doc(widget.tripId).snapshots().listen((snap) async {
      if (!snap.exists) return;
      final trip = Trip.fromFirestore(snap);
      setState(() {
        _trip = trip;
        _markers = {
          if (trip.originLat != null && trip.originLng != null)
            Marker(markerId: const MarkerId('origin'), position: LatLng(trip.originLat!, trip.originLng!), infoWindow: const InfoWindow(title: 'Origen')),
          if (trip.destinationLat != null && trip.destinationLng != null)
            Marker(markerId: const MarkerId('dest'), position: LatLng(trip.destinationLat!, trip.destinationLng!), infoWindow: const InfoWindow(title: 'Destino')),
          if (trip.currentLocation != null)
            Marker(markerId: const MarkerId('driver'), position: LatLng(trip.currentLocation!.latitude, trip.currentLocation!.longitude), infoWindow: const InfoWindow(title: 'Conductor')),
        };
      });
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _shareTrip() async {
    if (_trip == null) return;
    setState(() => _sharing = true);
    try {
      final t = _trip!;
      final buffer = StringBuffer();
      buffer.writeln('Compartiendo mi viaje en TaxiPro');
      if (t.originAddress.isNotEmpty) buffer.writeln('Origen: ${t.originAddress}');
      if (t.destinationAddress.isNotEmpty) buffer.writeln('Destino: ${t.destinationAddress}');
      if (t.driver?.name != null && t.driver!.name.isNotEmpty) buffer.writeln('Conductor: ${t.driver!.name}');
      if (t.driver?.licensePlate != null && t.driver!.licensePlate.isNotEmpty) buffer.writeln('Placas: ${t.driver!.licensePlate}');
      buffer.writeln('ID de viaje: ${t.id}');
      // Abrir WhatsApp como método simple de compartir (sin dependencia extra)
      // Si el usuario quiere otro canal, podemos extenderlo luego.
      final text = Uri.encodeComponent(buffer.toString());
      final wa = Uri.parse('https://wa.me/?text=$text');
      // ignore: use_build_context_synchronously
      if (!await launchUrl(wa, mode: LaunchMode.externalApplication)) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo abrir WhatsApp')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo compartir el viaje')));
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final onBg = Theme.of(context).colorScheme.onBackground;
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          color: Theme.of(context).colorScheme.onBackground,
          onPressed: () => Navigator.of(context).pushNamed('/map'),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: GoogleMap(
              initialCameraPosition: const CameraPosition(target: LatLng(22.1565, -100.9855), zoom: 13),
              onMapCreated: (c) => _controller.complete(c),
              myLocationEnabled: false,
              zoomControlsEnabled: false,
              markers: _markers,
            ),
          ),
          // Logo superior
          Positioned(
            top: 8,
            left: 0,
            right: 0,
            child: Center(
              child: Image.asset('assets/branding/logo_complete.png', height: 64),
            ),
          ),
          // Panel inferior
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Seguridad', style: TextStyle(color: onBg, fontWeight: FontWeight.w700, fontSize: 18)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text('Grabar audio durante el viaje', style: TextStyle(color: onBg)) ),
                      Switch(
                        value: _recordAudio,
                        onChanged: (v) => setState(() => _recordAudio = v),
                        activeColor: const Color(0xFF22C55E),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: kButtonHeight,
                    child: ElevatedButton(
                      onPressed: _sharing ? null : _shareTrip,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kCornerRadius)),
                      ),
                      child: _sharing
                          ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Compartir mi viaje'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: kButtonHeight,
                    child: ElevatedButton.icon(
                      onPressed: _trip == null ? null : () => EmergencyService.activatePanic(context, activeTrip: _trip),
                      icon: const Icon(Icons.shield, color: Colors.white),
                      label: const Text('Escudo TaxiPro (Emergencia)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD32F2F),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kCornerRadius)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
