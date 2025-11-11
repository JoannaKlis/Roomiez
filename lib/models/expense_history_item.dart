// lib/models/expense_history_item.dart

// Prosty model reprezentujący pozycję na liście historii wydatków
class ExpenseHistoryItem {
  final String id;
  final String description;
  final String subtext; // Np. "You owe Martin"
  final double amount; // Np. +40.0, -2.25
  final String date;
  final String type; // 'lent', 'owed', 'settled'

  ExpenseHistoryItem({
    required this.id,
    required this.description,
    required this.subtext,
    required this.amount,
    required this.date,
    required this.type,
  });
}