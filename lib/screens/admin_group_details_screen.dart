import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore
import 'package:firebase_auth/firebase_auth.dart'; // <--- DODANO: Potrzebne do ID admina
import 'package:intl/intl.dart'; // Formatowanie daty
import '../constants.dart';
import '../services/firestore_service.dart'; // Twój serwis
import '../models/announcement_model.dart'; // Model ogłoszenia

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

  @override
  void initState() {
    super.initState();
    // Pobieramy ID grupy
    _groupId = widget.group['id'] ?? '';
  }

  // --- FUNKCJE FIRESTORE ---

  // Zmiana statusu grupy
  void _changeGroupStatus(String newStatus) async {
    try {
      await _firestoreService.updateGroupStatus(_groupId, newStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Group status changed to: $newStatus"),
            backgroundColor: Colors.green,
          ),
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

  // Zmiana roli użytkownika
  void _toggleAdminRole(String userId, String currentRole) async {
    final newRole = currentRole == 'Admin' ? 'Member' : 'Admin';
    try {
      await _firestoreService.updateUserRole(userId, newRole);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newRole == 'Admin'
                ? "User promoted to Admin."
                : "Admin privileges revoked."),
            backgroundColor: Colors.blueAccent,
          ),
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

  // Usunięcie użytkownika
  void _removeUser(String userId) async {
    try {
      await _firestoreService.removeUserFromGroup(userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("User removed form group."),
              backgroundColor: Colors.orange),
        );
      }
    } catch (e) {
      // Obsługa błędu
    }
  }

  // --- NAPRAWIONA FUNKCJA DODAWANIA OGŁOSZENIA ---
  void _postAnnouncement(String title, String message) async {
    if (title.isEmpty || message.isEmpty) return;

    // Pobieramy ID aktualnego admina (lub placeholder, jeśli null)
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? 'ADMIN_SYSTEM';

    final announcement = Announcement(
      id: '', // Firestore wygeneruje ID, ale model wymaga stringa
      title: title,
      body: message, // <--- POPRAWIONE: mapowanie message -> body
      groupId: _groupId,
      createdById: currentUserId, // <--- POPRAWIONE: Dodano wymagane ID twórcy
      createdByName: 'Admin System', // <--- POPRAWIONE: authorName -> createdByName
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
            child: const Text("Cancel", style: TextStyle(color: lightTextColor)),
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
                body: Center(child: CircularProgressIndicator()));
          }

          final groupData = groupSnapshot.data!.data() as Map<String, dynamic>;
          final groupName = groupData['name'] ?? 'Unknown Group';
          final groupStatus = groupData['status'] ?? 'Active';
          final groupCreated = _formatTimestamp(groupData['createdAt']);

          return Scaffold(
            backgroundColor: backgroundColor,
            appBar: AppBar(
              backgroundColor: backgroundColor,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: textColor),
                onPressed: () => Navigator.pop(context),
              ),
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
                // --- MENU ZARZĄDZANIA GRUPĄ ---
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded, color: textColor),
                  color: Colors.white,
                  surfaceTintColor: Colors.transparent,
                  onSelected: (value) {
                    if (value == 'delete') {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text("Delete group clicked (Dangerous!)")),
                      );
                    } else {
                      _changeGroupStatus(value);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'Active',
                      child: Row(children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 18),
                        SizedBox(width: 8),
                        Text('Set Active')
                      ]),
                    ),
                    const PopupMenuItem(
                      value: 'Blocked',
                      child: Row(children: [
                        Icon(Icons.block, color: Colors.red, size: 18),
                        SizedBox(width: 8),
                        Text('Block Group')
                      ]),
                    ),
                    const PopupMenuItem(
                      value: 'Flagged',
                      child: Row(children: [
                        Icon(Icons.flag, color: Colors.orange, size: 18),
                        SizedBox(width: 8),
                        Text('Flag Group')
                      ]),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(children: [
                        Icon(Icons.delete_forever, color: Colors.red, size: 18),
                        SizedBox(width: 8),
                        Text('Delete Group',
                            style: TextStyle(color: Colors.red))
                      ]),
                    ),
                  ],
                ),
              ],
            ),
            body: SingleChildScrollView(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- BANER PRYWATNOŚCI ---
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border:
                            Border.all(color: Colors.orange.withOpacity(0.3)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.lock_outline_rounded,
                              color: Colors.orange, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
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

                    // --- ADMIN ACTIONS ---
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
                                  offset: const Offset(0, 4))
                            ]),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.campaign_rounded, color: Colors.white),
                            SizedBox(width: 10),
                            Text("Post Official Announcement",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: appFontFamily)),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // --- SZCZEGÓŁY GRUPY ---
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
                        Expanded(
                          child: _InfoCard(
                            label: "Status",
                            value: groupStatus,
                            icon: Icons.shield_outlined,
                            valueColor: groupStatus == 'Blocked'
                                ? Colors.red
                                : (groupStatus == 'Flagged'
                                    ? Colors.orange
                                    : Colors.green),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _InfoCard(
                      label: "Created at",
                      value: groupCreated,
                      icon: Icons.calendar_today_rounded,
                      isFullWidth: true,
                    ),

                    const SizedBox(height: 40),

                    // --- LISTA CZŁONKÓW (StreamBuilder) ---
                    StreamBuilder<List<Map<String, dynamic>>>(
                      stream: _firestoreService.getGroupMembersStream(_groupId),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
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
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final user = members[index];
                                return _MemberTile(
                                  user: user,
                                  onToggleAdmin: () => _toggleAdminRole(
                                      user['uid'], user['role']),
                                  onRemoveUser: () => _removeUser(user['uid']),
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
        });
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

  const _MemberTile({
    required this.user,
    required this.onToggleAdmin,
    required this.onRemoveUser,
  });

  @override
  Widget build(BuildContext context) {
    final bool isAdmin = user['role'] == 'Admin';
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
                            ? Icons.person_remove
                            : Icons.admin_panel_settings,
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