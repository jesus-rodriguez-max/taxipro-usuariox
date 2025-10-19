import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

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
  final String? apiKey = dotenv.env['GOOGLE_API_KEY'];

  Future<List<PlaceSuggestion>> getAutocomplete(String input) async {
    if (apiKey == null) {
      // En un entorno de producción, esto debería ser manejado por un sistema de logging.
      // Por ahora, simplemente retornamos una lista vacía para no crashear.
      return [];
    }

    if (input.isEmpty) {
      return [];
    }

    final String sessionToken = DateTime.now().millisecondsSinceEpoch.toString();
    final Uri uri = Uri.https(
      'maps.googleapis.com',
      '/maps/api/place/autocomplete/json',
      {
        'input': input,
        'key': apiKey,
        'sessiontoken': sessionToken,
        'language': 'es',
        'components': 'country:mx', // Limitar a México
      },
    );

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          final List<dynamic> predictions = data['predictions'];
          return predictions
              .map((p) => PlaceSuggestion(p['place_id'], p['description']))
              .toList();
        }
      }
      return [];
    } catch (e) {
      // En un entorno de producción, registrar el error con un servicio de logging.
      return [];
    }
  }
}
