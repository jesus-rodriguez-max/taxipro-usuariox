import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:taxipro_usuariox/models/trip_model.dart';
import 'package:taxipro_usuariox/models/driver_model.dart';
import 'package:taxipro_usuariox/services/directions_service.dart';
import 'package:taxipro_usuariox/services/functions_service.dart';
import 'package:taxipro_usuariox/screens/trip/trip_safety_screen.dart';
// import 'package:taxipro_usuariox/widgets/app_drawer.dart'; // Drawer desactivado temporalmente
import 'package:taxipro_usuariox/ui/ui_constants.dart';

class DriverAssignedScreen extends StatefulWidget {
  final String tripId;
  final LatLng origin;
  final LatLng destination;

  const DriverAssignedScreen({super.key, required this.tripId, required this.origin, required this.destination});

  @override
  State<DriverAssignedScreen> createState() => _DriverAssignedScreenState();
}

class _DriverAssignedScreenState extends State<DriverAssignedScreen> {
  final Completer<GoogleMapController> _controller = Completer<GoogleMapController>();
  final DirectionsService _directions = DirectionsService();
  StreamSubscription<DocumentSnapshot>? _sub;
  Trip? _trip;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  bool _cancelling = false;
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
      final t = Trip.fromFirestore(snap);
      _trip = t;
      // Map markers: driver current and passenger origin/destination
      final markers = <Marker>{
        Marker(markerId: const MarkerId('origin'), position: widget.origin, infoWindow: const InfoWindow(title: 'Origen')),
        Marker(markerId: const MarkerId('dest'), position: widget.destination, infoWindow: const InfoWindow(title: 'Destino')),
      };
      if (t.currentLocation != null) {
        final dPos = LatLng(t.currentLocation!.latitude, t.currentLocation!.longitude);
        markers.add(Marker(markerId: const MarkerId('driver'), position: dPos, infoWindow: const InfoWindow(title: 'Conductor')));
        // Route from driver to origin (ETA)
        final dir = await _directions.getRoute(origin: dPos, destination: widget.origin);
        if (dir != null && dir.polylinePoints.isNotEmpty) {
          _polylines = {
            Polyline(polylineId: const PolylineId('driverRoute'), color: Colors.blue, width: 6, points: dir.polylinePoints)
          };
        }
      }
      setState(() {
        _markers = markers;
      });

      // Navigate to safety when trip becomes active
      if (t.status == 'active' && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => TripSafetyScreen(tripId: widget.tripId)),
        );
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _cancelTrip() async {
    setState(() => _cancelling = true);
    try {
      await CloudFunctionsService.instance.callMap('cancelTripCallable', {'tripId': widget.tripId});
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Viaje cancelado')));
    } catch (e) {
      if (!mounted) return;
      setState(() => _cancelling = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No se pudo cancelar: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final onBg = Theme.of(context).colorScheme.onBackground;
    final driver = _trip?.driver ?? Driver.sample();

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          color: onBg,
          onPressed: () => Navigator.of(context).pushNamed('/map'),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(target: widget.origin, zoom: 14),
              markers: _markers,
              polylines: _polylines,
              zoomControlsEnabled: false,
              myLocationEnabled: false,
              onMapCreated: (c) => _controller.complete(c),
            ),
          ),
          // Top overlay title
          Positioned(
            top: 8,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'Tu taxi está por llegar',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onBackground,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
          ),
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
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(radius: 34, backgroundImage: driver.photoUrl.isNotEmpty ? NetworkImage(driver.photoUrl) : null, child: driver.photoUrl.isEmpty ? const Icon(Icons.person, size: 32) : null),
                  const SizedBox(height: 8),
                  Text(driver.name, style: TextStyle(color: onBg, fontWeight: FontWeight.w700, fontSize: 18)),
                  const SizedBox(height: 4),
                  Text('Taxi ${driver.carModel} • Placas: ${driver.licensePlate}', style: TextStyle(color: onBg.withOpacity(0.85))),
                  const SizedBox(height: 4),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.star, color: Colors.amber, size: 18),
                    const SizedBox(width: 4),
                    Text(driver.rating.toStringAsFixed(1), style: TextStyle(color: onBg, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 8),
                    Text(_trip?.status == 'assigned' ? 'Llega pronto' : (_trip?.status ?? 'pendiente'), style: TextStyle(color: onBg.withOpacity(0.8))),
                  ]),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: kButtonHeight,
                    child: ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Contactando al chofer…')));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kCornerRadius)),
                      ),
                      child: const Text('Contactar chofer'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: kButtonHeight,
                    child: ElevatedButton(
                      onPressed: _cancelling ? null : _cancelTrip,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD32F2F),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kCornerRadius)),
                      ),
                      child: _cancelling
                          ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Cancelar viaje'),
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
