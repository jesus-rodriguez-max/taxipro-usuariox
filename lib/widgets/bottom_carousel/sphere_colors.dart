import 'package:flutter/material.dart';

class SphereSpec {
  final Color c1;
  final Color c2;
  final IconData icon;
  final String semantics;
  const SphereSpec({required this.c1, required this.c2, required this.icon, required this.semantics});
}

// Helper to slightly lighten a color for the radial center
Color lighten(Color color, [double amount = 0.25]) {
  final hsl = HSLColor.fromColor(color);
  final hslLight = hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0));
  return hslLight.toColor();
}

// Sphere color and icon specs per module key
const Map<String, SphereSpec> kSphereSpecs = {
  'map': SphereSpec(
    c1: Color(0xFF0061FF),
    c2: Color(0xFF00C6FF),
    icon: Icons.map,
    semantics: 'Mapa',
  ),
  'illustr': SphereSpec(
    c1: Color(0xFFFF6A00),
    c2: Color(0xFFFFC300),
    icon: Icons.image,
    semantics: 'Ilustraciones',
  ),
  'wallet': SphereSpec(
    c1: Color(0xFF00E676),
    c2: Color(0xFF00C853),
    icon: Icons.account_balance_wallet,
    semantics: 'Wallet',
  ),
  'faq': SphereSpec(
    c1: Color(0xFFFFD600),
    c2: Color(0xFFFFEA00),
    icon: Icons.help_outline,
    semantics: 'Preguntas',
  ),
  'support': SphereSpec(
    c1: Color(0xFF7C4DFF),
    c2: Color(0xFF651FFF),
    icon: Icons.support_agent,
    semantics: 'Soporte',
  ),
  'shield': SphereSpec(
    c1: Color(0xFF00B8D4),
    c2: Color(0xFF0091EA),
    icon: Icons.shield,
    semantics: 'Escudo Taxi Pro',
  ),
  'offline': SphereSpec(
    c1: Color(0xFFFF1744),
    c2: Color(0xFFD50000),
    icon: Icons.sms,
    semantics: 'Solicitud sin Internet (SMS)',
  ),
  'legal': SphereSpec(
    c1: Color(0xFF9E9E9E),
    c2: Color(0xFF616161),
    icon: Icons.privacy_tip,
    semantics: 'Privacidad y Términos',
  ),
  'settings': SphereSpec(
    c1: Color(0xFF00E5FF),
    c2: Color(0xFF1DE9B6),
    icon: Icons.settings,
    semantics: 'Configuración',
  ),
  'profile': SphereSpec(
    c1: Color(0xFFC51162),
    c2: Color(0xFFAA00FF),
    icon: Icons.person,
    semantics: 'Mi Perfil',
  ),
  'logout': SphereSpec(
    c1: Color(0xFFFF3D00),
    c2: Color(0xFFDD2C00),
    icon: Icons.logout,
    semantics: 'Cerrar sesión',
  ),
};
