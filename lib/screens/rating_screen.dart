import 'package:flutter/material.dart';

class RatingScreen extends StatefulWidget {
  const RatingScreen({super.key});

  @override
  State<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
  double _rating = 3.0; // Calificación inicial
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Califica tu Viaje'),
        automaticallyImplyLeading: false, // Ocultar botón de regreso
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              const Text(
                '¡Gracias por viajar con Taxipro!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                'Tu opinión nos ayuda a mejorar.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 40),
              // Widget de calificación por estrellas
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(5, (index) {
                    final starIndex = index + 1;
                    final isFilled = _rating >= starIndex;
                    return IconButton(
                      onPressed: () => setState(() => _rating = starIndex.toDouble()),
                      icon: Icon(
                        isFilled ? Icons.star : Icons.star_border,
                        color: const Color(0xFFC0C0C0),
                        size: 32,
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 40),
              // Campo de texto para comentarios
              TextField(
                controller: _commentController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Deja un comentario (opcional)...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              // Botón para enviar calificación
              ElevatedButton(
                onPressed: () {
                  // TODO: Lógica para guardar la calificación y el comentario
    // TODO: Enviar la calificación y el comentario a Firestore o tu backend.

    // Muestra un mensaje de agradecimiento y cierra la pantalla.
                  // Regresar a la pantalla principal del mapa
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Finalizar',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
