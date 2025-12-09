import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:roomies/models/expense_history_item.dart';

void main() {
  group('ExpenseHistoryItem Model Test', () {
    final DateTime testDate = DateTime(2025, 12, 1);
    final Timestamp testTimestamp = Timestamp.fromDate(testDate);

    final Map<String, dynamic> testMap = {
      'description': 'Zakupy spożywcze',
      'payerId': 'p1',
      'amount': 45.50,
      'date': testTimestamp,
      'participantsIds': ['p1', 'p2'],
      'groupId': 'g1',
    };

    test('fromMap powinien poprawnie przetworzyć dane', () {
      final result = ExpenseHistoryItem.fromMap(testMap, 'expense1');

      expect(result.id, 'expense1');
      expect(result.amount, 45.50);
      expect(result.participantsIds, containsAll(['p1', 'p2']));
      expect(result.date, testDate);
    });

    test('fromMap powinien obsłużyć amount jako int (rzutowanie na double)', () {
      // Czasem baza zwraca liczbę całkowitą (np. 100), a model chce double
      final Map<String, dynamic> mapWithIntAmount = {
        ...testMap,
        'amount': 100, 
      };

      final result = ExpenseHistoryItem.fromMap(mapWithIntAmount, 'expense2');

      expect(result.amount, 100.0);
      expect(result.amount, isA<double>());
    });
  });
}