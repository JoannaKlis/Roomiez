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

  /// Get group name by ID
  Future<String> getGroupName(String groupId) async {
    try {
      final groupDoc = await _firestore.collection('groups').doc(groupId).get();
      if (groupDoc.exists && groupDoc.data()!.containsKey('name')) {
        return groupDoc.data()!['name'] as String;
      }
      return 'No group name';
    } catch (e) {
      print('Error fetching group name: $e');
      return 'Loading error';
    }
  }

  Future<String> getCurrentUserGroupId() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (userDoc.exists && userDoc.data()!.containsKey('groupId')) {
        return userDoc.data()!['groupId'] as String;
      }

      throw Exception(
          'User is not assigned to any group. Please create or join one.');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Error fetching user GroupID: ${e.toString()}');
    }
  }

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

  /// Create a new apartment group
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

  /// Add current user to an existing group
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
        'role': UserRole.member,
      });
      return true;
    } catch (e) {
      debugPrint("addUserToGroup error: $e");
      return false;
    }
  }

  /// Current user exits group and recalculates balances
  Future<void> userExitsAGroup() async {
    try {
      final String userId = FirebaseAuth.instance.currentUser!.uid;
      final groupId = await getCurrentUserGroupId();
      final batch = _firestore.batch();
      final currentUserRole = await getCurrentUserRole();
      
      final usersInGroupSnapshot = await _firestore
          .collection('users')
          .where('groupId', isEqualTo: groupId)
          .get();
      
      final remainingUserIds = usersInGroupSnapshot.docs
          .map((d) => d.id)
          .where((id) => id != userId)
          .toList();

      debugPrint('User $userId exiting group $groupId');

      Map<String, double> newBalances = {};
      for (var uid in remainingUserIds) {
        newBalances[uid] = 0.0;
      }

      final expensesSnapshot = await _firestore.collection('expenses')
          .where('groupId', isEqualTo: groupId)
          .get();
      
      int deletedExpenses = 0;
      int updatedExpenses = 0;
      
      for (var doc in expensesSnapshot.docs) {
        final data = doc.data();
        final payerId = data['payerId'] as String;
        double amount = (data['amount'] as num).toDouble();
        List<String> participantsIds = List<String>.from(data['participantsIds'] ?? []);
        
        bool isPayer = payerId == userId;
        bool isParticipant = participantsIds.contains(userId);
        
        if (!isPayer && !isParticipant) {
          if (remainingUserIds.contains(payerId)) {
             newBalances[payerId] = (newBalances[payerId] ?? 0.0) + amount;
          }
          double splitAmount = amount / participantsIds.length;
          for (var p in participantsIds) {
            if (remainingUserIds.contains(p)) {
              newBalances[p] = (newBalances[p] ?? 0.0) - splitAmount;
            }
          }
          continue; 
        }
        
        Set<String> allUniquePeople = {payerId, ...participantsIds};
        
        if (allUniquePeople.length <= 2) {
          batch.delete(doc.reference);
          deletedExpenses++;
          debugPrint('Deleted expense: ${doc.id} - only 2 people involved');
        }
        else {
          if (isPayer) {
            batch.delete(doc.reference);
            deletedExpenses++;
            debugPrint('Deleted expense: ${doc.id} - payer left');
          } else {
            participantsIds.remove(userId);
            
            batch.update(doc.reference, {
              'participantsIds': participantsIds,
            });
            updatedExpenses++;

            if (participantsIds.isNotEmpty) {
              double newSplitAmount = amount / participantsIds.length;
              
              if (remainingUserIds.contains(payerId)) {
                newBalances[payerId] = (newBalances[payerId] ?? 0.0) + amount;
              }
              
              for (var p in participantsIds) {
                if (remainingUserIds.contains(p)) {
                  newBalances[p] = (newBalances[p] ?? 0.0) - newSplitAmount;
                }
              }
            }
            debugPrint('Updated expense: ${doc.id} - recalculated split: ${amount / participantsIds.length}');
          }
        }
      }

      debugPrint('Recalculated balances: $newBalances');
      
      batch.update(
        _firestore.collection('groups').doc(groupId),
        {'balances': newBalances},
      );
      
      final tasksSnapshot = await _firestore.collection('tasks')
          .where('groupId', isEqualTo: groupId)
          .where('assignedTo', isEqualTo: userId)
          .get();
      for (var doc in tasksSnapshot.docs) batch.delete(doc.reference);

      final settlementsSnapshot = await _firestore.collection('settlements')
          .where('groupId', isEqualTo: groupId)
          .get();
      for (var doc in settlementsSnapshot.docs) {
        final d = doc.data();
        if (d['fromUserId'] == userId || d['toUserId'] == userId) {
          batch.delete(doc.reference);
        }
      }

      if (usersInGroupSnapshot.docs.length == 1) {
        batch.delete(_firestore.collection('groups').doc(groupId));
      } 
      else if(currentUserRole == UserRole.apartmentManager){ 
        if(remainingUserIds.isNotEmpty){
          remainingUserIds.shuffle(); 
          final newManagerId = remainingUserIds.first;
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
      debugPrint('User $userId successfully exited group $groupId with CORRECT balances');

    } catch (e) {
      debugPrint("userExitsAGroup error: $e");
    }
  }

  /// Get summary data needed for exit dialog
  Future<Map<String, dynamic>> getExitSummary() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      final groupId = await getCurrentUserGroupId();
      
      if (userId == null || groupId.isEmpty) {
        return {
          'debtAmount': 0.0, 
          'incompleteTasks': 0, 
          'pendingSettlements': 0,
          'isManager': false
        };
      }

      final currentRole = await getCurrentUserRole();
      final isManager = currentRole == UserRole.apartmentManager;

      double debtAmount = 0.0;
      final groupDoc = await _firestore.collection('groups').doc(groupId).get();
      if (groupDoc.exists && groupDoc.data()!.containsKey('balances')) {
        final balances = groupDoc.data()!['balances'] as Map<String, dynamic>;
        if (balances.containsKey(userId)) {
          final userBalance = (balances[userId] as num).toDouble();
          if (userBalance < 0) {
            debtAmount = userBalance.abs();
          }
        }
      }

      final tasksSnapshot = await _firestore.collection('tasks')
          .where('groupId', isEqualTo: groupId)
          .where('assignedTo', isEqualTo: userId)
          .get();

      final incompleteTasks = tasksSnapshot.docs.length;

      final settlementsSnapshot = await _firestore.collection('settlements')
          .where('groupId', isEqualTo: groupId)
          .get();
      
      int pendingSettlements = 0;
      for (var doc in settlementsSnapshot.docs) {
        final data = doc.data();
        final fromUserId = data['fromUserId'];
        final toUserId = data['toUserId'];
        
        if (fromUserId == userId || toUserId == userId) {
          pendingSettlements++;
        }
      }
      
      debugPrint('User $userId summary: Debt: $debtAmount, Tasks: $incompleteTasks, Settlements: $pendingSettlements');

      return {
        'debtAmount': debtAmount,
        'incompleteTasks': incompleteTasks,
        'pendingSettlements': pendingSettlements,
        'isManager': isManager,
      };
    } catch (e) {
      debugPrint('getExitSummary error: $e');
      return {
        'debtAmount': 0.0, 
        'incompleteTasks': 0, 
        'pendingSettlements': 0, 
        'isManager': false
      };
    }
  }


  /// Get all apartment users in the group
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

  /// Add task to group
  Future<void> addTask(Task task) async {
    await _firestore.collection('tasks').add(task.toMap());
  }

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

  /// Update task completion status
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

  /// Delete task from group
  Future<void> deleteTask(String taskId) async {
    await _firestore.collection('tasks').doc(taskId).delete();
  }

  /// Add expense to group
  Future<void> addExpense(ExpenseHistoryItem expense) async {
    if (expense.amount > 100000) {
      throw Exception('Expense amount cannot exceed 100,000 PLN.');
    }

    final expenseRef = _firestore.collection('expenses').doc();
    final groupRef = _firestore.collection('groups').doc(expense.groupId);

    await _firestore.runTransaction((transaction) async {
      final groupSnapshot = await transaction.get(groupRef);
      if (!groupSnapshot.exists) throw Exception("Group not found");

      Map<String, double> balances = {};
      if (groupSnapshot.data() != null && groupSnapshot.data()!.containsKey('balances')) {
        Map<String, dynamic> raw = groupSnapshot.data()!['balances'];
        raw.forEach((k, v) => balances[k] = (v as num).toDouble());
      }

      double splitAmount = expense.amount / expense.participantsIds.length;
      
      balances[expense.payerId] = (balances[expense.payerId] ?? 0.0) + expense.amount;
      
      for (var uid in expense.participantsIds) {
        balances[uid] = (balances[uid] ?? 0.0) - splitAmount;
      }

      transaction.set(expenseRef, expense.toMap());
      transaction.update(groupRef, {'balances': balances});
    });
  }

  Stream<DocumentSnapshot> getGroupStream(String groupId) {
    return _firestore.collection('groups').doc(groupId).snapshots();
  }

  Future<void> migrateOldExpensesToBalances() async {
    final groupId = await getCurrentUserGroupId();
    final expensesSnapshot = await _firestore.collection('expenses')
        .where('groupId', isEqualTo: groupId).get();
    
    final usersSnapshot = await _firestore.collection('users')
        .where('groupId', isEqualTo: groupId).get();
    List<String> allUserIds = usersSnapshot.docs.map((d) => d.id).toList();

    Map<String, double> balances = {};
    for (var uid in allUserIds) balances[uid] = 0.0;

    for (var doc in expensesSnapshot.docs) {
      final data = doc.data();
      
      double amount = (data['amount'] as num).toDouble();
      String payerId = data['payerId'];
      List<String> participants = List<String>.from(data['participantsIds']);
      
      double split = amount / participants.length;
      balances[payerId] = (balances[payerId] ?? 0) + amount;
      for(var p in participants) {
        balances[p] = (balances[p] ?? 0) - split;
      }
    }

    await _firestore.collection('groups').doc(groupId).update({
      'balances': balances
    });
    debugPrint("MIGRATION SUCCESS: Balances updated!");
  }

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

  /// Delete all expenses from group
  Future<void> deleteAllExpenses() async {
    final groupId = await getCurrentUserGroupId();
    
    final expensesSnapshot = await _firestore
        .collection('expenses')
        .where('groupId', isEqualTo: groupId)
        .get();

    final WriteBatch batch = _firestore.batch();
    for (var doc in expensesSnapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();

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

        if (isSettled != null) {
          items = items.where((item) => item.isSettled == isSettled).toList();
        }

        return items;
      });
    });
  }

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

    if (isSettled != null) {
       query = query.where('isSettled', isEqualTo: isSettled);
    }
    
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }
    
    query = query.limit(limit);

    final snapshot = await query.get();
    return snapshot.docs;
  }

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

  Future<String?> updateUserProfile(String firstName, String lastName) async {
    try {
      final String userId = FirebaseAuth.instance.currentUser!.uid;
      await _firestore.collection('users').doc(userId).update({
        'firstName': firstName,
        'lastName': lastName,
      });
      return null;
    } catch (e) {
      if (e is FirebaseException) {
        return e.message;
      }
      return 'An unexpected error occurred: ${e.toString()}';
    }
  }

  /// Add announcement to group
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

  /// Add item to shopping list
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

  Stream<List<Map<String, dynamic>>> getShoppingList() {
    return Stream.fromFuture(getCurrentUserGroupId()).asyncExpand((groupId) {
      return _firestore
          .collection('shopping_items')
          .where('groupId', isEqualTo: groupId)
          .orderBy('isBought', descending: false)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        debugPrint('getShoppingList: snapshot for group $groupId contains ${snapshot.docs.length} docs');
        return snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final map = Map<String, dynamic>.from(data);
          map['id'] = doc.id;
          return map;
        }).toList();
      });
    });
  }

  Future<void> toggleShoppingItemStatus(String itemId, bool currentStatus) async {
    final updateData = <String, dynamic>{
      'isBought': !currentStatus,
      'boughtAt': !currentStatus ? Timestamp.now() : FieldValue.delete(),
    };
    await _firestore.collection('shopping_items').doc(itemId).update(updateData);
  }

  Future<void> deleteShoppingItem(String itemId) async {
    await _firestore.collection('shopping_items').doc(itemId).delete();
  }

  // ==============================
  // ADMIN FEATURES
  // ==============================

  Stream<List<Map<String, dynamic>>> getAllGroupsStream() {
    return _firestore.collection('groups').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  Stream<List<Map<String, dynamic>>> getGroupMembersStream(String groupId) {
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