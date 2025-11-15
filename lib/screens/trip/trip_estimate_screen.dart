import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:taxipro_usuariox/services/functions_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:taxipro_usuariox/screens/trip/driver_assigned_screen.dart';
// import 'package:taxipro_usuariox/widgets/app_drawer.dart'; // Drawer desactivado temporalmente
import 'package:taxipro_usuariox/ui/ui_constants.dart';
import 'package:taxipro_usuariox/widgets/tx_icon.dart';
import 'package:taxipro_usuariox/widgets/app_icons.dart';

class TripEstimateScreen extends StatefulWidget {
  final LatLng origin;
  final LatLng destination;
  final String originAddress;
  final String destinationAddress;
  final double distanceKm;
  final int durationMin;
  final List<LatLng> polylinePoints;
  final double? initialFare;
  final String? initialCurrency;

  const TripEstimateScreen({
    super.key,
    required this.origin,
    required this.destination,
    required this.originAddress,
    required this.destinationAddress,
    required this.distanceKm,
    required this.durationMin,
    required this.polylinePoints,
    this.initialFare,
    this.initialCurrency,
  });

  @override
  State<TripEstimateScreen> createState() => _TripEstimateScreenState();
}

class _TripEstimateScreenState extends State<TripEstimateScreen> {
  final Completer<GoogleMapController> _controller = Completer<GoogleMapController>();
  bool _loading = false;
  double? _estimatedFare;
  String _currency = 'MXN';
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  Timer? _requestGuard;

