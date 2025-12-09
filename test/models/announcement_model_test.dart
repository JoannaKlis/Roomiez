import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// Pamiętaj o poprawnej nazwie pakietu (tu: roomiez)
import 'package:roomies/models/announcement_model.dart'; 

void main() {
  group('Announcement Model Test', () {
    final DateTime testDate = DateTime(2025, 11, 15);
    final Timestamp testTimestamp = Timestamp.fromDate(testDate);

    final Map<String, dynamic> testMap = {
      'title': 'Impreza w sobotę',
      'body': 'Zapraszam wszystkich do salonu!',
      'groupId': 'group123',
      'createdById': 'user99',
      'createdByName': 'Marek',
      'createdAt': testTimestamp,
      'imageUrls': ['img1.jpg', 'img2.jpg'],
    };

    final Announcement testAnnouncement = Announcement(
      id: 'ann1',
      title: 'Impreza w sobotę',
      body: 'Zapraszam wszystkich do salonu!',
      groupId: 'group123',
      createdById: 'user99',
      createdByName: 'Marek',
      createdAt: testDate,
      imageUrls: ['img1.jpg', 'img2.jpg'],
    );

    test('fromMap powinien poprawnie stworzyć obiekt (w tym listę stringów)', () {
      final result = Announcement.fromMap(testMap, 'ann1');

      expect(result.id, 'ann1');
      expect(result.title, 'Impreza w sobotę');
      expect(result.imageUrls, isA<List<String>>());
      expect(result.imageUrls.length, 2);
      expect(result.imageUrls.first, 'img1.jpg');
      expect(result.createdAt, testDate);
    });

    test('fromMap powinien obsłużyć brak listy zdjęć (null safety)', () {
      final Map<String, dynamic> mapWithoutImages = {
        ...testMap,
        'imageUrls': null, // Symulujemy brak pola lub null
      };

      final result = Announcement.fromMap(mapWithoutImages, 'ann2');

      expect(result.imageUrls, isEmpty); // Powinna być pusta lista, nie null
    });

    test('toMap powinien zwrócić poprawną mapę', () {
      final mapResult = testAnnouncement.toMap();

      expect(mapResult['title'], 'Impreza w sobotę');
      expect(mapResult['imageUrls'], ['img1.jpg', 'img2.jpg']);
      expect(mapResult['createdAt'], testDate);
    });
  });
}