import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:taxipro_usuariox/services/functions_service.dart';

class DirectionsResult {
  final List<LatLng> polylinePoints;
  final double distanceKm;
  final int durationMin;
  final String startAddress;
  final String endAddress;

  DirectionsResult({
    required this.polylinePoints,
    required this.distanceKm,
    required this.durationMin,
    required this.startAddress,
    required this.endAddress,
  });
}

class DirectionsService {
  Future<DirectionsResult?> getRoute({
    required LatLng origin,
    required LatLng destination,
  }) async {
    try {
      final resp = await CloudFunctionsService.instance.callPublic(
        'directionsRouteCallable',
        {
          'origin': {'lat': origin.latitude, 'lng': origin.longitude},
          'destination': {'lat': destination.latitude, 'lng': destination.longitude},
          'mode': 'driving',
          'language': 'es',
        },
      );
      if (resp['ok'] != true) return null;
      final polyline = resp['polyline'] as String?;
      if (polyline == null || polyline.isEmpty) return null;
      final pts = _decodePolyline(polyline);
      final distanceKm = (resp['distanceKm'] as num?)?.toDouble() ?? 0.0;
      final durationMin = (resp['durationMin'] as num?)?.toInt() ?? 0;
      final startAddress = resp['startAddress'] as String? ?? '';
      final endAddress = resp['endAddress'] as String? ?? '';
      return DirectionsResult(
        polylinePoints: pts,
        distanceKm: distanceKm,
        durationMin: durationMin,
        startAddress: startAddress,
        endAddress: endAddress,
      );
    } catch (_) {
      return null;
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1);
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1);
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }
}
