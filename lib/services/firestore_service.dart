import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/task_model.dart';
import '../models/expense_history_item.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:roomies/utils/user_roles.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // stała do pobierania danych dla 'default_group'
  // w przyszłości zmienić na dynamiczne pobieranie id grupy zalogowanego użytkownika
  static const String _defaultGroupId = 'default_group'; 

  Future<String> createNewGroup(String Name) async {
    try {
      final String userId = FirebaseAuth.instance.currentUser!.uid;
      var uuid = Uuid();
      String groupId;
      final snapshot = await _firestore
          .collection('groups')
          .get();
      List groups = snapshot.docs.map((doc) => doc.id).toList();
      do{
        groupId = uuid.v4().substring(0,6);
      } while(groups.contains(groupId));
        await _firestore.collection('groups').doc(groupId).set({
          'name': Name, 
        });
        await _firestore.collection('users').doc(userId).update({
          'role': UserRole.apartmentManager,
          'groupId': groupId,
        });
    return groupId;
    } catch (e) {
      return "";
    }
  }


Future<bool> addUserToGroup(String groupId) async {
  try{
    final String userId = FirebaseAuth.instance.currentUser!.uid;
          final snapshot = await _firestore
          .collection('groups')
          .get();
      List groups = snapshot.docs.map((doc) => doc.id).toList();
      if(!groups.contains(groupId)){
          return false;
      }
        await _firestore.collection('users').doc(userId).update({
          'groupId': groupId,
        });
        return true;
    } catch (e) {
      return false;
    }
}


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