import 'dart:convert';
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:taxipro_usuariox/services/places_service.dart';
import 'package:taxipro_usuariox/services/directions_service.dart';
import 'package:taxipro_usuariox/services/functions_service.dart';
import 'package:taxipro_usuariox/screens/confirm_trip_screen.dart';
import 'package:taxipro_usuariox/utils/debouncer.dart';
import 'package:taxipro_usuariox/screens/wallet_screen.dart';
import 'package:taxipro_usuariox/screens/trip_history_screen.dart';
import 'package:taxipro_usuariox/screens/faq_screen.dart';
import 'package:taxipro_usuariox/screens/support_screen.dart';
import 'package:taxipro_usuariox/screens/seguridad/escudo_taxipro.dart';
import 'package:taxipro_usuariox/screens/offline/sms_request_screen.dart';
import 'package:taxipro_usuariox/screens/profile_screen.dart';
import 'package:taxipro_usuariox/models/trip_model.dart';
import 'package:taxipro_usuariox/widgets/active_trip_panel.dart';
import 'package:taxipro_usuariox/widgets/trip_rating_dialog.dart';
import 'package:taxipro_usuariox/models/driver_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:taxipro_usuariox/widgets/payment_method_selector.dart';
import 'package:taxipro_usuariox/screens/payment_webview.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;
import 'package:http/http.dart' as http;
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:taxipro_usuariox/services/config_service.dart';
// import 'package:taxipro_usuariox/widgets/app_drawer.dart'; // Drawer desactivado temporalmente
// import 'package:taxipro_usuariox/services/app_config_service.dart'; // Flags locales no requeridos para mostrar el carrusel
import 'package:taxipro_usuariox/widgets/home_bottom_dock.dart';
import 'package:taxipro_usuariox/widgets/bottom_menu_modal.dart';

class HomeMapScreen extends StatefulWidget {
  const HomeMapScreen({super.key});

  @override
  State<HomeMapScreen> createState() => _HomeMapScreenState();
}

class _HomeMapScreenState extends State<HomeMapScreen> {
  final Completer<GoogleMapController> _controller = Completer<GoogleMapController>();

  static const CameraPosition _defaultPosition = CameraPosition(
    target: LatLng(22.1565, -100.9855),
    zoom: 15.0,
  );

  LatLng? _currentPosition;
  bool _isLoading = true;
  bool _locationPermissionDenied = true;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  final _placesService = PlacesService();
  final _directions = DirectionsService();
  final _debouncer = Debouncer(milliseconds: 500);
  List<PlaceSuggestion> _placeSuggestions = [];
  bool _isSearching = false;
  bool _isTripActive = false;
  Trip? _activeTrip;
  String? _tripRequestStatus;
  StreamSubscription<DocumentSnapshot>? _tripSubscription;
  bool _hasShownRatingDialog = false;
  String _selectedPaymentMethod = 'cash';
  bool _checkoutInProgress = false;
  bool _mapCreated = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _bottomSheetOpen = false;
  bool _menuOpen = false;

  final TextEditingController _originController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  String? _selectedPlaceId;

  // Eliminado modal de bienvenida

  @override
  void initState() {
    super.initState();
    _markers = {
      const Marker(
        markerId: MarkerId('default'),
        position: LatLng(22.1565, -100.9855),
        infoWindow: InfoWindow(title: 'Inicio'),
      ),
    };
    _checkAndRequestLocationPermission();
  }