  @override
  void initState() {
    super.initState();
    // Usar tarifa inicial si viene precalculada
    if (widget.initialFare != null) {
      _estimatedFare = widget.initialFare;
    }
    if (widget.initialCurrency != null && widget.initialCurrency!.isNotEmpty) {
      _currency = widget.initialCurrency!;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _fitCameraToBounds([widget.origin, widget.destination]);
      // Calcular tarifa estimada si el backend lo devuelve vía quote
      if (widget.initialFare == null) {
        try {
          final resp = await CloudFunctionsService.instance.quoteFare(
            estimatedDistanceKm: widget.distanceKm,
            estimatedDurationMin: widget.durationMin,
          );
          if (!mounted) return;
          setState(() {
            _estimatedFare = (resp['totalFare'] as num?)?.toDouble();
            _currency = (resp['currency'] as String?) ?? 'MXN';
          });
        } catch (_) {
          // Silencioso: usar cálculo previo si no hay quote
        }
      }
    });
  }

  Future<void> _fitCameraToBounds(List<LatLng> points) async {
    if (!_controller.isCompleted || points.isEmpty) return;
    final controller = await _controller.future;
    double south = points.first.latitude,
        north = points.first.latitude,
        west = points.first.longitude,
        east = points.first.longitude;
    for (final p in points) {
      south = south < p.latitude ? south : p.latitude;
      north = north > p.latitude ? north : p.latitude;
      west = west < p.longitude ? west : p.longitude;
      east = east > p.longitude ? east : p.longitude;
    }
    final bounds = LatLngBounds(southwest: LatLng(south, west), northeast: LatLng(north, east));
    await controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 60));
  }

  Future<void> _requestTrip() async {
    setState(() => _loading = true);
    _requestGuard?.cancel();
    _requestGuard = Timer(const Duration(seconds: 15), () {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tiempo de espera creando el viaje. Inténtalo de nuevo.')),
      );
    });
    try {
      final resp = await CloudFunctionsService.instance
          .requestTrip(
        originLat: widget.origin.latitude,
        originLng: widget.origin.longitude,
        originAddress: widget.originAddress,
        destLat: widget.destination.latitude,
        destLng: widget.destination.longitude,
        destAddress: widget.destinationAddress,
        estimatedDistanceKm: widget.distanceKm,
        estimatedDurationMin: widget.durationMin,
      )
          .timeout(const Duration(seconds: 12));

      String tripId = '';
      final anyId = resp['tripId'] ?? resp['id'] ?? (resp['trip'] is Map ? resp['trip']['id'] : null);
      if (anyId is String && anyId.isNotEmpty) {
        tripId = anyId;
      }
      if (tripId.isEmpty) {
        final fallback = await _findRecentTripId().timeout(const Duration(seconds: 5), onTimeout: () => null);
        if (fallback != null && fallback.isNotEmpty) {
          tripId = fallback;
        }
      }
      if (tripId.isEmpty) {
        if (mounted) {
          setState(() => _loading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se pudo crear el viaje. Intenta de nuevo.')),
          );
        }
        return;
      }
      if (!mounted) return;
      _requestGuard?.cancel();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => DriverAssignedScreen(
            tripId: tripId,
            origin: widget.origin,
            destination: widget.destination,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error solicitando taxi: $e')),
      );
    }
  }

  Future<String?> _findRecentTripId() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;
      final qs = await FirebaseFirestore.instance
          .collection('trips')
          .where('passengerId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();
      if (qs.docs.isEmpty) return null;
      final d = qs.docs.first;
      final data = d.data();
      final status = (data['status'] as String?) ?? '';
      if (status == 'pending' || status == 'assigned' || status == 'active') {
        return d.id;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final onBg = Theme.of(context).colorScheme.onBackground;
    final double? displayFare = _estimatedFare ?? widget.initialFare;
    final fareText = displayFare != null
        ? '\$${displayFare.toStringAsFixed(2)} $_currency aprox.'
        : '\$${(widget.distanceKm * 15).toStringAsFixed(2)} $_currency aprox.'; // fallback simple

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
              onMapCreated: (c) {
                _controller.complete(c);
                _fitCameraToBounds([widget.origin, widget.destination]);
              },
              zoomControlsEnabled: false,
              myLocationEnabled: false,
              markers: {
                Marker(markerId: const MarkerId('o'), position: widget.origin),
                Marker(markerId: const MarkerId('d'), position: widget.destination),
              },
              polylines: {
                Polyline(
                  polylineId: const PolylineId('route'),
                  points: widget.polylinePoints,
                  width: 6,
                  color: Colors.blue,
                ),
              },
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
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Confirmar viaje', style: TextStyle(color: onBg, fontSize: 22, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Text('${widget.originAddress} → ${widget.destinationAddress}', style: TextStyle(color: onBg.withOpacity(0.9))),
                  const SizedBox(height: 10),
                  Row(children: [
                    TxIcon(AppIcons.clockCar, size: 20, semanticLabel: 'Tiempo'),
                    const SizedBox(width: 8),
                    Text('${widget.durationMin} min aprox.', style: TextStyle(color: onBg.withOpacity(0.9))),
                  ]),
                  const SizedBox(height: 6),
                  Row(children: [
                    TxIcon(AppIcons.destination, size: 20, semanticLabel: 'Destino'),
                    const SizedBox(width: 8),
                    Expanded(child: Text(widget.destinationAddress, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: onBg.withOpacity(0.9)))),
                  ]),
                  const SizedBox(height: 6),
                  Row(children: [
                    TxIcon(AppIcons.route, size: 20, semanticLabel: 'Ruta'),
                    const SizedBox(width: 8),
                    Text('${widget.distanceKm.toStringAsFixed(1)} km', style: TextStyle(color: onBg.withOpacity(0.9))),
                  ]),
                  const SizedBox(height: 10),
                  Text('Tarifa estimada:', style: TextStyle(color: onBg.withOpacity(0.85))),
                  Text(fareText, style: TextStyle(color: onBg, fontWeight: FontWeight.w800, fontSize: 22)),
                  const SizedBox(height: 4),
                  Text('El precio final puede variar ligeramente según condiciones de tráfico.', style: TextStyle(color: onBg.withOpacity(0.75))),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: kButtonHeight,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _requestTrip,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kCornerRadius)),
                      ),
                      child: _loading
                          ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('CONFIRMAR VIAJE'),
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
