import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
// import 'package:taxipro_usuariox/widgets/app_drawer.dart'; // Drawer desactivado temporalmente
import 'package:taxipro_usuariox/ui/ui_constants.dart';
import 'package:taxipro_usuariox/services/places_service.dart';
import 'package:taxipro_usuariox/utils/debouncer.dart';
import 'package:taxipro_usuariox/widgets/tx_icon.dart';
import 'package:taxipro_usuariox/widgets/app_icons.dart';

class OfflineRequestScreen extends StatefulWidget {
  const OfflineRequestScreen({super.key});

  @override
  State<OfflineRequestScreen> createState() => _OfflineRequestScreenState();
}

class _OfflineRequestScreenState extends State<OfflineRequestScreen> {
  final Completer<GoogleMapController> _controller = Completer<GoogleMapController>();
  final _debouncer = Debouncer(milliseconds: 500);
  final _places = PlacesService();

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final FocusNode _destFocus = FocusNode();

  final TextEditingController _originCtrl = TextEditingController(text: 'Mi ubicación actual');
  final TextEditingController _destCtrl = TextEditingController();

  LatLng? _currentPosition;
  List<PlaceSuggestion> _suggestions = [];
  bool _finding = false;
  LatLng _slpCenter = const LatLng(22.1565, -100.9855);

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    try {
      var status = await Permission.locationWhenInUse.status;
      if (status.isDenied) status = await Permission.locationWhenInUse.request();
      if (!status.isGranted) return;
      Position? pos;
      try {
        pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.medium, timeLimit: const Duration(seconds: 6));
      } catch (_) {}
      if (pos != null) {
        setState(() => _currentPosition = LatLng(pos!.latitude, pos.longitude));
        if (_controller.isCompleted) {
          final c = await _controller.future;
          c.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(target: _currentPosition!, zoom: 15)));
        }
      }
    } catch (_) {}
  }

  Future<void> _recalcOrigin() async {
    await _initLocation();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ubicación actualizada')));
  }

  void _showHowItWorks() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: const [
            Text('¿Cómo funciona?', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            SizedBox(height: 8),
            Text('Modo limitado sin conexión: la app enviará un SMS con tu origen y destino a la plataforma TaxiPro. ')
            ,Text('Recibirás por SMS el nombre del chofer, número de taxi, modelo, ETA y costo aproximado. '),
            Text('Pago solo en efectivo. No incluye monitoreo de seguridad ni grabación.'),
          ],
        ),
      ),
    );
  }

  Future<void> _continue() async {
    final destText = _destCtrl.text.trim();
    if (destText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Introduce destino')));
      return;
    }
    setState(() => _finding = true);
    try {
      final bias = _currentPosition ?? _slpCenter;
      // Origin
      final originLatLng = _currentPosition ?? _slpCenter;
      final originAddress = _originCtrl.text.trim().isEmpty ? 'Mi ubicación actual' : _originCtrl.text.trim();
      // Destination
      final dest = await _places.geocodeAddress(destText, locationBias: bias, radius: 10000);
      if (dest == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo geocodificar el destino')));
        return;
      }
      if (!mounted) return;
      Navigator.of(context).pushNamed(
        '/offline/confirm',
        arguments: {
          'origin': originLatLng,
          'originAddress': originAddress,
          'destination': dest,
          'destinationAddress': destText,
        },
      );
    } finally {
      if (mounted) setState(() => _finding = false);
    }
  }

  @override
  void dispose() {
    _debouncer.dispose();
    _destFocus.dispose();
    _originCtrl.dispose();
    _destCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final onBg = Theme.of(context).colorScheme.onBackground;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final mq = MediaQuery.of(context);
    final kb = mq.viewInsets.bottom;
    final screenH = mq.size.height;
    final topSafe = mq.viewPadding.top;
    final availH = screenH - kb - topSafe - 24;
    final upper = screenH * 0.94;
    double overlayHeight = availH.clamp(0.0, upper).toDouble();
    const double minOverlay = 220.0;
    if (overlayHeight < minOverlay) {
      overlayHeight = math.min(minOverlay, upper);
    }
    return Scaffold(
      key: _scaffoldKey,
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(target: _currentPosition ?? _slpCenter, zoom: 14),
              myLocationEnabled: false,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              scrollGesturesEnabled: false,
              zoomGesturesEnabled: false,
              rotateGesturesEnabled: false,
              tiltGesturesEnabled: false,
              onMapCreated: (c) => _controller.complete(c),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                color: isLight ? Colors.black.withOpacity(0.25) : Colors.white.withOpacity(0.06),
              ),
            ),
          ),
          // Contenido scrollable que evita overflow con teclado
          SafeArea(
            child: LayoutBuilder(builder: (context, c) {
              final bottomInset = MediaQuery.of(context).viewInsets.bottom;
              return SingleChildScrollView(
                padding: EdgeInsets.only(bottom: bottomInset + 16),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: c.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        Center(child: Image.asset('assets/branding/logo_complete.png', height: 120)),
                        const SizedBox(height: 8),
                        _buildOfflineOverlay(context, isLight: isLight),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildOfflineOverlay(BuildContext context, {double? overlayHeight, required bool isLight}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(kGapS),
      decoration: BoxDecoration(
        color: isLight ? Colors.black.withOpacity(0.8) : Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(kCornerRadius),
      ),
      child: SizedBox(
        height: overlayHeight,
        child: Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Solicitar taxi sin internet', textAlign: TextAlign.center, style: TextStyle(color: isLight ? Colors.white : Colors.black, fontWeight: FontWeight.w800, fontSize: 20)),
            const SizedBox(height: kGapXS),
            Text(
              'Modo limitado. El viaje se gestiona por SMS. Pago solo en efectivo. Sin seguridad activa.',
              textAlign: TextAlign.center,
              style: TextStyle(color: (isLight ? Colors.white : Colors.black).withOpacity(0.9)),
            ),
            const SizedBox(height: kGapS),
            TextField(
              controller: _originCtrl,
              readOnly: true,
              style: TextStyle(color: isLight ? Colors.white : Colors.black),
              decoration: InputDecoration(
                labelText: 'Desde',
                prefixIcon: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: TxIcon(AppIcons.origin, size: 20, semanticLabel: 'Origen'),
                ),
                suffixIcon: IconButton(
                  icon: Icon(Icons.refresh, color: isLight ? Colors.white : Colors.black),
                  onPressed: _recalcOrigin,
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: (isLight ? Colors.white : Colors.black).withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: (isLight ? Colors.white : Colors.black).withOpacity(0.6), width: 1.4),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: kGapXS),
            TextField(
              controller: _destCtrl,
              focusNode: _destFocus,
              autofocus: true,
              style: TextStyle(color: isLight ? Colors.white : Colors.black),
              textInputAction: TextInputAction.done,
              onChanged: (text) {
                final bias = _currentPosition ?? _slpCenter;
                _debouncer.run(() async {
                  final s = await _places.getAutocomplete(text, locationBias: bias, radius: 10000);
                  if (mounted) setState(() => _suggestions = s);
                });
              },
              decoration: InputDecoration(
                hintText: 'Introduce destino...',
                hintStyle: TextStyle(color: (isLight ? Colors.white : Colors.black).withOpacity(0.85)),
                prefixIcon: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: TxIcon(AppIcons.search, size: 20, semanticLabel: 'Buscar destino'),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: (isLight ? Colors.white : Colors.black).withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: (isLight ? Colors.white : Colors.black).withOpacity(0.6), width: 1.4),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            if (_suggestions.isNotEmpty) ...[
              const SizedBox(height: kGapXS),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 200),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _suggestions.length.clamp(0, 6),
                  itemBuilder: (context, index) {
                    final s = _suggestions[index];
                    return ListTile(
                      dense: true,
                      leading: TxIcon(AppIcons.destination, size: 20, semanticLabel: 'Sugerencia'),
                      title: Text(s.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: isLight ? Colors.white : Colors.black)),
                      onTap: () {
                        _destCtrl.text = s.description;
                        setState(() => _suggestions = []);
                        FocusScope.of(context).unfocus();
                      },
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: kGapS),
            SizedBox(
              height: kButtonHeight,
              child: ElevatedButton(
                onPressed: _finding ? null : _continue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kCornerRadius)),
                ),
                child: _finding
                    ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Solicitar taxi'),
              ),
            ),
            const SizedBox(height: kGapXS),
            Center(
              child: TextButton(
                onPressed: _showHowItWorks,
                child: const Text('¿Cómo funciona?'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
