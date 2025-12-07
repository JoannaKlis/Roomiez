import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/task_model.dart';
import '../models/expense_history_item.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:roomies/utils/user_roles.dart';
import '../models/announcement_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // dynamiczne pobieranie id grupy zalogowanego użytkownika
  Future<String> getGroupName(String groupId) async {
    try {
      // pobieranie dokumentu z kolekcji 'groups' o podanym ID
      final groupDoc = await _firestore.collection('groups').doc(groupId).get();

      // sprawdzenie, czy dokument istnieje i zawiera pole 'name'
      if (groupDoc.exists && groupDoc.data()!.containsKey('name')) {
        return groupDoc.data()!['name'] as String;
      }

      return 'No group name';
    } catch (e) {
      print('Error fetching group name: $e');
      return 'Loading error';
    }
  }

  // pobieranie groupId aktualnie zalogowanego użytkownika
  Future<String> getCurrentUserGroupId() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;

      // pobieranie dokumentu użytkownika z kolekcji 'users'
      final userDoc = await _firestore.collection('users').doc(userId).get();

      // sprawdzenie, czy dokument istnieje i zawiera pole 'groupId'
      if (userDoc.exists && userDoc.data()!.containsKey('groupId')) {
        return userDoc.data()!['groupId'] as String;
      }

      // Jeśli użytkownik nie ma przypisanego groupId w dokumencie
      throw Exception(
          'User is not assigned to any group. Please create or join one.');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Error fetching user GroupID: ${e.toString()}');
    }
  }

  // pobieranie roli aktualnie zalogowanego użytkownika
  Future<String> getCurrentUserRole() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;

      if (userId == null) return UserRole.user;

      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (userDoc.exists && userDoc.data()!.containsKey('role')) {
        return userDoc.data()!['role'].toString() ?? UserRole.user;
      }

      return UserRole.user;
    } catch (e) {
      print('Error fetching user role: $e');
      return UserRole.user;
    }
  }

  Future<String> createNewGroup(String Name) async {
    try {
      final String userId = FirebaseAuth.instance.currentUser!.uid;
      var uuid = Uuid();
      String groupId;
      final snapshot = await _firestore.collection('groups').get();
      List groups = snapshot.docs.map((doc) => doc.id).toList();
      do {
        groupId = uuid.v4().substring(0, 6);
      } while (groups.contains(groupId));
      await _firestore.collection('groups').doc(groupId).set({
        'name': Name,
        'createdAt': FieldValue.serverTimestamp(), // Dodano timestamp dla admina
        'status': 'Active', // Dodano domyślny status dla admina
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
    try {
      final String userId = FirebaseAuth.instance.currentUser!.uid;
      final snapshot = await _firestore.collection('groups').get();
      List groups = snapshot.docs.map((doc) => doc.id).toList();
      if (!groups.contains(groupId)) {
        return false;
      }
      await _firestore.collection('users').doc(userId).update({
        'groupId': groupId,
        'role': 'Member', // Domyślna rola
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  // pobieranie użytkowników z tej samej grupy
  Future<List<Map<String, String>>> getCurrentApartmentUsers(
      String groupId) async {
    try {
      final groupId = await getCurrentUserGroupId();

      final snapshot = await _firestore
          .collection('users')
          .where('groupId', isEqualTo: groupId)
          .get();

      return snapshot.docs
          .map((doc) => {
                'id': doc.id,
                'name': '${doc.data()['firstName']} ${doc.data()['lastName']}',
              })
          .toList();
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
    return Stream.fromFuture(getCurrentUserGroupId()).asyncExpand((groupId) {
      return _firestore
          .collection('tasks')
          .where('groupId', isEqualTo: groupId)
          .orderBy('dueDate', descending: false)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => Task.fromMap(doc.data(), doc.id))
            .toList();
      });
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
    return Stream.fromFuture(getCurrentUserGroupId()).asyncExpand((groupId) {
      return _firestore
          .collection('expenses')
          .where('groupId', isEqualTo: groupId)
          .orderBy('date', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => ExpenseHistoryItem.fromMap(doc.data(), doc.id))
            .toList();
      });
    });
  }

  // POBIERANIE DANYCH PROFILU UŻYTKOWNIKA
  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    try {
      final String userId = FirebaseAuth.instance.currentUser!.uid;
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        return userDoc.data();
      }
      return null;
    } catch (e) {
      print('Error fetching user profile: $e');
      return null;
    }
  }

  // AKTUALIZACJA DANYCH PROFILU UŻYTKOWNIKA
  Future<String?> updateUserProfile(String firstName, String lastName) async {
    try {
      final String userId = FirebaseAuth.instance.currentUser!.uid;
      await _firestore.collection('users').doc(userId).update({
        'firstName': firstName,
        'lastName': lastName,
      });
      return null; // Oznacza sukces
    } catch (e) {
      // Obsługa błędów, np. brak uprawnień
      if (e is FirebaseException) {
        return e.message;
      }
      return 'An unexpected error occurred: ${e.toString()}';
    }
  }

  // ==============================
  // ANNOUNCEMENTS
  // ==============================

  Future<void> addAnnouncement(Announcement announcement) async {
    await _firestore.collection('announcements').add(announcement.toMap());
  }

  Stream<List<Announcement>> getAnnouncements() {
    return Stream.fromFuture(getCurrentUserGroupId()).asyncExpand((groupId) {
      return _firestore
          .collection('announcements')
          .where('groupId', isEqualTo: groupId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => Announcement.fromMap(doc.data(), doc.id))
            .toList();
      });
    });
  }

  // ==============================
  // SHOPPING LIST (NOWOŚĆ)
  // ==============================

  // 1. Dodaj produkt
  Future<void> addShoppingItem(String name, bool isPriority) async {
    final groupId = await getCurrentUserGroupId();
    final userId = FirebaseAuth.instance.currentUser?.uid;

    await _firestore.collection('shopping_items').add({
      'name': name,
      'isPriority': isPriority,
      'isBought': false,
      'groupId': groupId,
      'createdAt': FieldValue.serverTimestamp(),
      'addedBy': userId,
    });
  }

  // 2. Pobierz listę zakupów
  Stream<List<Map<String, dynamic>>> getShoppingList() {
    return Stream.fromFuture(getCurrentUserGroupId()).asyncExpand((groupId) {
      return _firestore
          .collection('shopping_items')
          .where('groupId', isEqualTo: groupId)
          .orderBy('isBought', descending: false) // Nie kupione na górze
          .orderBy('createdAt', descending: true) // Najnowsze na górze
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id; // Dodajemy ID dokumentu do mapy
          return data;
        }).toList();
      });
    });
  }

  // 3. Zmień status (Kupione/Niekupione)
  Future<void> toggleShoppingItemStatus(String itemId, bool currentStatus) async {
    await _firestore.collection('shopping_items').doc(itemId).update({
      'isBought': !currentStatus,
    });
  }

  // 4. Usuń produkt
  Future<void> deleteShoppingItem(String itemId) async {
    await _firestore.collection('shopping_items').doc(itemId).delete();
  }

  // ==============================
  // ADMIN FEATURES
  // ==============================

  // pobieranie wszytstkich grup (do admin dashboard)
  Stream<List<Map<String, dynamic>>> getAllGroupsStream() {
    return _firestore.collection('groups').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id; // ID grupy
        // liczenie członków grupy
        return data;
      }).toList();
    });
  }

  // zmiana statusu grupy (admin)
  Future<void> updateGroupStatus(String groupId, String newStatus) async {
    await _firestore.collection('groups').doc(groupId).update({
      'status': newStatus,
    });
  }

  // pobieranie listy członków grupy (admin)
  Stream<List<Map<String, dynamic>>> getGroupMembersStream(String groupId) {
    // groupId = ID
    return _firestore
        .collection('users')
        .where('groupId', isEqualTo: groupId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['uid'] = doc.id; // ID użytkownika
        // domyślna rola jeśli jej nie ma
        if (!data.containsKey('role')) data['role'] = UserRole.user;
        data['role'] = data['role'].toString();
        // imię + nazwisko
        if (!data.containsKey('name')) {
             data['name'] = '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}'.trim();
             if (data['name'].isEmpty) data['name'] = 'Unknown User';
        }
        return data;
      }).toList();
    });
  }

  // zmiana roli użytkownika (admin)
  Future<void> updateUserRole(String userId, bool makeAdmin) async {
    final String newRole = makeAdmin ? UserRole.administrator : UserRole.user;
    await _firestore.collection('users').doc(userId).update({
      'role': newRole,
    });
  }

  // usuwanie użytkownika z grupy (admin)
  Future<void> removeUserFromGroup(String userId) async {
    // groupId na null i rola na 'user'
    await _firestore.collection('users').doc(userId).update({
      'groupId': null, 
      'role': UserRole.user, 
    });
  }

  // usuwanie dokumentu użytkownika (admin)
  Future<void> deleteUserDocument(String userId) async {
    await _firestore.collection('users').doc(userId).delete();
  }

  // usuawanie grupy (admin)
  Future<void> deleteGroup(String groupId) async {
    // przeniesienie wszystkich użytkowników z tej grupy (lub groupId na null i rolę na 'user')
    final usersInGroup = await _firestore
        .collection('users')
        .where('groupId', isEqualTo: groupId)
        .get();

    final batch = _firestore.batch();
    for (var doc in usersInGroup.docs) {
      batch.update(doc.reference, {
        'groupId': null, 
        'role': UserRole.user, 
      });
    }

    // usuwanie dokumentu grupy
    batch.delete(_firestore.collection('groups').doc(groupId));

    await batch.commit();
  }
}