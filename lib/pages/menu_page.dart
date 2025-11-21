// lib/pages/menu_page.dart

import 'package:flutter/material.dart';

/// Página de menú principal para la app de pasajeros de TaxiPro.
/// Esta es una versión básica que muestra opciones y sirve como punto
/// de partida para implementar funcionalidades futuras.
class MenuPage extends StatelessWidget {
  const MenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Menú'),
      ),
      body: ListView(
        children: const [
          ListTile(
            leading: Icon(Icons.history),
            title: Text('Historial de viajes'),
            subtitle: Text('Consulta tus viajes pasados'),
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.support_agent),
            title: Text('Soporte'),
            subtitle: Text('Contacta al soporte de TaxiPro'),
          ),
        ],
      ),
    );
  }
}
