import 'package:flutter/material.dart';

class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textStyleQ = Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700);
    final textStyleA = Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Preguntas Frecuentes'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('¿Taxi Pro es una aplicación legal?', style: textStyleQ),
          const SizedBox(height: 6),
          Text('Sí. Taxi Pro es la única plataforma 100% legal en San Luis Potosí. Todos los conductores están verificados y cuentan con licencia oficial de taxi.', style: textStyleA),
          const SizedBox(height: 16),

          Text('¿Cuál es el costo de un viaje?', style: textStyleQ),
          const SizedBox(height: 6),
          Text('El viaje se cobra según el taxímetro oficial del reglamento municipal. Aplica un banderazo (según horario) y el costo se incrementa por tiempo o distancia, lo que ocurra primero.', style: textStyleA),
          const SizedBox(height: 16),

          Text('¿Se puede facturar el viaje?', style: textStyleQ),
          const SizedBox(height: 6),
          Text('No. Taxi Pro no intermedia ni cobra comisiones. La transacción es directa entre usuario y chofer. Los choferes pueden emitir factura directa si así lo ofrecen.', style: textStyleA),
          const SizedBox(height: 16),

          Text('¿Puedo viajar con mascotas?', style: textStyleQ),
          const SizedBox(height: 6),
          Text('No. Por ahora no se permite viajar con mascotas en Taxi Pro.', style: textStyleA),
          const SizedBox(height: 16),

          Text('¿Cómo funciona el modo sin conexión?', style: textStyleQ),
          const SizedBox(height: 6),
          Text('Modo limitado sin conexión. La app enviará un SMS con tu origen y destino a TaxiPro. Recibirás por SMS el nombre del chofer, número de taxi, modelo, llegada estimada y costo aproximado. Pago solo en efectivo. Sin monitoreo de seguridad ni grabación.', style: textStyleA),
        ],
      ),
    );
  }
}
