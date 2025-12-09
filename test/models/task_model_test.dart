import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// Upewnij się, że import wskazuje na właściwą ścieżkę w Twoim projekcie
// Zastąp 'roomiez' nazwą swojego pakietu, jeśli jest inna (sprawdź w pubspec.yaml)
import 'package:roomies/models/task_model.dart'; 

void main() {
  group('Task Model Test', () {
    // Przykładowe dane do testów
    final DateTime testDate = DateTime(2025, 10, 31);
    final Timestamp testTimestamp = Timestamp.fromDate(testDate);

    final Map<String, dynamic> testMap = {
      'title': 'Test Task',
      'assignedToId': 'user123',
      'assignedToName': 'Anna',
      'groupId': 'groupABC',
      'isDone': false,
      'dueDate': testTimestamp, // Symulujemy obiekt Timestamp z Firestore
    };

    final Task testTask = Task(
      id: 'task1',
      title: 'Test Task',
      assignedToId: 'user123',
      assignedToName: 'Anna',
      groupId: 'groupABC',
      isDone: false,
      dueDate: testDate,
    );

    test('powinien poprawnie stworzyć obiekt Task z mapy (fromMap)', () {
      // Act
      final result = Task.fromMap(testMap, 'task1');

      // Assert
      expect(result.id, 'task1');
      expect(result.title, 'Test Task');
      expect(result.assignedToId, 'user123');
      expect(result.assignedToName, 'Anna');
      expect(result.groupId, 'groupABC');
      expect(result.isDone, false);
      expect(result.dueDate, testDate);
    });

    test('powinien poprawnie zamienić obiekt Task na mapę (toMap)', () {
      // Act
      final mapResult = testTask.toMap();

      // Assert
      expect(mapResult['title'], 'Test Task');
      expect(mapResult['assignedToId'], 'user123');
      expect(mapResult['assignedToName'], 'Anna');
      expect(mapResult['groupId'], 'groupABC');
      expect(mapResult['isDone'], false);
      expect(mapResult['dueDate'], testDate); 
    });
    
    test('powinien zachować poprawność typów danych', () {
      final mapResult = testTask.toMap();
      expect(mapResult['isDone'], isA<bool>());
      expect(mapResult['dueDate'], isA<DateTime>());
    });
  });
}