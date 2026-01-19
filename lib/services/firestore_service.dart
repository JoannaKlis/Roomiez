import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/task_model.dart';
import '../models/expense_history_item.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:roomies/utils/user_roles.dart';
import '../models/announcement_model.dart';
import '../utils/split_bill_logic.dart';

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

  // wyjście użytkownika z grupy - usuwa wszystkie powiązane wydatki i zadania
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

    debugPrint('User $userId exiting group $groupId');

    // Usuń lub zaktualizuj WSZYSTKIE wydatki związane z użytkownikiem
    final expensesSnapshot = await _firestore.collection('expenses')
        .where('groupId', isEqualTo: groupId)
        .get();
    
    int deletedExpenses = 0;
    int updatedExpenses = 0;
    
    for (var doc in expensesSnapshot.docs) {
      final data = doc.data();
      final payerId = data['payerId'] as String?;
      final participantsIds = List<String>.from(data['participantsIds'] ?? []);
      
      // Sprawdź czy użytkownik jest powiązany z tym wydatkiem
      bool isPayerOrParticipant = (payerId == userId) || participantsIds.contains(userId);
      
      if (!isPayerOrParticipant) {
        continue; // Użytkownik nie jest związany z tym wydatkiem
      }
      
      // Policz liczbę unikalnych osób w wydatku (payer + particpants)
      Set<String> allParticipants = {payerId ?? '', ...participantsIds};
      allParticipants.remove(''); // Usuń pusty string jeśli był
      
      // REGUŁA 1: Jeśli wydatek był tylko między 2 osobami - usuń go całkowicie
      if (allParticipants.length == 2 && isPayerOrParticipant) {
        batch.delete(doc.reference);
        deletedExpenses++;
        debugPrint('Deleted expense: ${doc.id} - it was between 2 people (will settle outside app)');
      }
      // REGUŁA 2: Jeśli wydatek miał 3+ osoby
      else if (allParticipants.length >= 3) {
        if (payerId == userId) {
          // Jeśli użytkownik był payerId, usuń wydatek (on płacił i wychodzi)
          batch.delete(doc.reference);
          deletedExpenses++;
          debugPrint('Deleted expense: ${doc.id} - user was payer and group has ${allParticipants.length} people');
        } else if (participantsIds.contains(userId)) {
          // Jeśli użytkownik był tylko uczestnikiem - usuń go z listy i przelicz
          participantsIds.remove(userId);
          batch.update(doc.reference, {
            'participantsIds': participantsIds,
          });
          updatedExpenses++;
          debugPrint('Updated expense: ${doc.id} - removed user $userId from participants (${participantsIds.length} people remain)');
        }
      }
    }
    debugPrint('Deleted $deletedExpenses expenses, updated $updatedExpenses expenses for user $userId');

    // Teraz przelicz BALANSY GRUPY od nowa na podstawie zaktualizowanych wydatków
    // Pobierz wszystkie wydatki (już zaktualizowane)
    final updatedExpensesSnapshot = await _firestore.collection('expenses')
        .where('groupId', isEqualTo: groupId)
        .get();
    
    final remainingExpenses = updatedExpensesSnapshot.docs
        .map((doc) => ExpenseHistoryItem.fromMap(doc.data(), doc.id))
        .toList();

    // Pobierz pozostałych użytkowników grupy (bez odchodzącego)
    final remainingUsersSnapshot = await _firestore.collection('users')
        .where('groupId', isEqualTo: groupId)
        .get();
    
    final remainingUserIds = remainingUsersSnapshot.docs
        .map((d) => d.id)
        .where((id) => id != userId)
        .toList();

    // Przelicz balansy od nowa
    Map<String, double> newBalances = {};
    for (var uid in remainingUserIds) {
      newBalances[uid] = 0.0;
    }

    for (var expense in remainingExpenses) {
      if (expense.participantsIds.isEmpty) continue;
      double splitAmount = expense.amount / expense.participantsIds.length;
      
      if (remainingUserIds.contains(expense.payerId)) {
        newBalances[expense.payerId] = (newBalances[expense.payerId] ?? 0.0) + expense.amount;
      }
      
      for (var participantId in expense.participantsIds) {
        if (remainingUserIds.contains(participantId)) {
          newBalances[participantId] = (newBalances[participantId] ?? 0.0) - splitAmount;
        }
      }
    }

    debugPrint('Recalculated balances: $newBalances');
    
    // Zaktualizuj balansy w grupie z prawidłowo przeliczonymi wartościami
    batch.update(
      _firestore.collection('groups').doc(groupId),
      {'balances': newBalances},
    );
    debugPrint('Updated balances for group $groupId with recalculated values');
    
    final tasksSnapshot = await _firestore.collection('tasks')
        .where('groupId', isEqualTo: groupId)
        .where('assignedTo', isEqualTo: userId)
        .get();
    
    int deletedTasks = 0;
    for (var doc in tasksSnapshot.docs) {
      batch.delete(doc.reference);
      deletedTasks++;
    }
    debugPrint('Deleted $deletedTasks tasks for user $userId');

    // Usuń wszystkie prośby rozliczeniowe dotyczące użytkownika
    final settlementsSnapshot = await _firestore.collection('settlements')
        .where('groupId', isEqualTo: groupId)
        .get();
    
    int deletedSettlements = 0;
    for (var doc in settlementsSnapshot.docs) {
      final data = doc.data();
      final fromUserId = data['fromUserId'] as String?;
      final toUserId = data['toUserId'] as String?;
      if (fromUserId == userId || toUserId == userId) {
        batch.delete(doc.reference);
        deletedSettlements++;
      }
    }
    debugPrint('Deleted $deletedSettlements settlements for user $userId');

    if (usersInGroup.size == 1) {
      batch.delete(_firestore.collection('groups').doc(groupId));
      final collectionsToDelete = ['announcements', 'shopping_items'];
      for (var col in collectionsToDelete) {
        final snapshot = await _firestore.collection(col)
        .where('groupId', isEqualTo: groupId)
        .get();
        for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
        }
      }
      debugPrint('Group $groupId deleted (user was the last member)');
    } 
    else if(currentUserRole == UserRole.apartmentManager){ 
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
        debugPrint('Transferred apartment manager role to $newManagerId');
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
    debugPrint('User $userId successfully exited group $groupId');
    } catch (e) {
      debugPrint("userExitsAGroup error: $e");
      return;
    }
  }

  // Pobierz saldo użytkownika i niezakończone taski do wyświetlenia w dialogu exit
  Future<Map<String, dynamic>> getExitSummary() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      final groupId = await getCurrentUserGroupId();
      
      if (userId == null || groupId.isEmpty) {
        return {'debtAmount': 0.0, 'incompleteTasks': 0, 'isManager': false};
      }

      // Pobierz role użytkownika
      final currentRole = await getCurrentUserRole();
      final isManager = currentRole == UserRole.apartmentManager;

      // Pobierz saldo z grupy
      double debtAmount = 0.0;
      final groupDoc = await _firestore.collection('groups').doc(groupId).get();
      if (groupDoc.exists && groupDoc.data()!.containsKey('balances')) {
        final balances = groupDoc.data()!['balances'] as Map<String, dynamic>;
        if (balances.containsKey(userId)) {
          final userBalance = (balances[userId] as num).toDouble();
          // Jeśli saldo jest ujemne = dług
          if (userBalance < 0) {
            debtAmount = userBalance.abs();
          }
        }
      }

      debugPrint('User $userId debt: $debtAmount PLN');

      // Liczenie niezakończonych zadań
      final tasksSnapshot = await _firestore.collection('tasks')
          .where('groupId', isEqualTo: groupId)
          .where('assignedTo', isEqualTo: userId)
          .get();

      final incompleteTasks = tasksSnapshot.docs.length;
      debugPrint('Incomplete tasks count: $incompleteTasks');

      return {
        'debtAmount': debtAmount,
        'incompleteTasks': incompleteTasks,
        'isManager': isManager,
      };
    } catch (e) {
      debugPrint('getExitSummary error: $e');
      return {'debtAmount': 0.0, 'incompleteTasks': 0, 'isManager': false};
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

  Future<void> deleteTask(String taskId) async {
    await _firestore.collection('tasks').doc(taskId).delete();
  }

  // dodawanie nowego wydatku
  // 1. Zmodyfikowane dodawanie (Transakcja)
  Future<void> addExpense(ExpenseHistoryItem expense) async {
    // Validate expense amount limit
    if (expense.amount > 100000) {
      throw Exception('Expense amount cannot exceed 100,000 PLN.');
    }

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

  // !!! NOWE: POBIERANIE Z PAGINACJĄ (PARTIAMI) !!!
  Future<List<DocumentSnapshot>> getExpensesPaged({
    required int limit,
    DocumentSnapshot? startAfter,
    bool? isSettled,
  }) async {
    final groupId = await getCurrentUserGroupId();
    
    Query query = _firestore
        .collection('expenses')
        .where('groupId', isEqualTo: groupId)
        .orderBy('date', descending: true);

    // Filtrowanie isSettled
    if (isSettled != null) {
       query = query.where('isSettled', isEqualTo: isSettled);
    }
    
    // Paginacja
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }
    
    query = query.limit(limit);

    final snapshot = await query.get();
    return snapshot.docs;
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

  // Pobieranie wszystkich użytkowników
  Stream<List<Map<String, dynamic>>> getAllUsersStream() {
    return _firestore.collection('users').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['uid'] = doc.id;
        // Pełne imię
        data['name'] =
            '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}'.trim();
        if (data['name'].isEmpty) data['name'] = 'Unknown User';
        // Domyślna rola
        if (!data.containsKey('role')) data['role'] = UserRole.user;
        return data;
      }).toList();
    });
  }

  // Edycja danych użytkownika (admin)
  Future<void> updateUserData(
    String userId, {
    String? firstName,
    String? lastName,
    String? email,
  }) async {
    Map<String, dynamic> updates = {};

    if (firstName != null) updates['firstName'] = firstName;
    if (lastName != null) updates['lastName'] = lastName;
    if (email != null) updates['email'] = email;

    if (updates.isEmpty) return;

    await _firestore.collection('users').doc(userId).update(updates);
  }

  // Usuwanie użytkownika z bazy danych (admin), ale nie konta Firebase Auth
  Future<void> deleteUser(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return;

      final userData = userDoc.data()!;
      final userGroupId = userData['groupId'];
      final userRole = userData['role'];

      // Przypisanie roli apartment manager innemu userowi po usunieciu
      if (userRole == UserRole.apartmentManager &&
          userGroupId != 'default_group') {
        final otherMembers = await _firestore
            .collection('users')
            .where('groupId', isEqualTo: userGroupId)
            .get();

        final others = otherMembers.docs.where((d) => d.id != userId).toList();
        if (others.isNotEmpty) {
          others.shuffle();
          await _firestore.collection('users').doc(others.first.id).update({
            'role': UserRole.apartmentManager,
          });
        }
      }

      // Usunięcie wszystkich powiązanych danych usera
      final batch = _firestore.batch();

      // Usunięcie zadań utworzonych przez usera
      final tasks = await _firestore
          .collection('tasks')
          .where('assignedTo', isEqualTo: userId)
          .get();
      for (var doc in tasks.docs) {
        batch.delete(doc.reference);
      }

      // Usunięcie ogłoszeń utworzonych przez usera
      final announcements = await _firestore
          .collection('announcements')
          .where('createdById', isEqualTo: userId)
          .get();
      for (var doc in announcements.docs) {
        batch.delete(doc.reference);
      }

      // Usunięcie dokumentu usera
      batch.delete(_firestore.collection('users').doc(userId));

      await batch.commit();
      debugPrint('User $userId deleted successfully');
    } catch (e) {
      debugPrint('deleteUser error: $e');
      rethrow;
    }
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
    // Calculate and store a snapshot of the current debt between users so
    // subsequent changes to balances/expenses won't mutate this request.
    double snapshotAmount = amount;
    try {
      final groupDoc = await _firestore.collection('groups').doc(groupId).get();
      if (groupDoc.exists && groupDoc.data()!.containsKey('balances')) {
        final Map<String, dynamic> raw = groupDoc.data()!['balances'];
        final Map<String, double> balances = {};
        raw.forEach((k, v) => balances[k] = (v as num).toDouble());
        // compute debts from balances
        final debts = await Future.value();
        // use SplitBillLogic without importing here to avoid circulars: compute inline minimal
        // Instead, try to compute matching balance directly: the debt from fromUserId to toUserId
        if (fromUserId != null && balances.containsKey(fromUserId) && balances.containsKey(toUserId)) {
          // The simplest snapshot is the difference between creditor and debtor signs
          // If fromUser owes (negative balance) and toUser is creditor (positive), the amount owed
          final fromBal = balances[fromUserId] ?? 0.0;
          final toBal = balances[toUserId] ?? 0.0;
          // estimate owed amount as min(abs(fromBal), toBal) when signs match
          if (fromBal < 0 && toBal > 0) {
            snapshotAmount = (fromBal.abs() < toBal) ? fromBal.abs() : toBal;
          } else {
            // fallback to provided amount
            snapshotAmount = amount;
          }
        }
      }
    } catch (e) {
      // ignore snapshot calculation errors and fall back to provided amount
      snapshotAmount = amount;
    }

    await _firestore.collection('settlements').add({
      'fromUserId': fromUserId, // Who is paying
      'toUserId': toUserId,     // Who should confirm
      'amount': amount,
      'snapshotAmount': snapshotAmount,
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

  // --- APARTMENT MANAGER PERMISSIONS ---

  // Sprawdzenie czy użytkownik jest apartment managerem grupy
  Future<bool> isCurrentUserApartmentManager(String groupId) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return false;

      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return false;

      final userRole = userDoc.data()?['role'].toString() ?? '';
      final userGroupId = userDoc.data()?['groupId'].toString() ?? '';

      return userRole == UserRole.apartmentManager && userGroupId == groupId;
    } catch (e) {
      debugPrint('isCurrentUserApartmentManager error: $e');
      return false;
    }
  }

  // Zmiana nazwy mieszkania (tylko apartment manager)
  Future<void> updateApartmentName(String groupId, String newName) async {
    try {
      final isManager = await isCurrentUserApartmentManager(groupId);
      if (!isManager) {
        throw Exception('Only apartment manager can change the name');
      }

      await _firestore.collection('groups').doc(groupId).update({
        'name': newName,
      });
    } catch (e) {
      debugPrint('updateApartmentName error: $e');
      rethrow;
    }
  }

  // Usunięcie członka z mieszkania (tylko apartment manager)
  Future<void> removeApartmentMember(String groupId, String userId) async {
    try {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      final isManager = await isCurrentUserApartmentManager(groupId);

      if (!isManager) {
        throw Exception('Only apartment manager can remove members');
      }

      if (currentUserId == userId) {
        throw Exception('You cannot remove yourself from the apartment');
      }

      // Przeniesienie użytkownika do domyślnej grupy
      await _firestore.collection('users').doc(userId).update({
        'groupId': 'default_group',
        'role': UserRole.user,
      });
    } catch (e) {
      debugPrint('removeApartmentMember error: $e');
      rethrow;
    }
  }

  // Przekazanie roli managera innemu członkowi (tylko obecny manager)
  Future<void> transferManagerRole(String groupId, String newManagerId) async {
    try {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      final isManager = await isCurrentUserApartmentManager(groupId);

      if (!isManager) {
        throw Exception('Only current apartment manager can transfer the role');
      }

      if (currentUserId == newManagerId) {
        throw Exception('You are already the apartment manager');
      }

      // Sprawdzenie czy nowy manager należy do grupy
      final newManagerDoc = await _firestore.collection('users').doc(newManagerId).get();
      if (!newManagerDoc.exists) {
        throw Exception('User does not exist');
      }

      final newManagerGroupId = newManagerDoc.data()?['groupId'].toString() ?? '';
      if (newManagerGroupId != groupId) {
        throw Exception('User is not a member of this apartment');
      }

      final batch = _firestore.batch();

      // Obecny manager staje się zwykłym użytkownikiem
      batch.update(
        _firestore.collection('users').doc(currentUserId),
        {'role': UserRole.user},
      );

      // Nowy manager otrzymuje rolę
      batch.update(
        _firestore.collection('users').doc(newManagerId),
        {'role': UserRole.apartmentManager},
      );

      await batch.commit();
    } catch (e) {
      debugPrint('transferManagerRole error: $e');
      rethrow;
    }
  }

}