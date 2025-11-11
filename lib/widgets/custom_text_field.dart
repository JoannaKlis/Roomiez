// lib/widgets/custom_text_field.dart

import 'package:flutter/material.dart';
import '../constants.dart';

class CustomTextField extends StatelessWidget {
  final String label;
  final String hint;
  final bool isPassword;
  final TextEditingController? controller;

  const CustomTextField({
    super.key,
    required this.label,
    required this.hint,
    this.isPassword = false,
    this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      // Kluczowa linia: Wyrównuje etykietę do lewej strony
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Etykieta (Label)
        Text(
          label,
          style: const TextStyle(
            color: textColor,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8.0), // Odstęp między etykietą a polem

        // 2. Pole tekstowe (TextField)
        TextField(
          controller: controller,
          obscureText: isPassword,
          decoration: InputDecoration(
            hintText: hint,
            // Nie musimy tutaj definiować kolorów, obramowania ani stylu podpowiedzi.
            // Ten widget AUTOMATYCZNIE pobierze styl 
            // z `inputDecorationTheme` zdefiniowanego w Twoim pliku `main.dart`.
          ),
        ),
      ],
    );
  }
}