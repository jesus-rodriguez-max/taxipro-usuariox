import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:taxipro_usuariox/models/trip_model.dart';
import 'package:taxipro_usuariox/screens/profile_screen.dart';

class EmergencyService {
  static Future<LatLng?> _getQuickLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;
      Position? pos;
      try {
        pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.low, timeLimit: const Duration(seconds: 4));
      } catch (_) {
        pos = await Geolocator.getLastKnownPosition();
      }
      if (pos == null) return null;
      return LatLng(pos.latitude, pos.longitude);
    } catch (_) {
      return null;
    }
  }

  static Future<String?> _getTrustedPhone() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return null;
      final doc = await FirebaseFirestore.instance.collection('safety_profiles').doc(uid).get();
      final data = doc.data();
      final phone = data?['trustedContactPhone'] as String?;
      if (phone != null && phone.trim().isNotEmpty) return phone.trim();
      final pax = await FirebaseFirestore.instance.collection('passengers').doc(uid).get();
      final paxData = pax.data();
      final alt = paxData?['trustedContactPhone'] as String?;
      if (alt != null && alt.trim().isNotEmpty) return alt.trim();
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<void> activatePanic(BuildContext context, {Trip? activeTrip}) async {
    final phonePerm = await Permission.phone.request();
    if (!phonePerm.isGranted) {}
    final trusted = await _getTrustedPhone();
    final loc = await _getQuickLocation();

    String text = 'ALERTA TAXIPRO: Pasajero requiere ayuda.';
    if (loc != null) {
      text += ' Ubicación: https://maps.google.com/?q=${loc.latitude},${loc.longitude}';
    }
    if (activeTrip != null) {
      final driverName = activeTrip.driver?.name ?? '';
      final plates = activeTrip.driver?.licensePlate ?? '';
      if (activeTrip.originAddress.isNotEmpty) {
        text += ' Origen: ${activeTrip.originAddress}.';
      }
      if (activeTrip.destinationAddress.isNotEmpty) {
        text += ' Destino: ${activeTrip.destinationAddress}.';
      }
      if (driverName.isNotEmpty || plates.isNotEmpty) {
        text += ' Conductor: $driverName $plates.';
      }
    }

    try {
      await FlutterPhoneDirectCaller.callNumber('911');
    } catch (_) {}

    if (trusted == null || trusted.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Configura un contacto de confianza en tu perfil.')));
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfileScreen()));
      }
      return;
    }

    final encodedText = Uri.encodeComponent(text);
    final phone = trusted.replaceAll('+', '').replaceAll(' ', '');
    final uri = Uri.parse('whatsapp://send?phone=$phone&text=$encodedText');
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        final wa = Uri.parse('https://wa.me/$phone?text=$encodedText');
        await launchUrl(wa, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo abrir WhatsApp.')));
      }
    }
  }
}
