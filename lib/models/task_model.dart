import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a task assigned to a user
class Task {
  final String id;
  final String title;
  final String assignedToId;
  final String assignedToName;
  final String groupId;
  bool isDone;
  final DateTime dueDate;
  final DateTime? completedAt;

  Task({
    required this.id,
    required this.title,
    required this.assignedToId,
    required this.assignedToName,
    required this.groupId,
    required this.isDone,
    required this.dueDate,
    this.completedAt,
  });

  /// Create from Firestore document
  factory Task.fromMap(Map<String, dynamic> data, String documentId) {
    DateTime due;
    final raw = data['dueDate'];
    if (raw == null) {
      due = DateTime.now();
    } else if (raw is Timestamp) {
      due = raw.toDate();
    } else if (raw is DateTime) {
      due = raw;
    } else if (raw is String) {
      try {
        due = DateTime.parse(raw);
      } catch (_) {
        due = DateTime.now();
      }
    } else {
      due = DateTime.now();
    }

    final title = (data['title'] != null) ? data['title'].toString() : '';
    final assignedToId = (data['assignedToId'] != null) ? data['assignedToId'].toString() : '';
    final assignedToName = (data['assignedToName'] != null) ? data['assignedToName'].toString() : '';
    final groupId = (data['groupId'] != null) ? data['groupId'].toString() : '';

    bool isDone = false;
    final rawIsDone = data['isDone'];
    if (rawIsDone is bool) {
      isDone = rawIsDone;
    } else if (rawIsDone is int) {
      isDone = rawIsDone != 0;
    } else if (rawIsDone is String) {
      isDone = rawIsDone.toLowerCase() == 'true';
    }

    DateTime? completedAt;
    final rawCompletedAt = data['completedAt'];
    if (rawCompletedAt is Timestamp) {
      completedAt = rawCompletedAt.toDate();
    } else if (rawCompletedAt is DateTime) {
      completedAt = rawCompletedAt;
    } else if (rawCompletedAt is String) {
      try {
        completedAt = DateTime.parse(rawCompletedAt);
      } catch (_) {
        completedAt = null;
      }
    }

    return Task(
      id: documentId,
      title: title,
      assignedToId: assignedToId,
      assignedToName: assignedToName,
      groupId: groupId,
      isDone: isDone,
      dueDate: due,
      completedAt: completedAt,
    );
  }

  /// Convert to Firestore format
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'assignedToId': assignedToId,
      'assignedToName': assignedToName,
      'groupId': groupId,
      'isDone': isDone,
      'dueDate': Timestamp.fromDate(dueDate),
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
    };
  }
}