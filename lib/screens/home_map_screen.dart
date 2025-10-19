import 'dart:convert';
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:taxipro_usuariox/services/places_service.dart';
import 'package:taxipro_usuariox/utils/debouncer.dart';
import 'package:taxipro_usuariox/screens/wallet_screen.dart';
import 'package:taxipro_usuariox/screens/trip_history_screen.dart';
import 'package:taxipro_usuariox/screens/faq_screen.dart';
import 'package:taxipro_usuariox/screens/support_screen.dart';
import 'package:taxipro_usuariox/screens/seguridad/escudo_taxipro.dart';
import 'package:taxipro_usuariox/screens/offline/sms_request_screen.dart';
import 'package:taxipro_usuariox/models/trip_model.dart';
import 'package:taxipro_usuariox/widgets/active_trip_panel.dart';
import 'package:taxipro_usuariox/widgets/trip_rating_dialog.dart';
import 'package:taxipro_usuariox/models/driver_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:taxipro_usuariox/widgets/payment_method_selector.dart';
import 'package:taxipro_usuariox/services/stripe_checkout_service.dart';
import 'package:taxipro_usuariox/screens/payment_webview.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;

class HomeMapScreen extends StatefulWidget {
  const HomeMapScreen({super.key});

  @override
  State<HomeMapScreen> createState() => _HomeMapScreenState();
}

class _HomeMapScreenState extends State<HomeMapScreen> {
  final Completer<GoogleMapController> _controller = Completer<GoogleMapController>();
  
  // SLP, México (default location)
  static const CameraPosition _defaultPosition = CameraPosition(
    target: LatLng(22.1565, -100.9855),
    zoom: 15.0,
  );

  LatLng? _currentPosition;
  bool _isLoading = true;
  bool _locationPermissionDenied = true;
  Set<Marker> _markers = {};
  final _placesService = PlacesService();
  final _debouncer = Debouncer(milliseconds: 500);
  List<PlaceSuggestion> _placeSuggestions = [];
  bool _isSearching = false;
  bool _isTripActive = false;
  Trip? _activeTrip;
  String? _tripRequestStatus;
  StreamSubscription<DocumentSnapshot>? _tripSubscription;
  bool _hasShownRatingDialog = false;
  String _selectedPaymentMethod = 'cash';

  // Controladores para los campos de texto
  final TextEditingController _originController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();


  final List<String> _dynamicPhrases = [
    'Tú pones el rumbo, Taxipro te lleva.',
    'Decide tu destino, Taxipro te lleva seguro.',
    'Cualquier destino que elijas, sin tarifas dinámicas, solo con Taxipro.',
    'Decide para dónde te llevamos seguro, solo con Taxipro.',
    'Con Taxipro, tú decides a dónde viajar.'
  ];

  @override
  void initState() {
    super.initState();
    _checkAndRequestLocationPermission();
  }

