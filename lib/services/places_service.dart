import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:taxipro_usuariox/services/functions_service.dart';
import 'dart:developer' as developer;

class PlaceSuggestion {
  final String placeId;
  final String description;

  PlaceSuggestion(this.placeId, this.description);

  @override
  String toString() {
    return 'Suggestion(description: $description, placeId: $placeId)';
  }
}

class PlacesService {
  Future<LatLng?> geocodeAddress(String address, {LatLng? locationBias, int? radius}) async {
    try {
      final Map<String, dynamic> payload = {
        'address': address,
        'language': 'es',
        'region': 'mx',
      };
      if (locationBias != null) {
        payload['location'] = {
          'lat': locationBias.latitude,
          'lng': locationBias.longitude,
        };
      }
      if (radius != null) payload['radius'] = radius;
      developer.log('geocodeAddress payload: $payload', name: 'PlacesService');
      final resp = await CloudFunctionsService.instance.callPublic(
        'geocodeAddressCallable',
        payload,
      );
      developer.log('geocodeAddress resp.ok=${resp['ok']} keys=${resp.keys.toList()}', name: 'PlacesService');
      if (resp['ok'] != true || resp['location'] == null) return null;
      final locRaw = resp['location'];
      if (locRaw is! Map) return null;
      final loc = locRaw.map((k, v) => MapEntry(k.toString(), v));
      return LatLng((loc['lat'] as num).toDouble(), (loc['lng'] as num).toDouble());
    } on FirebaseFunctionsException {
      rethrow;
    } catch (e) {
      developer.log('geocodeAddress error: $e', name: 'PlacesService');
      rethrow;
    }
  }

  Future<LatLng?> geocodePlaceId(String placeId) async {
    try {
      developer.log('geocodePlaceId placeId=$placeId', name: 'PlacesService');
      final resp = await CloudFunctionsService.instance.callPublic(
        'geocodeAddressCallable',
        {'placeId': placeId, 'language': 'es'},
      );
      developer.log('geocodePlaceId resp.ok=${resp['ok']} keys=${resp.keys.toList()}', name: 'PlacesService');
      if (resp['ok'] != true || resp['location'] == null) return null;
      final locRaw = resp['location'];
      if (locRaw is! Map) return null;
      final loc = locRaw.map((k, v) => MapEntry(k.toString(), v));
      return LatLng((loc['lat'] as num).toDouble(), (loc['lng'] as num).toDouble());
    } on FirebaseFunctionsException {
      rethrow;
    } catch (e) {
      developer.log('geocodePlaceId error: $e', name: 'PlacesService');
      return null;
    }
  }
  Future<List<PlaceSuggestion>> getAutocomplete(String input, {LatLng? locationBias, int? radius}) async {
    if (input.isEmpty) return [];
    final String sessionToken = DateTime.now().millisecondsSinceEpoch.toString();
    try {
      final Map<String, dynamic> payload = {
        'input': input,
        'sessiontoken': sessionToken,
        'language': 'es',
        'components': 'country:mx',
      };
      if (locationBias != null) {
        payload['location'] = {
          'lat': locationBias.latitude,
          'lng': locationBias.longitude,
        };
      }
      if (radius != null) payload['radius'] = radius;
      developer.log('autocomplete payload: $payload', name: 'PlacesService');
      final resp = await CloudFunctionsService.instance.callPublic(
        'placesAutocompleteCallable',
        payload,
      );
      developer.log('autocomplete resp.status=${resp['ok']} count=${(resp['suggestions'] as List?)?.length ?? 0}', name: 'PlacesService');
      if (resp['ok'] != true) return [];
      final list = (resp['suggestions'] as List?) ?? [];
      final out = <PlaceSuggestion>[];
      for (final item in list) {
        if (item is Map<String, dynamic>) {
          final id = item['placeId'] as String?;
          final desc = item['description'] as String?;
          if (id != null && desc != null) out.add(PlaceSuggestion(id, desc));
        } else if (item is Map) {
          final m = item.map((k, v) => MapEntry(k.toString(), v));
          final id = m['placeId'] as String?;
          final desc = m['description'] as String?;
          if (id != null && desc != null) out.add(PlaceSuggestion(id, desc));
        }
      }
      return out;
    } catch (_) {
      return [];
    }
  }
}
