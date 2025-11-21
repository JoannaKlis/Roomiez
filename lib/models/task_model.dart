import 'package:cloud_firestore/cloud_firestore.dart';

// Prosty model reprezentujący zadanie do wykonania
class Task {
  final String id;
  final String title;
  final String assignedToId; // Kto jest przypisany (np. "Ana", "Martin")
  final String assignedToName; // Imię przypisanej osoby
  final String groupId; // ID grupy, do której należy zadanie
  bool isDone; // Status "zrobione" lub "niezrobione"
  final DateTime dueDate; // Np. "Tomorrow", "31.10.2025"

  Task({
    required this.id,
    required this.title,
    required this.assignedToId,
    required this.assignedToName,
    required this.groupId,
    required this.isDone,
    required this.dueDate,
  });


// metoda do tworzenia obiektu z firestore 
factory Task.fromMap(Map<String, dynamic> data, String documentId) {
    return Task(
      id: documentId,
      title: data['title'] as String,
      assignedToId: data['assignedToId'] as String,
      assignedToName: data['assignedToName'] as String,
      groupId: data['groupId'] as String,
      isDone: data['isDone'] as bool,
      // konwersja firestore Timestamp na DateTime
      dueDate: (data['dueDate'] as Timestamp).toDate(), 
    );
  }

  // metoda do mapowania obiektu na firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'assignedToId': assignedToId,
      'assignedToName': assignedToName,
      'groupId': groupId,
      'isDone': isDone,
      'dueDate': dueDate, 
    };
  }
}