  Future<Driver?> _fetchDriverById(String driverId) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('drivers').doc(driverId).get();
      if (!doc.exists) return null;
      final data = doc.data() as Map<String, dynamic>;
      // Map backend fields to Driver model fields with fallbacks
      return Driver(
        id: doc.id,
        name: (data['name'] ?? data['fullName'] ?? 'Conductor'),
        carModel: (data['vehicleModel'] ?? data['carModel'] ?? 'Vehículo'),
        licensePlate: (data['vehiclePlate'] ?? data['licensePlate'] ?? '---'),
        rating: (data['rating'] is num) ? (data['rating'] as num).toDouble() : 5.0,
        photoUrl: (data['photoUrl'] ?? ''),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _checkAndRequestLocationPermission() async {
    // 1. Verificar si los servicios de ubicación están habilitados en el dispositivo
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _locationPermissionDenied = true;
        _isLoading = false;
      });
      // Opcional: Mostrar un diálogo para pedir que activen los servicios de ubicación.
      return;
    }

    // 2. Verificar el estado del permiso
    var status = await Permission.locationWhenInUse.status;

    if (status.isDenied) {
      // Si está denegado, solicitarlo
      status = await Permission.locationWhenInUse.request();
    }

    if (status.isGranted) {
      // Permiso concedido, obtener ubicación
      setState(() {
        _locationPermissionDenied = false;
      });
      _getCurrentLocation();
    } else {
      // Permiso denegado (temporal o permanentemente)
      setState(() {
        _locationPermissionDenied = true;
        _isLoading = false;
      });
      // Si es denegado permanentemente, mostrar diálogo para ir a ajustes
      if (status.isPermanentlyDenied) {
        _showOpenSettingsDialog();
      }
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
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
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
      // Verificar si el servicio de ubicación está habilitado
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // El servicio de ubicación no está habilitado
        setState(() {
          _locationPermissionDenied = true;
          _isLoading = false;
        });
        return;
      }
      
      // Obtener la posición actual
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      final LatLng currentLatLng = LatLng(position.latitude, position.longitude);
      
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
      _showDynamicPhraseDialogIfNeeded();
    } catch (e) {
      // En caso de error, usar ubicación por defecto
      setState(() {
        _isLoading = false;
      });
      _showDynamicPhraseDialogIfNeeded();
    }
  }

  Future<void> _goToCurrentLocation() async {
    if (_currentPosition != null) {
      final GoogleMapController controller = await _controller.future;
      controller.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(
          target: _currentPosition!,
          zoom: 15.0,
        ),
      ));
    }
  }

  void _showDynamicPhraseDialogIfNeeded() {
    // Asegurarse de que el diálogo solo se muestre una vez y el contexto esté disponible.
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showDynamicPhraseDialog());
    }
  }

  void _showWhereToBottomSheet() {
    // Prefill origin with a friendly default label
    if (_originController.text.isEmpty) {
      _originController.text = 'Mi ubicación actual';
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.5,
              minChildSize: 0.3,
              maxChildSize: 0.9,
              builder: (_, controller) {
                final bottomInset = MediaQuery.of(context).viewInsets.bottom;
                return Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).canvasColor,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: ListView(
                    controller: controller,
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
                    children: [
                      // Campo de texto para el origen
                      TextField(
                        controller: _originController,
                        autofocus: false,
                        decoration: InputDecoration(
                          hintText: 'Origen...',
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[800]
                              : Colors.grey[200],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Campo de texto para el destino
                      TextField(
                        controller: _destinationController,
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: 'Destino...',
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[800]
                              : Colors.grey[200],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      PaymentMethodSelector(
                        onPaymentMethodSelected: (method) {
                          setState(() {
                            _selectedPaymentMethod = method;
                          });
                        },
                      ),
                      const SizedBox(height: 20),
                      // Botón para solicitar viaje
                      ElevatedButton(
                        onPressed: (_tripRequestStatus == 'pending' || _tripRequestStatus == 'processing_payment' || _originController.text.isEmpty || _destinationController.text.isEmpty)
                            ? null
                            : _requestTrip,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          _tripRequestStatus == 'pending'
                              ? 'BUSCANDO CONDUCTOR...'
                              : _tripRequestStatus == 'processing_payment'
                                  ? 'PROCESANDO PAGO...'
                                  : 'PEDIR TAXI',
                          style: const TextStyle(color: Colors.white, fontSize: 18),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    ).whenComplete(() {
      // Limpiar sugerencias cuando se cierra el panel
      setState(() {
        _placeSuggestions = [];
      });
    });
  }

  void _showDynamicPhraseDialog() {
    final random = Random();
    final phrase = _dynamicPhrases[random.nextInt(_dynamicPhrases.length)];

    showDialog(
      context: context,
      barrierDismissible: false, // El usuario debe presionar el botón
      builder: (BuildContext context) => AlertDialog(
        title: const Text('¡Bienvenido a Taxipro!'),
        content: Text(
          phrase,
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('¡VAMOS!'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _debouncer.dispose();
    _tripSubscription?.cancel(); // Cancelar la suscripción al salir
    _originController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
              ),
              child: Center(
                child: Image.asset('assets/branding/isotipo_tp.png', height: 80), // Isotipo TP
              ),
            ),
            ListTile(
              leading: const Icon(Icons.wallet),
              title: const Text('Mi Cartera'),
              onTap: () {
                Navigator.pop(context); // Cierra el drawer
                Navigator.push(context, MaterialPageRoute(builder: (context) => const WalletScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Historial'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const TripHistoryScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.quiz),
              title: const Text('Preguntas frecuentes'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const FaqScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.support_agent),
              title: const Text('Soporte'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const SupportScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.shield),
              title: const Text('Escudo TaxiPro'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const EscudoTaxiProScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.sms),
              title: const Text('Solicitud por SMS (Offline)'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const SmsRequestScreen()));
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Cerrar Sesión'),
              onTap: () {
                FirebaseAuth.instance.signOut();
                Navigator.pop(context); // Cierra el drawer
              },
            ),
          ],
        ),
      ),
      appBar: AppBar(
        title: Image.asset('assets/branding/isotipo_tp.png', height: 32), // Isotipo TP solo
        centerTitle: true,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            tooltip: 'Abrir menú de navegación',
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar Sesión',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Mapa a pantalla completa - usar Positioned.fill para garantizar que ocupe todo el espacio
          if (!_locationPermissionDenied)
            Positioned.fill(
              child: GoogleMap(
                mapType: MapType.normal,
                initialCameraPosition: _defaultPosition,
                markers: _markers,
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                onMapCreated: (GoogleMapController controller) {
                  _controller.complete(controller);
                },
              ),
            )
          else
            const Positioned.fill(
              child: ColoredBox(color: Colors.black),
            ),

          // Botón principal para iniciar la solicitud de viaje
          if (!_isTripActive)
            Positioned(
              bottom: 30,
              left: 20,
              right: 20,
              child: _buildMainButton(),
            ),

          // Estado de carga o error
          if (_isLoading)
            Container(
              color: Colors.black.withAlpha(178),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),

          // Panel de viaje activo
          if (_isTripActive && _activeTrip != null)
            ActiveTripPanel(trip: _activeTrip!),

          // Mensaje si los permisos son denegados
          if (_locationPermissionDenied && !_isLoading)
            SafeArea(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(25),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Permisos de ubicación requeridos',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Para usar el mapa, necesitamos acceso a tu ubicación. Por favor, habilita los permisos en la configuración de la aplicación.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        openAppSettings();
                      },
                      child: const Text('Abrir Configuración'),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      // FAB para centrar en la ubicación actual
      floatingActionButton: FloatingActionButton(
        onPressed: _goToCurrentLocation,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.my_location),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildMainButton() {
    return ElevatedButton(
      onPressed: _showWhereToBottomSheet,
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: const Text(
        'Pedir Taxi',
        style: TextStyle(color: Colors.white, fontSize: 18),
      ),
    );
  }

  Future<LatLng?> _geocodeAddress(String address) async {
    debugPrint('Geocodificando dirección: $address');
    try {
      final apiKey = dotenv.env['GOOGLE_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('API Key de Google no encontrada.');
      }

      final uri = Uri.https('maps.googleapis.com', '/maps/api/geocode/json', {
        'address': address,
        'key': apiKey,
        'language': 'es',
        'region': 'mx',
      });

      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        if (data['status'] == 'OK' && (data['results'] as List).isNotEmpty) {
          final loc = data['results'][0]['geometry']['location'] as Map<String, dynamic>;
          final lat = (loc['lat'] as num).toDouble();
          final lng = (loc['lng'] as num).toDouble();
          debugPrint('Dirección geocodificada a: Lat: $lat, Lng: $lng');
          return LatLng(lat, lng);
        } else {
          debugPrint('Error de geocodificación: ${data['status']}');
          return null;
        }
      } else {
        debugPrint('Error en la solicitud de geocodificación: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Excepción en _geocodeAddress: $e');
      return null;
    }
  }

  LatLng? _parseLatLng(String text) {
    try {
      final parts = text.split(',');
      if (parts.length != 2) return null;
      final lat = double.parse(parts[0].trim());
      final lng = double.parse(parts[1].trim());
      if (lat.abs() <= 90 && lng.abs() <= 180) {
        return LatLng(lat, lng);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _requestTrip() async {
    debugPrint('Iniciando _requestTrip...');
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showErrorDialog('Debes iniciar sesión para solicitar un viaje.');
      return;
    }

    if (_destinationController.text.isEmpty) {
      _showErrorDialog('Por favor, selecciona un destino válido.');
      return;
    }

    setState(() {
      _tripRequestStatus = 'pending';
    });

    try {
      final destLatLng = await _geocodeAddress(_destinationController.text);
      if (destLatLng == null) {
        throw Exception('No se pudo encontrar la dirección de destino. Por favor, intenta con una dirección más específica.');
      }

      final originLatLng = _currentPosition!;
      final estimatedFare = 123.45; // TODO: Calcular tarifa real

      if (_selectedPaymentMethod == 'card') {
        await _handleCardPaymentFlow(originLatLng, destLatLng, estimatedFare);
      } else {
        await _createTripWithCash(originLatLng, destLatLng, estimatedFare);
      }

    } catch (e) {
      _showErrorDialog(e.toString());
      setState(() {
        _tripRequestStatus = null;
      });
    }
  }

  Future<void> _handleCardPaymentFlow(LatLng origin, LatLng destination, double fare) async {
    debugPrint('Iniciando flujo de pago con tarjeta...');
    setState(() {
      _tripRequestStatus = 'processing_payment';
    });

    try {
      // 1. Crear Payment Intent en el backend
      final response = await http.post(
        // TODO: Reemplazar con la URL real del backend
        Uri.parse('https://api.tudominio.com/createPaymentIntent'), 
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'amount': (fare * 100).toInt(), // En centavos
          'currency': 'mxn',
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('No se pudo comunicar con el servicio de pago.');
      }

      final data = json.decode(response.body);
      final clientSecret = data['clientSecret'];

      if (clientSecret == null) {
        throw Exception('El servicio de pago no devolvió una clave válida.');
      }

      debugPrint('Client Secret obtenido. Mostrando hoja de pago de Stripe...');

      // 2. Presentar la hoja de pago de Stripe
      await Stripe.instance.presentPaymentSheet();

      debugPrint('Pago completado con éxito.');

      // 3. Crear el viaje en Firestore con estado de pagado
      await _createTripInFirestore(
        origin: origin,
        destination: destination,
        fare: fare,
        paymentStatus: 'paid',
      );

    } catch (e) {
      debugPrint('Error durante el pago con tarjeta: $e');
      throw Exception('El pago con tarjeta falló. Por favor, intenta de nuevo.');
    }
  }

  Future<void> _createTripWithCash(LatLng origin, LatLng destination, double fare) async {
    debugPrint('Creando viaje con pago en efectivo...');
    await _createTripInFirestore(
      origin: origin,
      destination: destination,
      fare: fare,
      paymentStatus: 'pending',
    );
  }

  Future<void> _createTripInFirestore({
    required LatLng origin,
    required LatLng destination,
    required double fare,
    required String paymentStatus,
  }) async {
    final user = FirebaseAuth.instance.currentUser!;
    final newTripRef = FirebaseFirestore.instance.collection('trips').doc();

    await newTripRef.set({
      'userId': user.uid,
      'origin': {
        'lat': origin.latitude,
        'lng': origin.longitude,
        'address': _originController.text,
      },
      'destination': {
        'lat': destination.latitude,
        'lng': destination.longitude,
        'address': _destinationController.text,
      },
      'paymentMethod': _selectedPaymentMethod,
      'estimatedFare': fare,
      'paymentStatus': paymentStatus,
      'status': 'searching',
      'createdAt': FieldValue.serverTimestamp(),
    });

    debugPrint('Viaje creado en Firestore con ID: ${newTripRef.id}');

    if (mounted) {
      Navigator.pop(context); // Cierra el bottom sheet
    }

    _listenToTripUpdates(newTripRef.id);
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ocurrió un Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _listenToTripUpdates(String tripId) {
    debugPrint('Escuchando actualizaciones para el viaje con ID: $tripId');
    
    // Cerrar el BottomSheet y limpiar el estado de la solicitud
    if (mounted) {
      Navigator.pop(context);
      setState(() {
        _tripRequestStatus = null;
      });
    }

    _tripSubscription = FirebaseFirestore.instance
        .collection('trips')
        .doc(tripId)
        .snapshots()
        .listen((snapshot) async {
      if (!snapshot.exists) {
        debugPrint('El documento del viaje $tripId ya no existe.');
        return;
      }

      final updatedTrip = Trip.fromFirestore(snapshot);
      debugPrint('Viaje actualizado. Nuevo estado: ${updatedTrip.status}');

      // Lógica para manejar los diferentes estados del viaje...
      if (updatedTrip.status == 'assigned' || updatedTrip.status == 'active') {
        Trip tripForUi = updatedTrip;
        if (updatedTrip.driver == null && (updatedTrip.driverId ?? '').isNotEmpty) {
          final driver = await _fetchDriverById(updatedTrip.driverId!);
          if (mounted && driver != null) {
            tripForUi = updatedTrip.copyWith(driver: driver);
          }
        }
        setState(() {
          _isTripActive = true;
          _activeTrip = tripForUi;
        });
      } else if (updatedTrip.status == 'completed') {
        if (!_hasShownRatingDialog && mounted) {
          _hasShownRatingDialog = true;
          showDialog(
            context: context,
            builder: (ctx) => TripRatingDialog(
              driverName: updatedTrip.driver?.name ?? 'Conductor',
              onSubmit: (rating, comment) { /* ... */ },
            ),
          ).then((_) {
            if (mounted) {
              setState(() {
                _isTripActive = false;
                _activeTrip = null;
              });
              _tripSubscription?.cancel();
            }
          });
        }
      } else if (updatedTrip.status == 'cancelled') {
        if (mounted) {
          setState(() {
            _isTripActive = false;
            _activeTrip = null;
          });
        }
        _tripSubscription?.cancel();
      }
    });
  }
}
