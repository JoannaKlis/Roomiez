import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
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
      });
      await _firestore.collection('users').doc(userId).update({
        'role': UserRole.apartmentManager,
        'groupId': groupId,
      });
      return groupId;
    } catch (e) {
      debugPrint("createNewGroup error: $e");
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
      debugPrint("addUserToGroup error: $e");
      return false;
    }
  }

  // wyjście użytkownika z grupy
  Future<void> userExitsAGroup() async {
    try {
    final String userId = FirebaseAuth.instance.currentUser!.uid;
    final groupId = await getCurrentUserGroupId();
    final batch = _firestore.batch();
    final currentUserRole = await getCurrentUserRole();
    final usersInGroup = await _firestore
        .collection('users')
        .where('groupId', isEqualTo: groupId)
        .get();
    if (usersInGroup.size == 1) {
      batch.delete(_firestore.collection('groups').doc(groupId));

      // usuń wszystkie powiązane dokumenty
      final collectionsToDelete = ['announcements', 'tasks', 'shopping_items', 'expenses'];
      for (var col in collectionsToDelete) {
        final snapshot = await _firestore.collection(col)
        .where('groupId', isEqualTo: groupId)
        .get();
        for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
        }
      }
    } else if(currentUserRole == UserRole.apartmentManager){
        final otherUsers = usersInGroup.docs
          .where((doc) => doc.id != userId)
          .toList();
      if(otherUsers.isNotEmpty){
        otherUsers.shuffle();
        final newManagerId = otherUsers.first.id;
        batch.update(
          _firestore.collection('users').doc(newManagerId),
          {'role': UserRole.apartmentManager},
        );
      }
    }
    batch.update(
      _firestore.collection('users').doc(userId),
      {
        'groupId': 'default_group',
        'role': UserRole.user,
      },
    );
    await batch.commit();
    } catch (e) {
      debugPrint("userExitsAGroup error: $e");
      return;
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
    final updateData = <String, dynamic>{
      'isDone': isDone,
      'completedAt': isDone ? Timestamp.now() : FieldValue.serverTimestamp(),
    };
    if (!isDone) {
      updateData['completedAt'] = FieldValue.delete();
    }
    await _firestore.collection('tasks').doc(taskId).update(updateData);
  }

  // dodawanie nowego wydatku
  // 1. Zmodyfikowane dodawanie (Transakcja)
  Future<void> addExpense(ExpenseHistoryItem expense) async {
    final expenseRef = _firestore.collection('expenses').doc();
    final groupRef = _firestore.collection('groups').doc(expense.groupId);

    await _firestore.runTransaction((transaction) async {
      // A. Pobierz aktualne salda grupy
      final groupSnapshot = await transaction.get(groupRef);
      if (!groupSnapshot.exists) throw Exception("Group not found");

      Map<String, double> balances = {};
      if (groupSnapshot.data() != null && groupSnapshot.data()!.containsKey('balances')) {
        // Konwersja z Firebase Map<String, dynamic> na Map<String, double>
        Map<String, dynamic> raw = groupSnapshot.data()!['balances'];
        raw.forEach((k, v) => balances[k] = (v as num).toDouble());
      }

      // B. Oblicz wpływ nowego wydatku
      double splitAmount = expense.amount / expense.participantsIds.length;
      
      // Płatnik zyskuje (jest na plusie)
      balances[expense.payerId] = (balances[expense.payerId] ?? 0.0) + expense.amount;
      
      // Uczestnicy tracą (są na minusie)
      for (var uid in expense.participantsIds) {
        balances[uid] = (balances[uid] ?? 0.0) - splitAmount;
      }

      // C. Zapisz wszystko w bazie
      // Nowy wydatek
      transaction.set(expenseRef, expense.toMap());
      // Zaktualizowane salda w grupie
      transaction.update(groupRef, {'balances': balances});
    });
  }

  // 2. Potrzebne do pobierania salda na żywo
  Stream<DocumentSnapshot> getGroupStream(String groupId) {
    return _firestore.collection('groups').doc(groupId).snapshots();
  }

  // 3. MAGICZNA METODA NAPRAWCZA (Uruchom raz, by policzyć stare wydatki)
  Future<void> migrateOldExpensesToBalances() async {
    final groupId = await getCurrentUserGroupId();
    final expensesSnapshot = await _firestore.collection('expenses')
        .where('groupId', isEqualTo: groupId).get();
    
    // Pobieramy wszystkich użytkowników (żeby wiedzieć kogo liczyć)
    final usersSnapshot = await _firestore.collection('users')
        .where('groupId', isEqualTo: groupId).get();
    List<String> allUserIds = usersSnapshot.docs.map((d) => d.id).toList();

    // Liczymy "po staremu"
    Map<String, double> balances = {};
    for (var uid in allUserIds) balances[uid] = 0.0;

    for (var doc in expensesSnapshot.docs) {
      final data = doc.data();
      // Pomijamy 'repayment' (zwroty), bo one tylko zerują saldo, 
      // a w tym modelu salda zerują się same przy logice wpłat.
      // *UWAGA*: Jeśli Twoja logika "Repayment" to po prostu Expense, 
      // to musisz to uwzględnić. Zakładam standardowe wydatki.
      
      double amount = (data['amount'] as num).toDouble();
      String payerId = data['payerId'];
      List<String> participants = List<String>.from(data['participantsIds']);
      
      double split = amount / participants.length;
      balances[payerId] = (balances[payerId] ?? 0) + amount;
      for(var p in participants) {
        balances[p] = (balances[p] ?? 0) - split;
      }
    }

    // Zapisujemy wynik do grupy
    await _firestore.collection('groups').doc(groupId).update({
      'balances': balances
    });
    debugPrint("MIGRATION SUCCESS: Balances updated!");
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
    final docRef = await _firestore.collection('shopping_items').add({
      'name': name,
      'isPriority': isPriority,
      'isBought': false,
      'groupId': groupId,
      'createdAt': FieldValue.serverTimestamp(),
      'addedBy': userId,
    });
    debugPrint('addShoppingItem: added ${docRef.id} to group $groupId');
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
        debugPrint('getShoppingList: snapshot for group $groupId contains ${snapshot.docs.length} docs');
        return snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final map = Map<String, dynamic>.from(data);
          map['id'] = doc.id; // Dodajemy ID dokumentu do mapy
          return map;
        }).toList();
      });
    });
  }

  // 3. Zmień status (Kupione/Niekupione)
  Future<void> toggleShoppingItemStatus(String itemId, bool currentStatus) async {
    final updateData = <String, dynamic>{
      'isBought': !currentStatus,
      'boughtAt': !currentStatus ? Timestamp.now() : FieldValue.delete(),
    };
    await _firestore.collection('shopping_items').doc(itemId).update(updateData);
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
    // groupId nie na null tylko default_group i rola na 'user'
    await _firestore.collection('users').doc(userId).update({
      'groupId': "default_group", 
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
        'groupId': "default_group", 
        'role': UserRole.user, 
      });
    }

    // usuwanie dokumentu grupy
    batch.delete(_firestore.collection('groups').doc(groupId));

    await batch.commit();
  }

  // --- WKLEJ NA SAMYM DOLE KLASY FirestoreService ---

  // 1. Pobierz 2 ostatnie wydatki (do Home Screen)
  Stream<List<ExpenseHistoryItem>> getRecentExpensesStream(String groupId) {
    return _firestore.collection('expenses')
        .where('groupId', isEqualTo: groupId)
        .orderBy('date', descending: true)
        .limit(2)
        .snapshots()
        .map((s) => s.docs.map((d) => ExpenseHistoryItem.fromMap(d.data(), d.id)).toList());
  }

  // --- ROZLICZENIA (SETTLEMENTS - POCZEKALNIA) ---

  // 1. Wyślij prośbę o rozliczenie (User A klika "Settle Up")
  Future<void> requestSettlement(String toUserId, double amount) async {
    final fromUserId = FirebaseAuth.instance.currentUser?.uid;
    final groupId = await getCurrentUserGroupId();
    
    await _firestore.collection('settlements').add({
      'fromUserId': fromUserId, // Kto oddaje
      'toUserId': toUserId,     // Kto ma potwierdzić
      'amount': amount,
      'groupId': groupId,
      'status': 'pending',      // Oczekuje
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // 2. Potwierdź otrzymanie pieniędzy (User B klika "Confirm")
  Future<void> confirmSettlement(String settlementId, String fromUserId, double amount) async {
    final groupId = await getCurrentUserGroupId();
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    // A. Dodaj oficjalny wydatek "Zwrot", który wyzeruje dług w algorytmie
    final repayment = ExpenseHistoryItem(
      id: '', 
      description: 'Repayment (Zwrot)', 
      payerId: fromUserId,     // Płatnikiem jest ten, kto oddawał (User A)
      amount: amount, 
      date: DateTime.now(), 
      participantsIds: [currentUserId!], // Koszt ponosi tylko ten, kto odebrał (User B)
      groupId: groupId,
    );
    await addExpense(repayment);

    // B. Usuń prośbę z poczekalni
    await _firestore.collection('settlements').doc(settlementId).delete();
  }

  // 3. Odrzuć (User B klika "Nie dostałem")
  Future<void> denySettlement(String settlementId) async {
    await _firestore.collection('settlements').doc(settlementId).delete();
  }

  // 4. Pobierz listę oczekujących rozliczeń
  Stream<List<Map<String, dynamic>>> getPendingSettlementsStream() {
    return Stream.fromFuture(getCurrentUserGroupId()).asyncExpand((groupId) {
      return _firestore.collection('settlements')
          .where('groupId', isEqualTo: groupId)
          .snapshots()
          .map((s) => s.docs.map((d) {
             var data = d.data();
             data['id'] = d.id;
             return data;
          }).toList());
    });
  }

}