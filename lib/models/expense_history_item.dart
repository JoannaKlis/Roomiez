import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents an expense entry in the system
class ExpenseHistoryItem {
  final String id;
  final String description;
  final String payerId;
  final double amount;
  final DateTime date;
  final List<String> participantsIds;
  final String groupId;
  final bool isSettled;

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

  /// Create from Firestore document
  factory ExpenseHistoryItem.fromMap(Map<String, dynamic> data, String documentId) {
    return ExpenseHistoryItem(
      id: documentId,
      description: data['description'] as String,
      payerId: data['payerId'] as String,
      amount: (data['amount'] as num).toDouble(),
      date: (data['date'] as Timestamp).toDate(),
      participantsIds: List<String>.from(data['participantsIds'] as List),
      groupId: data['groupId'] as String,
      isSettled: data.containsKey('isSettled') ? (data['isSettled'] as bool) : false,
    );
  }

  /// Convert to Firestore format
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