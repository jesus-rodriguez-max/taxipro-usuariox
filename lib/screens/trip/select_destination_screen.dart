import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:taxipro_usuariox/services/places_service.dart';
import 'package:taxipro_usuariox/services/directions_service.dart';
import 'package:taxipro_usuariox/services/functions_service.dart';
import 'package:taxipro_usuariox/screens/trip/trip_estimate_screen.dart';
import 'package:taxipro_usuariox/widgets/tx_icon.dart';
import 'package:taxipro_usuariox/widgets/app_icons.dart';
import 'package:taxipro_usuariox/widgets/home_bottom_dock.dart';
import 'package:taxipro_usuariox/utils/debouncer.dart';
import 'package:taxipro_usuariox/widgets/bottom_menu_modal.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:taxipro_usuariox/ui/ui_constants.dart';

class SelectDestinationScreen extends StatefulWidget {
  const SelectDestinationScreen({super.key});

  @override
  State<SelectDestinationScreen> createState() => _SelectDestinationScreenState();
}

class _SelectDestinationScreenState extends State<SelectDestinationScreen> {
  final Completer<GoogleMapController> _controller = Completer<GoogleMapController>();
  static const LatLng _slpCenter = LatLng(22.1565, -100.9855);
  static const CameraPosition _initialCamera = CameraPosition(target: _slpCenter, zoom: 14);

  final TextEditingController _originCtrl = TextEditingController(text: 'Mi ubicación actual');
  final TextEditingController _destCtrl = TextEditingController();
  final PlacesService _places = PlacesService();
  final DirectionsService _directions = DirectionsService();
  final _debouncer = Debouncer(milliseconds: 500);

  LatLng? _currentPosition;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  List<PlaceSuggestion> _suggestions = [];
  bool _finding = false;
  bool _canConfirm = false;
  bool _overlayActive = true;
  final FocusNode _destFocus = FocusNode();
  final FocusNode _originFocus = FocusNode();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _menuOpen = false;
  String? _selectedDestPlaceId;
  String? _selectedOriginPlaceId;
  LatLng? _customOrigin;

  void _resetInput() {
    setState(() {
      _destCtrl.clear();
      _originCtrl.text = 'Mi ubicación actual';
      _selectedDestPlaceId = null;
      _selectedOriginPlaceId = null;
      _customOrigin = null;
      _suggestions = [];
      _canConfirm = false;
      _polylines.clear();
      _markers = {
        if (_currentPosition != null)
          Marker(
            markerId: const MarkerId('me'),
            position: _currentPosition!,
            infoWindow: const InfoWindow(title: 'Mi ubicación'),
          ),
      };
    });
  }

  @override
  void initState() {
    super.initState();
    _initLocation();
    _destFocus.addListener(() {
      if (mounted) setState(() {});
    });
    _originFocus.addListener(() {
      if (mounted) setState(() {});
    });
  }

