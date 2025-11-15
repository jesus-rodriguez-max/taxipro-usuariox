import 'package:flutter/material.dart';
import 'dart:math';
import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:taxipro_usuariox/widgets/app_drawer.dart'; // Drawer desactivado temporalmente
import 'package:taxipro_usuariox/ui/ui_constants.dart';
import 'package:taxipro_usuariox/services/sms_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OfflineConfirmScreen extends StatefulWidget {
  const OfflineConfirmScreen({super.key, required this.origin, required this.originAddress, required this.destination, required this.destinationAddress});

  final LatLng origin;
  final String originAddress;
  final LatLng destination;
  final String destinationAddress;

  @override
  State<OfflineConfirmScreen> createState() => _OfflineConfirmScreenState();
}

class _OfflineConfirmScreenState extends State<OfflineConfirmScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _rememberNumber = false;
  bool _sending = false;
  late final String _smsBody;
  double? _distanceKm;
  double? _estimatedFare;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'ANON';
    // Compute distance and rough fare estimate (offline)
    _distanceKm = _haversine(widget.origin.latitude, widget.origin.longitude, widget.destination.latitude, widget.destination.longitude);
    _estimatedFare = _estimateFare(_distanceKm!);
    _smsBody = SmsService.buildOfflineSmsBody(
      originAddress: widget.originAddress,
      originLat: widget.origin.latitude,
      originLng: widget.origin.longitude,
      destAddress: widget.destinationAddress,
      destLat: widget.destination.latitude,
      destLng: widget.destination.longitude,
      uid: uid,
    );
    _rememberNumber = await SmsService.getRememberNumber();
    if (mounted) setState(() {});
  }

  // Haversine distance in KM
  double _haversine(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371.0; // km
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);
    final a =
        (sin(dLat / 2) * sin(dLat / 2)) + cos(_deg2rad(lat1)) * cos(_deg2rad(lat2)) * (sin(dLon / 2) * sin(dLon / 2));
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _deg2rad(double deg) => deg * (3.141592653589793 / 180.0);

  // Simple offline fare estimate (restore previous heuristic)
  double _estimateFare(double km) {
    const base = 20.0; // base MXN
    const perKm = 12.0; // MXN por km
    return (base + km * perKm).clamp(35.0, 9999.0);
  }

  Future<bool> _ensureLegalAccepted() async {
    final prefs = await SharedPreferences.getInstance();
    final accepted = prefs.getBool('offlineLegalAccepted') ?? false;
    if (accepted) return true;
    bool check = false;
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Modo limitado sin conexión'),
          content: StatefulBuilder(
            builder: (context, setS) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('No incluye monitoreo ni grabación. Pago solo en efectivo.'),
                const SizedBox(height: 8),
                Row(children: [
                  Checkbox(value: check, onChanged: (v) => setS(() => check = v ?? false)),
                  const Expanded(child: Text('Entiendo y acepto')),
                ])
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, check), child: const Text('Aceptar')),
          ],
        );
      },
    );
    if (ok == true) {
      await prefs.setBool('offlineLegalAccepted', true);
      return true;
    }
    return false;
  }

  Future<void> _send() async {
    if (_sending) return;
    setState(() => _sending = true);
    try {
      if (!await _ensureLegalAccepted()) {
        setState(() => _sending = false);
        return;
      }
      final number = await SmsService.resolveDestinationNumber();
      if (number == null || number.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No hay número de TaxiPro para SMS (OFFLINE_SMS_NUMBER).')));
        setState(() => _sending = false);
        return;
      }
      await SmsService.setRememberNumber(_rememberNumber);
      final ok = await SmsService.sendSms(number, _smsBody);
      if (ok) {
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed('/offline/sent', arguments: {'number': number});
      } else {
        await SmsService.copyToClipboard(_smsBody);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo abrir SMS. Mensaje copiado al portapapeles.')));
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al preparar el SMS.')));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final onBg = Theme.of(context).colorScheme.onBackground;
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          color: onBg,
          onPressed: () => Navigator.of(context).pushNamed('/map'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Confirmación de solicitud (SMS)', style: TextStyle(color: onBg, fontWeight: FontWeight.w800, fontSize: 20)),
          const SizedBox(height: 8),
          Text('Origen: ${widget.originAddress} | ${widget.origin.latitude.toStringAsFixed(5)},${widget.origin.longitude.toStringAsFixed(5)}', style: TextStyle(color: onBg)),
          Text('Destino: ${widget.destinationAddress} | ${widget.destination.latitude.toStringAsFixed(5)},${widget.destination.longitude.toStringAsFixed(5)}', style: TextStyle(color: onBg)),
          if (_distanceKm != null) ...[
            const SizedBox(height: 8),
            Text('Distancia estimada: ${_distanceKm!.toStringAsFixed(2)} km', style: TextStyle(color: onBg.withOpacity(0.9))),
          ],
          if (_estimatedFare != null) ...[
            const SizedBox(height: 4),
            Text('Costo aproximado: \$${_estimatedFare!.toStringAsFixed(0)} MXN', style: TextStyle(color: onBg, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('Pago solo en efectivo. Sin seguridad activa.', style: TextStyle(color: onBg.withOpacity(0.8))),
          ],
          const SizedBox(height: 12),
          Text('Mensaje SMS a enviar:', style: TextStyle(color: onBg.withOpacity(0.9))),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(12),
            child: SelectableText(_smsBody, style: TextStyle(color: onBg, fontFamily: 'monospace')),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            value: _rememberNumber,
            onChanged: (v) => setState(() => _rememberNumber = v),
            title: const Text('Recordarme este número de TaxiPro'),
            subtitle: const Text('No volver a preguntarme en este dispositivo.'),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: kButtonHeight,
            child: ElevatedButton(
              onPressed: _sending ? null : _send,
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kCornerRadius)),
              ),
              child: _sending ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Enviar SMS'),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Editar destinos'),
            ),
          ),
        ],
      ),
    );
  }
}
