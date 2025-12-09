import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roomies/widgets/custom_button.dart';

void main() {
  // Test dla wariantu Primary (wypełniony)
  testWidgets('CustomButton (Primary) wyświetla tekst i reaguje na tap', (WidgetTester tester) async {
    bool wasPressed = false;

    // 1. Budujemy widget wewnątrz MaterialApp (potrzebne do stylów i nawigacji)
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: CustomButton(
          text: 'Zaloguj się',
          isPrimary: true,
          onPressed: () {
            wasPressed = true;
          },
        ),
      ),
    ));

    // 2. Szukamy widgetu po tekście
    expect(find.text('Zaloguj się'), findsOneWidget);

    // 3. Sprawdzamy, czy pod spodem jest ElevatedButton (dla isPrimary: true)
    expect(find.byType(ElevatedButton), findsOneWidget);
    expect(find.byType(OutlinedButton), findsNothing);

    // 4. Symulujemy kliknięcie
    await tester.tap(find.byType(CustomButton));
    
    // Wymuszamy przerysowanie (jeśli byłyby animacje)
    await tester.pump(); 

    // 5. Weryfikujemy, czy funkcja została wywołana
    expect(wasPressed, true);
  });

  // Test dla wariantu Secondary (konturowy)
  testWidgets('CustomButton (Secondary) jest typu OutlinedButton', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: CustomButton(
          text: 'Anuluj',
          isPrimary: false, // Ważne: false
          onPressed: () {},
        ),
      ),
    ));

    expect(find.text('Anuluj'), findsOneWidget);
    
    // Sprawdzamy, czy tym razem jest to OutlinedButton
    expect(find.byType(OutlinedButton), findsOneWidget);
    expect(find.byType(ElevatedButton), findsNothing);
  });
}