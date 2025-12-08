import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Dodajemy to, żeby pobrać rolę bezpośrednio
import '../services/firestore_service.dart';
import '../constants.dart';
import '../widgets/menu_bar.dart';

class MembersScreen extends StatefulWidget {
  const MembersScreen({super.key});

  @override
  State<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends State<MembersScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  
  String _groupId = '';
  String _groupName = '';
  List<Map<String, dynamic>> _members = []; // Zmieniono na dynamic, żeby trzymać też rolę
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // 1. Pobieramy ID grupy
      final groupId = await _firestoreService.getCurrentUserGroupId();
      
      // 2. Pobieramy nazwę grupy
      final groupName = await _firestoreService.getGroupName(groupId);
      
      // 3. Pobieramy listę członków WRAZ Z ROLAMI
      // Używamy bezpośredniego zapytania tutaj, aby mieć pewność, że mamy pole 'role'
      // bez konieczności modyfikowania FirestoreService w tej chwili.
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('groupId', isEqualTo: groupId)
          .get();

      final members = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}'.trim(),
          'role': data['role'] ?? 'Member', // Pobieramy rolę (np. 'manager' lub 'Member')
        };
      }).toList();

      if (mounted) {
        setState(() {
          _groupId = groupId;
          _groupName = groupName;
          _members = members;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading members data: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      
      // --- APP BAR (Zaktualizowany styl) ---
      appBar: AppBar(
        backgroundColor: backgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded, size: 28, color: textColor),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        // STYLOWY NAGŁÓWEK
        title: Column(
          children: [
            const Text(
              'ROOMIES',
              style: TextStyle(
                color: primaryColor,
                fontFamily: 'StackSansNotch',
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
                fontSize: 20,
              ),
            ),
            Text(
              _groupName.isNotEmpty ? _groupName.toUpperCase() : 'MEMBERS',
              style: const TextStyle(
                color: lightTextColor,
                fontFamily: appFontFamily,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          // Pusty przycisk dla zachowania symetrii lub powiadomienia
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, size: 28, color: textColor),
            onPressed: () {},
          ),
        ],
      ),

      drawer: CustomDrawer(
        groupId: _groupId, 
        roomName: _groupName,
        currentRoute: 'members',
      ),

      // --- BODY ---
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          : _members.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.group_off_rounded, size: 64, color: lightTextColor),
                      const SizedBox(height: 16),
                      Text(
                        'No members found.',
                        style: TextStyle(
                          color: lightTextColor,
                          fontSize: 16,
                          fontFamily: appFontFamily,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: _members.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final member = _members[index];
                    final String userId = member['id'];
                    final String name = member['name'].toString().isNotEmpty ? member['name'] : 'Unknown';
                    // Sprawdzamy rolę (obsługuje różne warianty zapisu)
                    final String role = (member['role'] ?? '').toString().toLowerCase();
                    final bool isAdmin = role.contains('manager');
                    
                    final bool isMe = userId == _currentUserId;
                    final String initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isMe ? primaryColor.withOpacity(0.5) : borderColor, 
                          width: isMe ? 1.5 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: textColor.withOpacity(0.02),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // --- AVATAR ---
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: isMe ? primaryColor : surfaceColor,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              initial,
                              style: TextStyle(
                                color: isMe ? Colors.white : primaryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                fontFamily: appFontFamily,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          
                          // --- DANE UŻYTKOWNIKA ---
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        name,
                                        style: const TextStyle(
                                          color: textColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          fontFamily: appFontFamily,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    // --- BADGE Managera ---
                                    if (isAdmin) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: textColor, // Ciemny kolor dla admina
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Text(
                                          'APARTMENT MANAGER',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 9,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                if (isMe)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: primaryColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        'You',
                                        style: TextStyle(
                                          color: primaryColor,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: appFontFamily,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}