  // --- INICIO FUNCIONES DE PERMISO Y UBICACIÓN ---
  Future<void> _checkAndRequestLocationPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _locationPermissionDenied = true;
        _isLoading = false;
      });
      return;
    }

    var status = await Permission.locationWhenInUse.status;
    if (status.isDenied) status = await Permission.locationWhenInUse.request();

    if (status.isGranted) {
      setState(() {
        _locationPermissionDenied = false;
      });
      _getCurrentLocation();
    } else {
      setState(() {
        _locationPermissionDenied = true;
        _isLoading = false;
      });
      if (status.isPermanentlyDenied) _showOpenSettingsDialog();
    }
  }

  void _showOpenSettingsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Permisos de ubicación requeridos'),
        content: const Text(
          'Para mejorar tu experiencia, necesitamos acceder a tu ubicación. '
          'Por favor, habilita los permisos en la configuración.'
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Abrir Configuración'),
          ),
        ],
      ),
    );
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _locationPermissionDenied = true;
          _isLoading = false;
        });
        return;
      }

      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 6),
        );
      } catch (_) {
        // Ignorar y usar último conocido o fallback
      }

      LatLng currentLatLng;
      if (position != null) {
        currentLatLng = LatLng(position.latitude, position.longitude);
      } else {
        final last = await Geolocator.getLastKnownPosition().catchError((_) => null);
        if (last != null) {
          currentLatLng = LatLng(last.latitude, last.longitude);
        } else {
          // Fallback SLP centro
          currentLatLng = const LatLng(22.1565, -100.9855);
        }
      }

      if (!mounted) return;
      setState(() {
        _currentPosition = currentLatLng;
        _markers = {
          Marker(
            markerId: const MarkerId('currentLocation'),
            position: currentLatLng,
            infoWindow: const InfoWindow(title: 'Mi ubicación actual'),
          ),
        };
        _isLoading = false;
      });

      _goToCurrentLocation();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _goToCurrentLocation() async {
    if (_currentPosition == null) return;
    if (!_controller.isCompleted) return; // Esperar a que el mapa esté listo
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(
      CameraUpdate.newCameraPosition(CameraPosition(target: _currentPosition!, zoom: 15.0)),
    );
  }
  // --- FIN FUNCIONES DE UBICACIÓN ---

  void _showWhereToBottomSheet() {
    if (_originController.text.isEmpty) {
      _originController.text = 'Mi ubicación actual';
    }
    _bottomSheetOpen = true;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.95,
              minChildSize: 0.6,
              maxChildSize: 0.98,
              builder: (_, controller) {
                final bottomInset = MediaQuery.of(context).viewInsets.bottom;
                return AnimatedPadding(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.only(bottom: bottomInset),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).canvasColor,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    child: ListView(
                      controller: controller,
                      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                      children: [
                        TextField(
                          controller: _destinationController,
                          autofocus: true,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _onRequestTaxi(),
                          onChanged: (text) {
                            // No limpiar el placeId seleccionado; permitir que el usuario edite sin perder la selección
                            final bias = _currentPosition ?? const LatLng(22.1333, -100.9333);
                            _debouncer.run(() async {
                              try {
                                setState(() => _isSearching = true);
                                final suggestions = await _placesService.getAutocomplete(
                                  text,
                                  locationBias: bias,
                                  radius: 10000,
                                );
                                setState(() {
                                  _placeSuggestions = suggestions;
                                  _isSearching = false;
                                });
                              } catch (_) {
                                if (!mounted) return;
                                setState(() {
                                  _placeSuggestions = [];
                                  _isSearching = false;
                                });
                              }
                            });
                          },
                          scrollPadding: EdgeInsets.only(bottom: bottomInset + 120),
                          decoration: InputDecoration(
                            hintText: '¿A dónde vamos?',
                            prefixIcon: const Icon(Icons.search),
                            filled: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (_placeSuggestions.isNotEmpty)
                          ..._placeSuggestions.take(6).map((s) => ListTile(
                                leading: const Icon(Icons.place_outlined),
                                dense: true,
                                title: Text(s.description, maxLines: 2, overflow: TextOverflow.ellipsis),
                                onTap: () async {
                                  _selectedPlaceId = s.placeId;
                                  _destinationController.text = s.description;
                                  setState(() => _placeSuggestions = []);
                                  FocusScope.of(context).unfocus();
                                },
                              )),
                        if (_isSearching) const LinearProgressIndicator(minHeight: 2),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _onRequestTaxi,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                          child: const Text('PEDIR TAXI'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    ).whenComplete(() {
      if (mounted) setState(() => _bottomSheetOpen = false);
    });
  }

  // Eliminado modal de bienvenida

  // --- RESTO DE FUNCIONES ORIGINALES (sin cambios) ---
  // Mantén aquí todas las funciones de viajes, firestore, stripe, etc.
  // No hay conflicto con el cambio del diálogo.

  Future<void> _onRequestTaxi() async {
    try {
      // Validar sesión: la función requestTrip requiere usuario autenticado
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Inicia sesión para solicitar un taxi')),
        );
        return;
      }
      final destText = _destinationController.text.trim();
      if (destText.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ingresa un destino para continuar')),
        );
        return;
      }

      setState(() => _isLoading = true);

      // Origin: usar ubicación actual si no se especifica otra cosa
      LatLng? origin = _currentPosition;
      final LatLng bias = _currentPosition ?? const LatLng(22.1333, -100.9333);
      String originAddress = _originController.text.trim();
      if (originAddress.isEmpty || originAddress.toLowerCase() == 'mi ubicación actual') {
        originAddress = 'Mi ubicación actual';
      } else {
        try {
          final o = await _placesService.geocodeAddress(originAddress, locationBias: bias, radius: 10000);
          if (o != null) origin = o;
        } on FirebaseFunctionsException catch (e) {
          if (!mounted) return;
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error de geocodificación (origen): ${e.message ?? e.code}')),
          );
          return;
        }
      }

      // Destination
      LatLng? dest;
      try {
        if (_selectedPlaceId != null && _selectedPlaceId!.isNotEmpty) {
          dest = await _placesService.geocodePlaceId(_selectedPlaceId!);
          // Fallback: si por alguna razón el placeId no resolvió, intentar por texto
          if (dest == null) {
            dest = await _placesService.geocodeAddress(destText, locationBias: bias, radius: 10000);
          }
        } else {
          dest = await _placesService.geocodeAddress(destText, locationBias: bias, radius: 10000);
        }
      } on FirebaseFunctionsException catch (e) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error de geocodificación (destino): ${e.message ?? e.code}')),
        );
        return;
      }
      // Fallback robusto: si no tenemos origen aún, usa centro de SLP
      if (origin == null) {
        origin = _currentPosition ?? const LatLng(22.1565, -100.9855);
      }
      if (dest == null) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo geocodificar el destino')),
        );
        return;
      }

      // Directions
      final dir = await _directions.getRoute(origin: origin, destination: dest);
      if (dir == null || dir.polylinePoints.isEmpty) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo calcular la ruta')),
        );
        return;
      }

      // Dibujar ruta + marcadores
      final routePolyline = Polyline(
        polylineId: const PolylineId('route'),
        color: Colors.blue,
        width: 6,
        points: dir.polylinePoints,
      );
      setState(() {
        _polylines = {routePolyline};
        _markers = {
          Marker(markerId: const MarkerId('origin'), position: origin!, infoWindow: const InfoWindow(title: 'Origen')),
          Marker(markerId: const MarkerId('destination'), position: dest!, infoWindow: const InfoWindow(title: 'Destino')),
        };
      });

      // Cotizar tarifa sin crear viaje y mostrar pantalla de confirmación
      try {
        final quote = await CloudFunctionsService.instance.quoteFare(
          estimatedDistanceKm: dir.distanceKm,
          estimatedDurationMin: dir.durationMin,
        );
        final total = (quote['totalFare'] as num?)?.toDouble() ?? 0.0;
        final currency = (quote['currency'] as String?) ?? 'MXN';
        if (mounted) setState(() => _isLoading = false);

        final resp = await Navigator.of(context).push<Map<String, dynamic>>(
          MaterialPageRoute(
            builder: (_) => ConfirmTripScreen(
              originAddress: originAddress,
              destinationAddress: destText,
              distanceKm: dir.distanceKm,
              durationMin: dir.durationMin,
              totalFare: total,
              currency: currency,
              origin: origin!,
              destination: dest!,
            ),
          ),
        );

        if (resp == null) {
          // Usuario canceló
          return;
        }

        final tripId = (resp['tripId'] as String?) ?? '';
        if (tripId.isEmpty) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se creó el viaje. Intenta de nuevo.')),
          );
          return;
        }

        // Ajustar cámara a la ruta (no bloquear si falla por tamaño o timing)
        try {
          await _fitCameraToBounds([origin!, dest!]);
        } catch (_) {}

        _tripSubscription?.cancel();
        _tripSubscription = FirebaseFirestore.instance
            .collection('trips')
            .doc(tripId)
            .snapshots()
            .listen((snap) {
          if (!snap.exists) return;
          final trip = Trip.fromFirestore(snap);
          setState(() {
            _activeTrip = trip;
            _isTripActive = true;
            _tripRequestStatus = trip.status;
            _isLoading = false;
          });
          // Mostrar calificación al completar el viaje
          if (trip.status == 'completed' && !_hasShownRatingDialog) {
            _hasShownRatingDialog = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              showDialog(
                context: context,
                barrierDismissible: true,
                builder: (_) => TripRatingDialog(
                  driverName: trip.driver?.name ?? 'Tu conductor',
                  onSubmit: (rating, comment) async {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('¡Gracias por tu calificación!')));
                    setState(() {
                      _isTripActive = false;
                      _activeTrip = null;
                      _polylines.clear();
                      _markers.clear();
                      if (_currentPosition != null) {
                        _markers.add(Marker(
                          markerId: const MarkerId('currentLocation'),
                          position: _currentPosition!,
                          infoWindow: const InfoWindow(title: 'Mi ubicación actual'),
                        ));
                      }
                    });
                  },
                ),
              ).whenComplete(() {
                if (!mounted) return;
                setState(() {
                  _isTripActive = false;
                });
              });
            });
          }
        }, onError: (_) {
          if (!mounted) return;
          setState(() => _isLoading = false);
        });
      } on FirebaseFunctionsException catch (e) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo cotizar: ${e.message ?? e.code}')),
        );
        return;
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ocurrió un error al solicitar el taxi: $e')),
      );
    }
  }

  Future<void> _fitCameraToBounds(List<LatLng> points) async {
    if (points.isEmpty) return;
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

  @override
  void dispose() {
    _debouncer.dispose();
    _tripSubscription?.cancel();
    _originController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Nueva lógica para manejo del teclado y dock
    final viewInsets = MediaQuery.viewInsetsOf(context).bottom;
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    const double dockHeight = 76; // altura real del HomeBottomDock
    final bool kbOpen = viewInsets > 0;
    
    return WillPopScope(
      onWillPop: _handleWillPop,
      child: Scaffold(
      key: _scaffoldKey,
      extendBody: true,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: GoogleMap(
              mapType: MapType.normal,
              initialCameraPosition: _defaultPosition,
              markers: _markers,
              myLocationEnabled: !_locationPermissionDenied,
              myLocationButtonEnabled: !_locationPermissionDenied,
              zoomControlsEnabled: false,
              onMapCreated: (GoogleMapController controller) {
                _controller.complete(controller);
                if (mounted) {
                  setState(() {
                    _mapCreated = true;
                    if (!_locationPermissionDenied) {
                      // Si ya tenemos el mapa listo, no bloquear innecesariamente la UI
                      _isLoading = false;
                    }
                  });
                }
                // Intentar centrar cámara si ya tenemos ubicación
                if (_currentPosition != null) {
                  _goToCurrentLocation();
                }
              },
              polylines: _polylines,
            ),
          ),
          // Evitar mostrar spinner visible entre el splash y la pantalla principal
          if (_isLoading)
            const SizedBox.shrink(),
          // Logo flotante en la parte superior
          Positioned(
            top: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Image.asset('assets/branding/logo_complete.png', height: 120, filterQuality: FilterQuality.high),
            ),
          ),
          if (_isTripActive && _activeTrip != null)
            ActiveTripPanel(trip: _activeTrip!),
        ],
      ),
      // Oculta el dock si el teclado está abierto
      bottomNavigationBar: kbOpen
          ? null
          : HomeBottomDock(
              onOpenMenu: () => BottomMenuModal.show(context),
              onOpenWallet: () => Navigator.of(context).pushNamed('/wallet'),
              onOpenShield: () => Navigator.of(context).pushNamed('/safety/shield'),
            ),
    ),
    );
  }

  Widget _buildMainButton() { return const SizedBox.shrink(); }

  Future<bool> _handleWillPop() async {
    // Cerrar Drawer si está abierto
    if (_scaffoldKey.currentState?.isDrawerOpen == true) {
      Navigator.of(context).pop();
      return false;
    }
    // Cerrar carrusel si está abierto
    if (_menuOpen) {
      setState(() => _menuOpen = false);
      return false;
    }
    // Cerrar bottom sheet si está abierto
    if (_bottomSheetOpen) {
      Navigator.of(context).pop();
      return false;
    }
    // Si hay ruta trazada, limpiar en lugar de salir
    if (_polylines.isNotEmpty) {
      setState(() {
        _polylines.clear();
        _markers.clear();
        if (_currentPosition != null) {
          _markers.add(Marker(
            markerId: const MarkerId('currentLocation'),
            position: _currentPosition!,
            infoWindow: const InfoWindow(title: 'Mi ubicación actual'),
          ));
        }
      });
      return false;
    }
    return true;
  }

  void _onSelectMenuKey(String key) async {
    switch (key) {
      case 'map':
        if (!mounted) return;
        Navigator.of(context).pushNamedAndRemoveUntil('/map', (route) => false);
        break;
      case 'illustr':
        Navigator.of(context).pushNamed('/info/illustrations');
        break;
      case 'wallet':
        Navigator.of(context).pushNamed('/wallet');
        break;
      case 'faq':
        Navigator.of(context).pushNamed('/faq');
        break;
      case 'support':
        Navigator.of(context).pushNamed('/support');
        break;
      case 'shield':
        Navigator.of(context).pushNamed('/safety/shield');
        break;
      case 'offline':
        Navigator.of(context).pushNamed('/offline/request');
        break;
      case 'profile':
        Navigator.of(context).pushNamed('/profile/edit');
        break;
      case 'legal':
        Navigator.of(context).pushNamed('/legal');
        break;
      case 'settings':
        Navigator.of(context).pushNamed('/settings');
        break;
      case 'logout':
        await FirebaseAuth.instance.signOut();
        if (!mounted) return;
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
        break;
    }
  }
}

