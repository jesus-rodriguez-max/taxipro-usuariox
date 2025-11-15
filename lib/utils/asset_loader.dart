import 'package:flutter/services.dart' show rootBundle;

class AssetLoader {
  static Future<String> loadText(String path) async {
    try {
      return await rootBundle.loadString(path);
    } catch (_) {
      return 'Contenido no disponible. Contacta soporte.';
    }
  }
}
