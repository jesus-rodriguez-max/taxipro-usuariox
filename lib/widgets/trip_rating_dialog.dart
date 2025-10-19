import 'package:flutter/material.dart';

class TripRatingDialog extends StatefulWidget {
  final String driverName;
  final Function(double rating, String comment) onSubmit;

  const TripRatingDialog({super.key, required this.driverName, required this.onSubmit});

  @override
  State<TripRatingDialog> createState() => _TripRatingDialogState();
}

class _TripRatingDialogState extends State<TripRatingDialog> {
  double _rating = 5.0;
  final _commentController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Califica a ${widget.driverName}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('¿Cómo estuvo tu viaje?'),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return IconButton(
                onPressed: () {
                  setState(() {
                    _rating = index + 1.0;
                  });
                },
                icon: Icon(
                  index < _rating ? Icons.star : Icons.star_border,
                  color: Theme.of(context).colorScheme.secondary, // plata
                  size: 35,
                ),
              );
            }),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _commentController,
            decoration: const InputDecoration(
              labelText: 'Deja un comentario (opcional)',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Omitir'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onSubmit(_rating, _commentController.text);
            Navigator.of(context).pop();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
          ),
          child: const Text('Enviar Calificación', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
