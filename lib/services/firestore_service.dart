import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task_model.dart';
import '../models/expense_history_item.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // stała do pobierania danych dla 'default_group'
  // w przyszłości zmienić na dynamiczne pobieranie id grupy zalogowanego użytkownika
  static const String _defaultGroupId = 'default_group'; 

  // pobieranie użytkowników z tej samej grupy
  Future<List<Map<String, String>>> getCurrentApartmentUsers() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('groupId', isEqualTo: _defaultGroupId)
          .get();

      return snapshot.docs.map((doc) => {
        'id': doc.id,
        'name': '${doc.data()['firstName']} ${doc.data()['lastName']}',
      }).toList();
    } catch (e) {
      print('Error fetching users: $e');
      return [];
    }
  }

  // dodawanie nowego zadania
  Future<void> addTask(Task task) async {
    await _firestore.collection('tasks').add(task.toMap());
  }

  // pobieranie zadań dla domyślnej grupy
  Stream<List<Task>> getTasks() {
    return _firestore
        .collection('tasks')
        .where('groupId', isEqualTo: _defaultGroupId)
        .orderBy('dueDate', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Task.fromMap(doc.data(), doc.id)).toList();
    });
  }

  // aktualizacja statusu zadania
  Future<void> updateTaskStatus(String taskId, bool isDone) async {
    await _firestore.collection('tasks').doc(taskId).update({'isDone': isDone});
  }

  // dodawanie nowego wydatku
  Future<void> addExpense(ExpenseHistoryItem expense) async {
    await _firestore.collection('expenses').add(expense.toMap());
  }

  // pobieranie wydatków dla domyślnej grupy
  Stream<List<ExpenseHistoryItem>> getExpenses() {
    return _firestore
        .collection('expenses')
        .where('groupId', isEqualTo: _defaultGroupId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => ExpenseHistoryItem.fromMap(doc.data(), doc.id)).toList();
    });
  }
}