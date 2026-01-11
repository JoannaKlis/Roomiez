import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore
import 'package:firebase_auth/firebase_auth.dart'; // <--- DODANO: Potrzebne do ID admina
import 'package:intl/intl.dart'; // Formatowanie daty
import '../constants.dart';
import '../services/firestore_service.dart'; // Twój serwis
import '../models/announcement_model.dart'; // Model ogłoszenia
import '../utils/user_roles.dart';

class AdminGroupDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> group;

  const AdminGroupDetailsScreen({super.key, required this.group});

  @override
  State<AdminGroupDetailsScreen> createState() =>
      _AdminGroupDetailsScreenState();
}

class _AdminGroupDetailsScreenState extends State<AdminGroupDetailsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  late String _groupId;
  final String? _currentAdminUid = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _groupId = widget.group['id'] ?? '';
  }

  // --- FUNKCJE FIRESTORE - ZARZĄDZANIE GRUPĄ ---

  // Usunięcie grupy i resetowanie użytkowników (Admin CRUD)
  void _deleteGroup() async {
    final bool confirmed = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Confirm Deletion"),
        content: Text(
          "Are you sure you want to permanently delete group '${widget.group['name'] ?? _groupId}'? All members will be moved to 'No Group' and their roles will be reset.",
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    ) ?? false;

    if (!confirmed) return;

    try {
      await _firestoreService.deleteGroup(_groupId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Group successfully deleted!"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error deleting group: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Zmiana nazwy grupy
  void _showEditGroupNameDialog() {
    final nameController = TextEditingController(
      text: widget.group['name'] ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "Edit Group Name",
          style: TextStyle(
            fontFamily: 'StackSansNotch',
            fontWeight: FontWeight.bold,
          ),
        ),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Group Name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: lightTextColor)),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = nameController.text.trim();
              if (newName.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Name cannot be empty")),
                );
                return;
              }

              try {
                await FirebaseFirestore.instance
                    .collection('groups')
                    .doc(_groupId)
                    .update({'name': newName});
                
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Group name updated!"),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Error: $e"),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  // --- FUNKCJE FIRESTORE - ZARZĄDZANIE CZŁONKAMI GRUPY ---

  // Zmiana roli użytkownika (Make Admin / Revoke Admin)
  void _toggleAdminRole(String userId, String currentRole) async {
    // sprawdzenie czy nowa rola będzie adminem
    final bool willBeAdmin = currentRole != UserRole.administrator;

    // admin nie może odebrać sobie roli
    if (userId == _currentAdminUid && !willBeAdmin) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("You cannot revoke your own administrator role!"),
          ),
        );
      }
      return;
    }

    try {
      // wywołanie metody z firestore_service
      await _firestoreService.updateUserRole(userId, willBeAdmin); 

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(willBeAdmin
                ? "User role set to Admin."
                : "Admin privileges revoked."),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error changing role: $e")),
        );
      }
    }
  }

  // Usunięcie użytkownika z grupy (admin CRUD)
  void _removeUserFromGroup(String userId, String userName) async {
    // admin nie może usunąć siebie z grupy
    if (userId == _currentAdminUid) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("You cannot remove yourself from the group!"),
          ),
        );
      }
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Remove Member"),
        content: Text(
          "Remove '$userName' from this group? They will be moved to 'No Group' and their role will be reset to User.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text("Remove"),
          ),
        ],
      ),
    ) ?? false;

    if (!confirmed) return;

    try {
      await _firestoreService.removeUserFromGroup(userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("User removed from the group."),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error removing user: $e")),
        );
      }
    }
  }

  // Całkowite usunięcie użytkownika z bazy danych
  void _deleteUser(String userId, String userName) async {
    // Admin nie może usunąć siebie
    if (userId == _currentAdminUid) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("You cannot delete yourself!"),
          ),
        );
      }
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Delete User"),
        content: Text(
          "Permanently delete user '$userName' from the database? This action cannot be undone and will remove all their data.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Delete Permanently"),
          ),
        ],
      ),
    ) ?? false;

    if (!confirmed) return;

    try {
      await _firestoreService.deleteUser(userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("User deleted permanently."),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error deleting user: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Edycja danych użytkownika
  void _editUser(Map<String, dynamic> user) {
    final firstNameController = TextEditingController(
      text: user['firstName'] ?? '',
    );
    final lastNameController = TextEditingController(
      text: user['lastName'] ?? '',
    );
    final emailController = TextEditingController(
      text: user['email'] ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "Edit User",
          style: TextStyle(
            fontFamily: 'StackSansNotch',
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: firstNameController,
                decoration: const InputDecoration(
                  labelText: 'First Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: lastNameController,
                decoration: const InputDecoration(
                  labelText: 'Last Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: lightTextColor)),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _firestoreService.updateUserData(
                  user['uid'],
                  firstName: firstNameController.text,
                  lastName: lastNameController.text,
                  email: emailController.text,
                );
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("User updated successfully"),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Error: $e"),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  // --- FUNKCJA DODAWANIA OGŁOSZENIA ---
  void _postAnnouncement(String title, String message) async {
    if (title.isEmpty || message.isEmpty) return;

    // Pobieramy ID aktualnego admina (lub placeholder, jeśli null)
    final currentUserId =
        FirebaseAuth.instance.currentUser?.uid ?? 'ADMIN_SYSTEM';

    final announcement = Announcement(
      id: '', // Firestore wygeneruje ID, ale model wymaga stringa
      title: title,
      body: message, // <--- POPRAWIONE: mapowanie message -> body
      groupId: _groupId,
      createdById: currentUserId, // <--- POPRAWIONE: Dodano wymagane ID twórcy
      createdByName:
          'Admin System', // <--- POPRAWIONE: authorName -> createdByName
      createdAt: DateTime.now(),
      imageUrls: [], // Opcjonalne, pusta lista
    );

    try {
      await _firestoreService.addAnnouncement(announcement);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Announcement sent successfully!"),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  // Okienko dodawania ogłoszenia
  void _showPostAnnouncementDialog() {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Post Admin Announcement",
            style: TextStyle(
                fontFamily: 'StackSansNotch', fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("This message will be visible to all group members.",
                style: TextStyle(color: lightTextColor, fontSize: 12)),
            const SizedBox(height: 16),
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: bodyController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Message',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text("Cancel", style: TextStyle(color: lightTextColor)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _postAnnouncement(titleController.text, bodyController.text);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text("Post"),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    if (timestamp is Timestamp) {
      return DateFormat('yyyy-MM-dd').format(timestamp.toDate());
    }
    return timestamp.toString();
  }

  @override
  Widget build(BuildContext context) {
    // StreamBuilder dla dokumentu grupy (status na żywo)
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('groups')
          .doc(_groupId)
          .snapshots(),
      builder: (context, groupSnapshot) {
        if (!groupSnapshot.hasData) {
          return const Scaffold(
            backgroundColor: backgroundColor,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final groupData = groupSnapshot.data!.data() as Map<String, dynamic>;
        final groupName = groupData['name'] ?? 'Unknown Group';

        return Scaffold(
          backgroundColor: backgroundColor,
          appBar: AppBar(
            backgroundColor: backgroundColor,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            title: Text(
              groupName,
              style: const TextStyle(
                color: textColor,
                fontFamily: 'StackSansNotch',
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
            centerTitle: true,
            actions: [
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, color: textColor),
                color: Colors.white,
                onSelected: (value) {
                  if (value == 'delete') {
                    _deleteGroup();
                  } else if (value == 'edit_name') {
                    _showEditGroupNameDialog();
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit_name',
                    child: Row(
                      children: [
                        Icon(Icons.edit, color: primaryColor, size: 18),
                        SizedBox(width: 8),
                        Text('Edit Name'),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_forever, color: Colors.red, size: 18),
                        SizedBox(width: 8),
                        Text('Delete Group', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              )
            ],
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Baner prywatności
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.lock_outline_rounded,
                          color: Colors.orange,
                          size: 20,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Privacy Protected",
                                style: TextStyle(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: appFontFamily,
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                "Private data (expenses, tasks, lists) are hidden from admin view.",
                                style: TextStyle(
                                  color: Colors.orange,
                                  fontSize: 12,
                                  fontFamily: appFontFamily,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Admin Actions
                  const Text(
                    'Admin Actions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                      fontFamily: appFontFamily,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: _showPostAnnouncementDialog,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.campaign_rounded, color: Colors.white),
                          SizedBox(width: 10),
                          Text(
                            "Post Official Announcement",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontFamily: appFontFamily,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Szczegóły grupy
                  const Text(
                    'Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                      fontFamily: appFontFamily,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _InfoCard(
                          label: "Group ID",
                          value: _groupId,
                          icon: Icons.fingerprint_rounded,
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                  ),
                  const SizedBox(height: 40),

                  // Lista członków
                  StreamBuilder<List<Map<String, dynamic>>>(
                    stream: _firestoreService.getGroupMembersStream(_groupId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Text('Error loading members: ${snapshot.error}');
                      }

                      final members = snapshot.data ?? [];

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Members',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                  fontFamily: appFontFamily,
                                ),
                              ),
                              Text(
                                '${members.length} total',
                                style: const TextStyle(
                                  color: lightTextColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (members.isEmpty)
                            const Text("No members in this group."),
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: members.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final user = members[index];
                              return _MemberTile(
                                user: user,
                                onToggleAdmin: () => _toggleAdminRole(
                                  user['uid'],
                                  user['role'],
                                ),
                                onRemoveUser: () => _removeUserFromGroup(
                                  user['uid'],
                                  user['name'],
                                ),
                                onDeleteUser: () => _deleteUser(
                                  user['uid'],
                                  user['name'],
                                ),
                                onEditUser: () => _editUser(user),
                              );
                            },
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// --- WIDŻETY POMOCNICZE ---

class _InfoCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;
  final bool isFullWidth;

  const _InfoCard({
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor,
    this.isFullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: lightTextColor),
              const SizedBox(width: 8),
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  color: lightTextColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? textColor,
              fontWeight: FontWeight.bold,
              fontFamily: isFullWidth ? 'Monospace' : appFontFamily,
              fontSize: 16,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  final Map<String, dynamic> user; // Zmienione na dynamiczne z Firebase
  final VoidCallback onToggleAdmin;
  final VoidCallback onRemoveUser;
  final VoidCallback onDeleteUser;
  final VoidCallback onEditUser;

  const _MemberTile({
    required this.user,
    required this.onToggleAdmin,
    required this.onRemoveUser,
    required this.onDeleteUser,
    required this.onEditUser,
  });

  @override
  Widget build(BuildContext context) {
    final bool isAdmin = user['role'] == 'admin';
    final String name = user['name'] ?? 'Unknown';
    final String email = user['email'] ?? 'No email';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          // Awatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isAdmin ? primaryColor.withOpacity(0.1) : surfaceColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: TextStyle(
                  color: isAdmin ? primaryColor : lightTextColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: textColor,
                        fontFamily: appFontFamily,
                        fontSize: 15,
                      ),
                    ),
                    if (isAdmin) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: primaryColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          "ADMIN",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold),
                        ),
                      )
                    ]
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  email,
                  style: const TextStyle(
                    color: lightTextColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Menu akcji
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: lightTextColor),
            color: Colors.white,
            surfaceTintColor: Colors.transparent,
            onSelected: (value) {
              if (value == 'toggle_role') {
                onToggleAdmin();
              } else if (value == 'remove') {
                onRemoveUser(); 
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'toggle_role',
                child: Row(
                  children: [
                    Icon(
                        isAdmin
                            ? Icons.person_remove // revoke admin
                            : Icons.admin_panel_settings, // make admin
                        color: primaryColor,
                        size: 20),
                    const SizedBox(width: 10),
                    Text(isAdmin ? 'Revoke Admin' : 'Make Admin'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'remove',
                child: Row(children: [
                  Icon(Icons.logout, color: Colors.black87, size: 20),
                  SizedBox(width: 10),
                  Text('Remove from group')
                ]),
              ),
            ],
          ),
        ],
      ),
    );
  }
}