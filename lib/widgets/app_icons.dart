import 'package:flutter/widgets.dart';

@immutable
class AppIcon {
  final String light;
  final String dark;
  const AppIcon({required this.light, required this.dark});
}

class AppIcons {
  static const String _base = 'assets/icon/taxipro_icons_pack_v1';

  static const AppIcon search = AppIcon(
    light: '$_base/light/legal/lupa_documento.png',
    dark: '$_base/dark/legal/lupa_documento.png',
  );
  static const AppIcon myLocation = AppIcon(
    light: '$_base/light/viajes/gps_activo.png',
    dark: '$_base/dark/viajes/gps_activo.png',
  );
  static const AppIcon place = AppIcon(
    light: '$_base/light/viajes/destino_bandera.png',
    dark: '$_base/dark/viajes/destino_bandera.png',
  );
  static const AppIcon wallet = AppIcon(
    light: '$_base/light/pagos/cartera.png',
    dark: '$_base/dark/pagos/cartera.png',
  );
  static const AppIcon menu = AppIcon(
    light: '$_base/light/configuracion/menu_puntos.png',
    dark: '$_base/dark/configuracion/menu_puntos.png',
  );
  static const AppIcon phone = AppIcon(
    light: '$_base/light/soporte/telefono_llamada.png',
    dark: '$_base/dark/soporte/telefono_llamada.png',
  );
  static const AppIcon chat = AppIcon(
    light: '$_base/light/soporte/chat_activo.png',
    dark: '$_base/dark/soporte/chat_activo.png',
  );
  static const AppIcon shield = AppIcon(
    light: '$_base/light/security/escudo_tp.png',
    dark: '$_base/dark/security/escudo_tp.png',
  );
  static const AppIcon gps = AppIcon(
    light: '$_base/light/viajes/gps_activo.png',
    dark: '$_base/dark/viajes/gps_activo.png',
  );
  static const AppIcon faq = AppIcon(
    light: '$_base/light/soporte/burbuja_pregunta.png',
    dark: '$_base/dark/soporte/burbuja_pregunta.png',
  );
  static const AppIcon settings = AppIcon(
    light: '$_base/light/configuracion/engranaje.png',
    dark: '$_base/dark/configuracion/engranaje.png',
  );
  static const AppIcon star = AppIcon(
    light: '$_base/light/configuracion/estrella.png',
    dark: '$_base/dark/configuracion/estrella.png',
  );
  static const AppIcon origin = AppIcon(
    light: '$_base/light/viajes/mapa_origen.png',
    dark: '$_base/dark/viajes/mapa_origen.png',
  );
  static const AppIcon destination = AppIcon(
    light: '$_base/light/viajes/destino_bandera.png',
    dark: '$_base/dark/viajes/destino_bandera.png',
  );
  static const AppIcon creditCard = AppIcon(
    light: '$_base/light/pagos/tarjeta.png',
    dark: '$_base/dark/pagos/tarjeta.png',
  );
  static const AppIcon taxi = AppIcon(
    light: '$_base/light/viajes/taxi.png',
    dark: '$_base/dark/viajes/taxi.png',
  );
  static const AppIcon route = AppIcon(
    light: '$_base/light/viajes/carretera.png',
    dark: '$_base/dark/viajes/carretera.png',
  );
  static const AppIcon clockCar = AppIcon(
    light: '$_base/light/viajes/reloj_auto.png',
    dark: '$_base/dark/viajes/reloj_auto.png',
  );
  static const AppIcon mic = AppIcon(
    light: '$_base/light/soporte/microfono.png',
    dark: '$_base/dark/soporte/microfono.png',
  );
  static const AppIcon email = AppIcon(
    light: '$_base/light/soporte/correo.png',
    dark: '$_base/dark/soporte/correo.png',
  );
}

class MissingIconsV2 {
  static const String _base = 'assets/icon/taxipro_missing_icons_v2/missing_icons';

  static const AppIcon map = AppIcon(
    light: '$_base/light/mapa.png',
    dark: '$_base/dark/mapa.png',
  );
  static const AppIcon question = AppIcon(
    light: '$_base/light/pregunta.png',
    dark: '$_base/dark/pregunta.png',
  );
  static const AppIcon exitDoor = AppIcon(
    light: '$_base/light/salida_puerta.png',
    dark: '$_base/dark/salida_puerta.png',
  );
  static const AppIcon shieldInfo = AppIcon(
    light: '$_base/light/escudo_info.png',
    dark: '$_base/dark/escudo_info.png',
  );
  static const AppIcon deleteCard = AppIcon(
    light: '$_base/light/eliminar_tarjeta.png',
    dark: '$_base/dark/eliminar_tarjeta.png',
  );
  static const AppIcon user = AppIcon(
    light: '$_base/light/usuario.png',
    dark: '$_base/dark/usuario.png',
  );
  static const AppIcon star = AppIcon(
    light: '$_base/light/star.png',
    dark: '$_base/dark/star.png',
  );
}
