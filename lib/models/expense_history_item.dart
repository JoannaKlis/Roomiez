import 'package:cloud_firestore/cloud_firestore.dart';

// Prosty model reprezentujący pozycję na liście historii wydatków
class ExpenseHistoryItem {
  final String id;
  final String description;
  final String payerId; // Kto zapłacił (ID użytkownika)
  final double amount; // Np. +40.0, -2.25
  final DateTime date;
  final List<String> participantsIds; // ID uczestników (również płatnika)
  final String groupId;  // ID grupy, do której należy wydatek
  final bool isSettled; // czy wydatek jest rozliczony (archiwalny)

  ExpenseHistoryItem({
    required this.id,
    required this.description,
    required this.payerId,
    required this.amount,
    required this.date,
    required this.participantsIds,
    required this.groupId,
    this.isSettled = false,
  });

  // metoda do tworzenia obiektu z firestore 
  factory ExpenseHistoryItem.fromMap(Map<String, dynamic> data, String documentId) {
    return ExpenseHistoryItem(
      id: documentId,
      description: data['description'] as String,
      payerId: data['payerId'] as String,
      amount: (data['amount'] as num).toDouble(),
      // konwersja firestore Timestamp na DateTime
      date: (data['date'] as Timestamp).toDate(),
      participantsIds: List<String>.from(data['participantsIds'] as List),
      groupId: data['groupId'] as String,
      isSettled: data.containsKey('isSettled') ? (data['isSettled'] as bool) : false,
    );
  }

  // metoda do mapowania obiektu na firestore
  Map<String, dynamic> toMap() {
    return {
      'description': description,
      'payerId': payerId,
      'amount': amount,
      'date': date,
      'participantsIds': participantsIds,
      'groupId': groupId,
      'isSettled': isSettled,
    };
  }
}