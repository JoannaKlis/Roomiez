import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roomies/widgets/custom_text_field.dart';

void main() {
  group('CustomTextField Widget Test', () {
    testWidgets('powinien wyświetlić etykietę i hint', (WidgetTester tester) async {
      // 1. Budujemy widget
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: CustomTextField(
            label: 'Adres Email',
            hint: 'wpisz email',
            isPassword: false,
          ),
        ),
      ));

      // 2. Sprawdzamy czy etykieta i hint są widoczne
      expect(find.text('Adres Email'), findsOneWidget);
      expect(find.text('wpisz email'), findsOneWidget);
    });

    testWidgets('powinien ukrywać tekst gdy isPassword jest true', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: CustomTextField(
            label: 'Hasło',
            hint: 'wpisz hasło',
            isPassword: true, // Ważne!
          ),
        ),
      ));

      // 3. Znajdujemy TextField i sprawdzamy właściwość obscureText
      final textFieldFinder = find.byType(TextField);
      final TextField textField = tester.widget(textFieldFinder);

      expect(textField.obscureText, true);
    });
  });
}