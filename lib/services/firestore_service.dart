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
      final String userId = FirebaseAuth.instance.currentUser!.uid; //pobranie id obecnie zalogowanego użytkownika
      var uuid = Uuid(); //funkcja generująca kod uuid przypisana do zmiennej uuid
      String groupId; //deklaracja zmiennej przechowującej id przyszło utworzonej grupy
      final snapshot = await _firestore.collection('groups').get(); //przechwycenie zawartości kolekcji 'groups'
      List groups = snapshot.docs.map((doc) => doc.id).toList(); //zebranie wszystkich id grup z bazy do listy groups
      do {
        groupId = uuid.v4().substring(0, 6); //generowanie kandydata na id nowej grupy złożonego z sześciu znaków poprzez przycięcie kodu uuid
      } while (groups.contains(groupId)); //generowanie id nowej grupy tak długo jak ten kod NIE jest unikalny - 
      //- Pętla przerwie się gdy wygenerowanego kodu nie będzie w bazie. To oznacza znalezienie unikalnego kodu który jest kodem nowej grupy 
      await _firestore.collection('groups').doc(groupId).set({ //tworzenie grupy o unikatowym id i nazwie przekazanej do funkcji
        'name': Name,
      });
      // ! osoba która tworzy grupę otrzymuje rolę managera 
      await _firestore.collection('users').doc(userId).update({
        'role': UserRole.apartmentManager,
        'groupId': groupId,
      });
      return groupId; //funkcja zwraca id nowej grupy, ponieważ udało się utworzyć grupę i zmodyfikować odpowiednio dane użytkownika
    } catch (e) {
      debugPrint("createNewGroup error: $e");
      return ""; //w razie wszelkich problemów przy tworzeniu grupy funkcja zwróci pusty String
    }
  }

  Future<bool> addUserToGroup(String groupId) async {
    try {
      final String userId = FirebaseAuth.instance.currentUser!.uid; //pobranie id obecnie zalogowanego użytkownika
      final snapshot = await _firestore.collection('groups').get(); //przechwycenie zawartości kolekcji 'groups'
      List groups = snapshot.docs.map((doc) => doc.id).toList(); //zebranie wszystkich id grup z bazy do listy groups
      if (!groups.contains(groupId)) { //jeśli nie ma w bazie grupy o podanym id, grupa nie istnieje i nie można dołączyć użytkownika
        return false; //funkcja zwraca false jeśli nie uda się dołączyć użytkownika do grupy
      }
      //jeśli nie zwrócono false to oznacza, że grupa o podanym id istenieje i należy je przypisać do groupId użytkownika
      //oraz nadać mu domyślną rolę (jako osoby która nie tworzy tylko dołącza do grupy) 
      await _firestore.collection('users').doc(userId).update({ 
        'groupId': groupId,
        'role': 'Member', // Domyślna rola
      });
      return true; //jeśli wszystko zwiazane z dołączeniem do grupy się powiodło funkcja zwraca true
    } catch (e) {
      debugPrint("addUserToGroup error: $e"); //w razie wszelkich problemów przy dołączaniu do grupy funkcja zwróci false
      return false;
    }
  }

  // wyjście użytkownika z grupy
  Future<void> userExitsAGroup() async {
    try {
    final String userId = FirebaseAuth.instance.currentUser!.uid; //pobranie id aktualnie zalogowanego użytkownika
    final groupId = await getCurrentUserGroupId(); //pobranie id grupy użytkownika
    final batch = _firestore.batch();
    final currentUserRole = await getCurrentUserRole(); //pobranie roli użytkownika
    final usersInGroup = await _firestore //zapytanie zwracające wszystkich użytkowników należących do grupy 
        .collection('users')
        .where('groupId', isEqualTo: groupId)
        .get();
     //jeśli użytkowink opuszczający grupę był jedynym jej członkiem to grupa jest usuwana    
    if (usersInGroup.size == 1) {
      batch.delete(_firestore.collection('groups').doc(groupId));

      // usuń wszystkie powiązane dokumenty
      final collectionsToDelete = ['announcements', 'tasks', 'shopping_items', 'expenses'];
      for (var col in collectionsToDelete) { //dla każdej w wymienionych powyżej kolekcji
        final snapshot = await _firestore.collection(col) //znajdź wszystkie dokumenty, które dotyczą usuwanej grupy i zapisz je w snapshot
        .where('groupId', isEqualTo: groupId)
        .get();
        for (var doc in snapshot.docs) { //usuń każdy dokument ze snapshot
        batch.delete(doc.reference);
        }
      }
    } 
    // jeśli była więcej niż jedna osoba w grupie i odchodzi z niej apartmentManager, należy przypisać te rolę innemu, losowemu użytkownikowi
    else if(currentUserRole == UserRole.apartmentManager){ 
        final otherUsers = usersInGroup.docs // zapytanie które przypisuje wszystkich członków grupy, poza usuwanym, do listy otherUsers
          .where((doc) => doc.id != userId)
          .toList();
      if(otherUsers.isNotEmpty){ //dodatkowe zabezpieczenie
        otherUsers.shuffle(); //przetasowanie kolejności uzytkowników z listy
        final newManagerId = otherUsers.first.id; //zapisanie id nowego managera
        batch.update(
          _firestore.collection('users').doc(newManagerId), //nadanie nowej roli managera wylosowanej osobie
          {'role': UserRole.apartmentManager},
        );
      }
    }
    //usunięty użytkownik otrzymuje domyślne id i rolę dla nieprzynależącego nigdzie użytkownika 
    batch.update(
      _firestore.collection('users').doc(userId),
      {
        'groupId': 'default_group',
        'role': UserRole.user,
      },
    );
    await batch.commit(); //wszystkie operacje są zatwierdzane i wykonywane w tym momencie 
    //batch chroni przed wykonaniem tylko części z koniecznych operacji (przypadki brzegowe)
    //np. nieoczekiwane zamknięcie aplikacji podczas przyznawania roli, czyli przed usunięciem użytkownika -> dwóch managerów w grupie
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
      // Nowy wydatek (upewnij się, że pole isSettled jest zapisane)
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

  // Ensure every expense document has the 'isSettled' field (default false)
  Future<void> ensureExpensesHaveIsSettled() async {
    final groupId = await getCurrentUserGroupId();
    final expensesSnapshot = await _firestore
        .collection('expenses')
        .where('groupId', isEqualTo: groupId)
        .get();

    final WriteBatch batch = _firestore.batch();
    for (var doc in expensesSnapshot.docs) {
      final data = doc.data();
      if (!data.containsKey('isSettled')) {
        batch.update(doc.reference, {'isSettled': false});
      }
    }

    if (batch != null) {
      await batch.commit();
    }
  }

  // Delete all expenses for the current group and reset balances
  Future<void> deleteAllExpenses() async {
    final groupId = await getCurrentUserGroupId();
    
    // Delete all expenses
    final expensesSnapshot = await _firestore
        .collection('expenses')
        .where('groupId', isEqualTo: groupId)
        .get();

    final WriteBatch batch = _firestore.batch();
    for (var doc in expensesSnapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();

    // Reset balances in group to zero
    final groupRef = _firestore.collection('groups').doc(groupId);
    final groupSnapshot = await groupRef.get();
    if (groupSnapshot.exists) {
      final users = await getCurrentApartmentUsers(groupId);
      Map<String, double> zeroBalances = {};
      for (var user in users) {
        zeroBalances[user['id']!] = 0.0;
      }
      await groupRef.update({'balances': zeroBalances});
    }

    debugPrint("ALL EXPENSES DELETED AND BALANCES RESET!");
  }

  // pobieranie wydatków dla domyślnej grupy
  // Filtrowanie po isSettled robimy po stronie klienta, aby uniknąć konieczności tworzenia indeksów w Firestore
  Stream<List<ExpenseHistoryItem>> getExpenses({bool? isSettled}) {
    return Stream.fromFuture(getCurrentUserGroupId()).asyncExpand((groupId) {
      var query = _firestore
          .collection('expenses')
          .where('groupId', isEqualTo: groupId)
          .orderBy('date', descending: true);

      return query.snapshots().map((snapshot) {
        var items = snapshot.docs
            .map((doc) => ExpenseHistoryItem.fromMap(doc.data(), doc.id))
            .toList();

        // Filtrowanie po stronie klienta
        if (isSettled != null) {
          items = items.where((item) => item.isSettled == isSettled).toList();
        }

        return items;
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

  // --- SETTLEMENTS ---

  // 1. Send settlement request (User A clicks "Settle Up")
  Future<void> requestSettlement(String toUserId, double amount) async {
    final fromUserId = FirebaseAuth.instance.currentUser?.uid;
    final groupId = await getCurrentUserGroupId();
    
    await _firestore.collection('settlements').add({
      'fromUserId': fromUserId, // Who is paying
      'toUserId': toUserId,     // Who should confirm
      'amount': amount,
      'groupId': groupId,
      'status': 'pending',      // Pending confirmation
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // 2. Confirm payment received (User B clicks "Confirm")
  Future<void> confirmSettlement(String settlementId, String fromUserId, double amount) async {
    final groupId = await getCurrentUserGroupId();
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    // A. Add settlement record that will zero out the debt in the algorithm
    // Mark as isSettled: true to appear in Archive
    final repayment = ExpenseHistoryItem(
      id: '', 
      description: 'Settlement', 
      payerId: fromUserId,     // Payment comes from the payer (User A)
      amount: amount, 
      date: DateTime.now(), 
      participantsIds: [currentUserId!], // Cost applied to recipient (User B)
      groupId: groupId,
      isSettled: true,  // Mark as settled
    );
    await addExpense(repayment);

    // B. Remove the settlement request from pending
    await _firestore.collection('settlements').doc(settlementId).delete();
  }

  // 3. Deny settlement request (User B clicks "Deny")
  Future<void> denySettlement(String settlementId) async {
    await _firestore.collection('settlements').doc(settlementId).delete();
  }

  // 4. Get list of pending settlements
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