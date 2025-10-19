
import 'package:flutter/material.dart';

/// Un widget que permite al usuario seleccionar un método de pago (efectivo o tarjeta).
class PaymentMethodSelector extends StatefulWidget {
  /// Callback que se invoca cuando el método de pago cambia.
  final Function(String) onPaymentMethodSelected;

  const PaymentMethodSelector({
    Key? key,
    required this.onPaymentMethodSelected,
  }) : super(key: key);

  @override
  State<PaymentMethodSelector> createState() => _PaymentMethodSelectorState();
}

class _PaymentMethodSelectorState extends State<PaymentMethodSelector> {
  String _selectedPaymentMethod = 'cash'; // Valor por defecto

  @override
  void initState() {
    super.initState();
    // Notificar el valor inicial
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onPaymentMethodSelected(_selectedPaymentMethod);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Selecciona tu forma de pago',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildPaymentOption(
              context: context,
              label: 'Efectivo',
              icon: '💵',
              value: 'cash',
            ),
            _buildPaymentOption(
              context: context,
              label: 'Tarjeta',
              icon: '💳',
              value: 'card',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPaymentOption({
    required BuildContext context,
    required String label,
    required String icon,
    required String value,
  }) {
    final bool isSelected = _selectedPaymentMethod == value;
    final Color color = isSelected ? Theme.of(context).primaryColor : Colors.grey.shade300;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = value;
        });
        widget.onPaymentMethodSelected(value);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color, width: 2),
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isSelected ? Theme.of(context).primaryColor : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