  Future<void> _initLocation() async {
    try {
      var status = await Permission.locationWhenInUse.status;
      if (status.isDenied) status = await Permission.locationWhenInUse.request();
      if (!status.isGranted) return;
      Position? pos;
      try {
        pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 6),
        );
      } catch (_) {
        pos = await Geolocator.getLastKnownPosition();
      }
      if (pos == null) return;
      final here = LatLng(pos.latitude, pos.longitude);
      _currentPosition = here;
      _markers = {
        Marker(markerId: const MarkerId('me'), position: here, infoWindow: const InfoWindow(title: 'Mi ubicación'))
      };
      if (mounted) setState(() {});
      if (_controller.isCompleted) {
        final c = await _controller.future;
        c.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(target: here, zoom: 15)));
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _originCtrl.dispose();
    _destCtrl.dispose();
    _debouncer.dispose();
    _destFocus.dispose();
    _originFocus.dispose();
    super.dispose();
  }

  Future<void> _onConfirm() async {
    FocusScope.of(context).unfocus();
    final destText = _destCtrl.text.trim();
    if (destText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Introduce destino')));
      return;
    }
    setState(() => _finding = true);
    try {
      LatLng? origin = _customOrigin;
      String originAddress = _originCtrl.text.trim();
      if (origin == null) {
        if ((_selectedOriginPlaceId != null) && _selectedOriginPlaceId!.isNotEmpty) {
          origin = await _places.geocodePlaceId(_selectedOriginPlaceId!);
        } else if (originAddress.isNotEmpty && originAddress.toLowerCase() != 'mi ubicación actual') {
          origin = await _places.geocodeAddress(originAddress, locationBias: _currentPosition ?? _slpCenter, radius: 10000);
        } else {
          originAddress = 'Mi ubicación actual';
        }
      }
      origin ??= _currentPosition ?? _slpCenter;

      final originFinal = origin;

      LatLng? dest;
      if ((_selectedDestPlaceId != null) && _selectedDestPlaceId!.isNotEmpty) {
        dest = await _places.geocodePlaceId(_selectedDestPlaceId!);
      }
      dest ??= await _places.geocodeAddress(destText, locationBias: originFinal, radius: 10000);
      if (dest == null) {
        if (mounted) setState(() => _finding = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo geocodificar el destino')));
        return;
      }
      final LatLng destFinal = dest;

      final dir = await _directions.getRoute(origin: originFinal, destination: dest);
      if (dir == null || dir.polylinePoints.isEmpty) {
        if (mounted) setState(() => _finding = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo calcular la ruta')));
        return;
      }

      if (!mounted) return;
      setState(() {
        _polylines = {
          Polyline(polylineId: const PolylineId('route'), color: Colors.blue, width: 6, points: dir.polylinePoints),
        };
        _markers = {
          Marker(markerId: const MarkerId('origin'), position: originFinal, infoWindow: const InfoWindow(title: 'Origen')),
          Marker(markerId: const MarkerId('dest'), position: destFinal, infoWindow: const InfoWindow(title: 'Destino')),
        };
      });

      double? initialFare;
      String? initialCurrency;
      try {
        final quote = await CloudFunctionsService.instance.quoteFare(
          estimatedDistanceKm: dir.distanceKm,
          estimatedDurationMin: dir.durationMin,
        );
        initialFare = (quote['totalFare'] as num?)?.toDouble();
        initialCurrency = (quote['currency'] as String?) ?? 'MXN';
      } catch (_) {}

      final result = await Navigator.of(context).push(PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (_, __, ___) => TripEstimateScreen(
          origin: originFinal,
          destination: destFinal,
          originAddress: originAddress.isEmpty ? dir.startAddress : originAddress,
          destinationAddress: destText.isEmpty ? dir.endAddress : destText,
          distanceKm: dir.distanceKm,
          durationMin: dir.durationMin,
          polylinePoints: dir.polylinePoints,
          initialFare: initialFare,
          initialCurrency: initialCurrency,
        ),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(opacity: animation, child: child),
      ));

      if (!mounted) return;
      if (result == null || (result is Map && (result['canceled'] == true))) {
        _resetInput();
        setState(() => _overlayActive = true);
        await Future.delayed(const Duration(milliseconds: 50));
        if (mounted) _destFocus.requestFocus();
      }
    } finally {
      if (mounted) setState(() => _finding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final mapGesturesEnabled = !_overlayActive || !_destFocus.hasFocus;
    final viewInsets = MediaQuery.viewInsetsOf(context).bottom;
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    const double dockHeight = 76;
    final bool kbOpen = viewInsets > 0;

    return Scaffold(
      key: _scaffoldKey,
      extendBody: true,
      resizeToAvoidBottomInset: false,
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Stack(
        children: [
          Positioned.fill(
            child: GoogleMap(
              initialCameraPosition: _initialCamera,
              myLocationEnabled: false,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              scrollGesturesEnabled: mapGesturesEnabled,
              zoomGesturesEnabled: mapGesturesEnabled,
              rotateGesturesEnabled: mapGesturesEnabled,
              tiltGesturesEnabled: mapGesturesEnabled,
              markers: _markers,
              polylines: _polylines,
              onMapCreated: (c) => _controller.complete(c),
              onLongPress: (p) {
                setState(() {
                  _customOrigin = p;
                  _selectedOriginPlaceId = null;
                  _originCtrl.text = 'Punto en mapa';
                  _markers = {
                    ..._markers,
                    Marker(markerId: const MarkerId('pickup_custom'), position: p, infoWindow: const InfoWindow(title: 'Punto de recogida')),
                  };
                });
              },
            ),
          ),
          Positioned(
            top: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Image.asset('assets/branding/logo_complete.png', height: 120, filterQuality: FilterQuality.high),
            ),
          ),
          if (_overlayActive)
            Align(
              alignment: Alignment.bottomCenter,
              child: Material(
                color: Colors.black.withOpacity(0.85),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: Padding(
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 8,
                    top: 12,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Barra superior
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '¿A dónde vamos?',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () {
                              FocusScope.of(context).unfocus();
                              setState(() => _overlayActive = false);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Campo de destino
                      TextField(
                        controller: _destCtrl,
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: 'Introduce destino...',
                          prefixIcon: const Icon(Icons.search, color: Colors.white70),
                          filled: true,
                          fillColor: Colors.white10,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          hintStyle: const TextStyle(color: Colors.white70),
                        ),
                        style: const TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      // Botón ubicación actual
                      TextButton.icon(
                        onPressed: () {
                          FocusScope.of(context).unfocus();
                          _originCtrl.text = 'Mi ubicación actual';
                        },
                        icon: const Icon(Icons.location_on, color: Colors.white70),
                        label: const Text(
                          'Usar mi ubicación actual',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (_overlayActive && _destFocus.hasFocus)
            Positioned.fill(
              child: IgnorePointer(
                ignoring: false,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  color: Colors.black.withOpacity(0.35),
                ),
              ),
            ),
          if (!_overlayActive)
            Positioned(
              bottom: safeBottom + dockHeight + 20,
              left: 0,
              right: 0,
              child: Center(
                child: FloatingActionButton.extended(
                  backgroundColor: const Color(0xFF246BFD),
                  foregroundColor: Colors.white,
                  onPressed: () {
                    setState(() {
                      _overlayActive = true;
                    });
                    _destFocus.requestFocus();
                  },
                  icon: const Icon(Icons.search),
                  label: const Text('¿A dónde vamos?'),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: kbOpen
          ? null
          : HomeBottomDock(
              onOpenMenu: () => BottomMenuModal.show(context),
              onOpenWallet: () => Navigator.of(context).pushNamed('/wallet'),
              onOpenShield: () => Navigator.of(context).pushNamed('/safety/shield'),
            ),
    );
  }
}
