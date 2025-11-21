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
  // 🚀 CACHE LOCAL para geocoding
  static final Map<String, LatLng> _geocodeCache = {};
  static final Map<String, List<PlaceSuggestion>> _autocompleteCache = {};
  
  Future<LatLng?> geocodeAddress(String address, {LatLng? locationBias, int? radius}) async {
    final cacheKey = '$address|${locationBias?.latitude}|${locationBias?.longitude}|$radius';
    
    // ⚡️ CACHE HIT: Devolver inmediatamente si existe
    if (_geocodeCache.containsKey(cacheKey)) {
      developer.log('geocodeAddress CACHE HIT: $address', name: 'PlacesService');
      return _geocodeCache[cacheKey];
    }
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
      
      print('[CALLABLE] geocodeAddressCallable started');
      developer.log('geocodeAddress payload: $payload', name: 'PlacesService');
      
      final resp = await CloudFunctionsService.instance.callPublic(
        'geocodeAddressCallable',
        payload,
      );
      
      print('[CALLABLE] geocodeAddressCallable finished');
      developer.log('geocodeAddress resp.ok=${resp['ok']} keys=${resp.keys.toList()}', name: 'PlacesService');
      
      if (resp['ok'] != true || resp['location'] == null) return null;
      final locRaw = resp['location'];
      if (locRaw is! Map) return null;
      final loc = locRaw.map((k, v) => MapEntry(k.toString(), v));
      final result = LatLng((loc['lat'] as num).toDouble(), (loc['lng'] as num).toDouble());
      
      // 💾 GUARDAR EN CACHE
      _geocodeCache[cacheKey] = result;
      return result;
    } on FirebaseFunctionsException {
      rethrow;
    } catch (e) {
      developer.log('geocodeAddress error: $e', name: 'PlacesService');
      rethrow;
    }
  }

  Future<LatLng?> geocodePlaceId(String placeId) async {
    // ⚡️ CACHE por placeId
    if (_geocodeCache.containsKey(placeId)) {
      developer.log('geocodePlaceId CACHE HIT: $placeId', name: 'PlacesService');
      return _geocodeCache[placeId];
    }
    
    try {
      print('[CALLABLE] geocodePlaceId started');
      developer.log('geocodePlaceId placeId=$placeId', name: 'PlacesService');
      
      final resp = await CloudFunctionsService.instance.callPublic(
        'geocodeAddressCallable',
        {'placeId': placeId, 'language': 'es'},
      );
      
      print('[CALLABLE] geocodePlaceId finished');
      developer.log('geocodePlaceId resp.ok=${resp['ok']} keys=${resp.keys.toList()}', name: 'PlacesService');
      
      if (resp['ok'] != true || resp['location'] == null) return null;
      final locRaw = resp['location'];
      if (locRaw is! Map) return null;
      final loc = locRaw.map((k, v) => MapEntry(k.toString(), v));
      final result = LatLng((loc['lat'] as num).toDouble(), (loc['lng'] as num).toDouble());
      
      // 💾 GUARDAR EN CACHE
      _geocodeCache[placeId] = result;
      return result;
    } on FirebaseFunctionsException {
      rethrow;
    } catch (e) {
      developer.log('geocodePlaceId error: $e', name: 'PlacesService');
      return null;
    }
  }
  Future<List<PlaceSuggestion>> getAutocomplete(String input, {LatLng? locationBias, int? radius}) async {
    if (input.isEmpty) return [];
    
    // ⚡️ CACHE AUTOCOMPLETE
    final cacheKey = '$input|${locationBias?.latitude}|${locationBias?.longitude}|$radius';
    if (_autocompleteCache.containsKey(cacheKey)) {
      developer.log('autocomplete CACHE HIT: $input', name: 'PlacesService');
      return _autocompleteCache[cacheKey]!;
    }
    
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
      
      print('[CALLABLE] placesAutocompleteCallable started');
      developer.log('autocomplete payload: $payload', name: 'PlacesService');
      
      final resp = await CloudFunctionsService.instance.callPublic(
        'placesAutocompleteCallable',
        payload,
      );
      
      print('[CALLABLE] placesAutocompleteCallable finished');
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
      
      // 💾 GUARDAR EN CACHE
      _autocompleteCache[cacheKey] = out;
      return out;
    } catch (_) {
      return [];
    }
  }
}
