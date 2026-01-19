import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Dodajemy to, żeby pobrać rolę bezpośrednio
import '../services/firestore_service.dart';
import '../constants.dart';
import '../widgets/menu_bar.dart';
import 'announcements_screen.dart';
import 'home_screen.dart';

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
  List<Map<String, dynamic>> _members =
      []; // Zmieniono na dynamic, żeby trzymać też rolę
  bool _isLoading = true;
  bool _isCurrentUserManager = false;

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

      // Sprawdzamy czy zalogowany użytkownik jest apartment managerem
      final isManager = await _firestoreService.isCurrentUserApartmentManager(groupId);

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
          'role': data['role'],
        };
      }).toList();

      if (mounted) {
        setState(() {
          _groupId = groupId;
          _groupName = groupName;
          _isCurrentUserManager = isManager;
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

  // Usunięcie członka z mieszkania
  Future<void> _removeMember(String userId) async {
    try {
      await _firestoreService.removeApartmentMember(_groupId, userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Member removed from the apartment'),
            backgroundColor: Colors.green,
          ),
        );
        // Odśwież listę
        await _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Przekazanie roli managera
  Future<void> _transferManagerRole(String newManagerId) async {
    try {
      await _firestoreService.transferManagerRole(_groupId, newManagerId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Manager role transferred successfully'),
            backgroundColor: Colors.green,
          ),
        );
        // Odśwież listę
        await _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Pokazanie dialogu do potwierdzenia usunięcia członka
  void _showRemoveMemberDialog(String userId, String memberName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Remove Member?'),
        content: Text('Are you sure you want to remove $memberName from the apartment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _removeMember(userId);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  // Pokazanie dialogu do transferu roli
  void _showTransferRoleDialog(String newManagerId, String memberName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Transfer Manager Role?'),
        content: Text('Transfer the apartment manager role to $memberName?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _transferManagerRole(newManagerId);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.green),
            child: const Text('Transfer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
  return PopScope(
    canPop: false, // BLOKUJEMY normalne cofanie
    onPopInvoked: (didPop) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()), 
        (route) => false, // USUWA CAŁY STACK
      );
    },
    child: Scaffold(
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
          IconButton(
            icon: const Icon(
              Icons.notifications_none_rounded,
              size: 28,
              color: textColor,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AnnouncementsScreen(),
                ),
              );
            },
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
                      const Icon(Icons.group_off_rounded,
                          size: 64, color: lightTextColor),
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
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final member = _members[index];
                    final String userId = member['id'];
                    final String name = member['name'].toString().isNotEmpty
                        ? member['name']
                        : 'Unknown';
                    // Sprawdzamy rolę (obsługuje różne warianty zapisu)
                    final String role =
                        (member['role'] ?? '').toString().toLowerCase();
                    final bool isAdmin = role.contains('manager');

                    final bool isMe = userId == _currentUserId;
                    final String initial =
                        name.isNotEmpty ? name[0].toUpperCase() : '?';

                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isMe
                              ? primaryColor.withOpacity(0.5)
                              : borderColor,
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
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color:
                                              textColor, // Ciemny kolor dla admina
                                          borderRadius:
                                              BorderRadius.circular(6),
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
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
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
                          // --- ACTION BUTTONS (Tylko widoczne dla zalogowanego apartment managera) ---
                          if (_isCurrentUserManager && _currentUserId != userId)
                            PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'remove') {
                                  _showRemoveMemberDialog(userId, name);
                                } else if (value == 'transfer') {
                                  _showTransferRoleDialog(userId, name);
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'transfer',
                                  child: Row(
                                    children: [
                                      Icon(Icons.admin_panel_settings, color: primaryColor, size: 18),
                                      SizedBox(width: 10),
                                      Text('Make Manager'),
                                    ],
                                  ),
                                ),
                                const PopupMenuDivider(),
                                const PopupMenuItem(
                                  value: 'remove',
                                  child: Row(
                                    children: [
                                      Icon(Icons.logout, color: Colors.red, size: 18),
                                      SizedBox(width: 10),
                                      Text('Remove'),
                                    ],
                                  ),
                                ),
                              ],
                            )
                          else
                            const SizedBox.shrink(),
                        ],
                      ),
                    );
                  },
                ),
  ));
  }
}
