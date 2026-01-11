import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Potrzebne do obsługi Timestamp
import 'package:intl/intl.dart'; // Do formatowania daty
import '../constants.dart';
import '../services/firestore_service.dart'; // Import Twojego serwisu
import 'admin_group_details_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  static const String id = 'admin_dashboard_screen';

  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> with SingleTickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  
  late TabController _tabController;
  String _userGroupFilter = 'all'; // filtr dla zakładki Users

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Pomocnicza funkcja do formatowania daty z Timestamp
  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    if (timestamp is Timestamp) {
      return DateFormat('yyyy-MM-dd').format(timestamp.toDate());
    }
    return timestamp.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: backgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'ADMIN PANEL',
          style: TextStyle(
            color: textColor,
            fontFamily: 'StackSansNotch',
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            onPressed: () => Navigator.pop(context),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: primaryColor,
          labelColor: primaryColor,
          unselectedLabelColor: lightTextColor,
          labelStyle: const TextStyle(
            fontFamily: appFontFamily,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          tabs: const [
            Tab(icon: Icon(Icons.apartment_rounded), text: 'Groups'),
            Tab(icon: Icon(Icons.people_rounded), text: 'Users'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGroupsTab(),
          _buildUsersTab(),
        ],
      ),
    );
  }

  // ZAKŁADKA GROUPS
  Widget _buildGroupsTab() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          const Text(
            'Manage Groups',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: textColor,
              fontFamily: appFontFamily,
              letterSpacing: -1.0,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Overview of all registered apartments.',
            style: TextStyle(color: lightTextColor, fontFamily: appFontFamily),
          ),
          const SizedBox(height: 20),

          // Wyszukiwarka
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by name or ID...',
              prefixIcon: const Icon(Icons.search, color: lightTextColor),
              fillColor: surfaceColor,
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
            style: const TextStyle(color: textColor, fontFamily: appFontFamily),
          ),
          const SizedBox(height: 20),

          // Lista grup
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _firestoreService.getAllGroupsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text(
                      'No groups found.',
                      style: TextStyle(fontFamily: appFontFamily),
                    ),
                  );
                }

                final allGroups = snapshot.data!;
                final filteredGroups = allGroups.where((group) {
                  final name = (group['name'] ?? '').toString().toLowerCase();
                  final id = (group['id'] ?? '').toString().toLowerCase();
                  return name.contains(_searchQuery) || id.contains(_searchQuery);
                }).toList();

                if (filteredGroups.isEmpty) {
                  return const Center(
                    child: Text(
                      'No results found.',
                      style: TextStyle(fontFamily: appFontFamily),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: filteredGroups.length,
                  itemBuilder: (context, index) {
                    final group = filteredGroups[index];
                    return _AdminGroupCard(group: group);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ZAKŁADKA USERS
  Widget _buildUsersTab() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          const Text(
            'Manage Users',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: textColor,
              fontFamily: appFontFamily,
              letterSpacing: -1.0,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'View and manage all users in the system.',
            style: TextStyle(color: lightTextColor, fontFamily: appFontFamily),
          ),
          const SizedBox(height: 20),

          // Wyszukiwarka
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by name or email...',
              prefixIcon: const Icon(Icons.search, color: lightTextColor),
              fillColor: surfaceColor,
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
            style: const TextStyle(color: textColor, fontFamily: appFontFamily),
          ),
          const SizedBox(height: 16),

          // Filtr po grupach
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: _firestoreService.getAllGroupsStream(),
            builder: (context, groupSnapshot) {
              if (!groupSnapshot.hasData) return const SizedBox.shrink();
              
              final groups = groupSnapshot.data!;
              
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.filter_list, color: lightTextColor, size: 18),
                    const SizedBox(width: 8),
                    const Text(
                      'Filter:',
                      style: TextStyle(
                        color: lightTextColor,
                        fontFamily: appFontFamily,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _FilterChip(
                              label: 'All',
                              isSelected: _userGroupFilter == 'all',
                              onTap: () => setState(() => _userGroupFilter = 'all'),
                            ),
                            const SizedBox(width: 8),
                            _FilterChip(
                              label: 'No Group',
                              isSelected: _userGroupFilter == 'default_group',
                              onTap: () => setState(() => _userGroupFilter = 'default_group'),
                            ),
                            ...groups.map((g) => Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: _FilterChip(
                                label: g['name'] ?? g['id'],
                                isSelected: _userGroupFilter == g['id'],
                                onTap: () => setState(() => _userGroupFilter = g['id']),
                              ),
                            )),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 20),

          // Lista użytkowników
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _firestoreService.getAllUsersStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text(
                      'No users found.',
                      style: TextStyle(fontFamily: appFontFamily),
                    ),
                  );
                }

                final allUsers = snapshot.data!;
                
                // Filtrowanie
                final filteredUsers = allUsers.where((user) {
                  // Filtr wyszukiwania
                  final name = (user['name'] ?? '').toString().toLowerCase();
                  final email = (user['email'] ?? '').toString().toLowerCase();
                  final searchMatch = name.contains(_searchQuery) || email.contains(_searchQuery);
                  
                  // Filtr grupy
                  final groupId = user['groupId'] ?? 'default_group';
                  final groupMatch = _userGroupFilter == 'all' || groupId == _userGroupFilter;
                  
                  return searchMatch && groupMatch;
                }).toList();

                if (filteredUsers.isEmpty) {
                  return const Center(
                    child: Text(
                      'No results found.',
                      style: TextStyle(fontFamily: appFontFamily),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: filteredUsers.length,
                  itemBuilder: (context, index) {
                    final user = filteredUsers[index];
                    return _UserCard(
                      user: user,
                      onEdit: () => _showEditUserDialog(user),
                      onDelete: () => _deleteUser(user),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // EDYCJA DANYCH UŻYTKOWNIKA
  void _showEditUserDialog(Map<String, dynamic> user) {
    final firstNameController = TextEditingController(text: user['firstName'] ?? '');
    final lastNameController = TextEditingController(text: user['lastName'] ?? '');
    final emailController = TextEditingController(text: user['email'] ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Edit User',
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
            child: const Text('Cancel', style: TextStyle(color: lightTextColor)),
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
                      content: Text('User updated successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
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
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _deleteUser(Map<String, dynamic> user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirm Deletion'),
        content: Text(
          'Are you sure you want to permanently delete user "${user['name']}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    ) ?? false;

    if (!confirmed) return;

    try {
      await _firestoreService.deleteUser(user['uid']);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
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
}

// --- WIDŻET KARTY GRUPY ---
class _AdminGroupCard extends StatelessWidget {
  final Map<String, dynamic> group;

  const _AdminGroupCard({required this.group});

  @override
  Widget build(BuildContext context) {
    final status = group['status'] ?? 'Active';
    final bool isBlocked = status == 'Blocked';
    final bool isFlagged = status == 'Flagged';

    Color statusColor = primaryColor;
    IconData statusIcon = Icons.apartment_rounded;

    if (isBlocked) {
      statusColor = Colors.red;
      statusIcon = Icons.block;
    } else if (isFlagged) {
      statusColor = Colors.orange;
      statusIcon = Icons.warning_rounded;
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AdminGroupDetailsScreen(group: group),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: textColor.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(statusIcon, color: statusColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    group['name'] ?? 'Unnamed Group',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: textColor,
                      fontFamily: appFontFamily,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ID: ${group['id']}',
                    style: const TextStyle(
                      color: lightTextColor,
                      fontSize: 12,
                      fontFamily: appFontFamily,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: lightTextColor),
          ],
        ),
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _UserCard({
    required this.user,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final name = user['name'] ?? 'Unknown';
    final email = user['email'] ?? 'No email';
    final groupId = user['groupId'] ?? 'default_group';
    
    Color roleColor = lightTextColor;
    String roleLabel = 'User';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: roleColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: TextStyle(
                  color: roleColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
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
                    Flexible(
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: textColor,
                          fontFamily: appFontFamily,
                          fontSize: 15,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: const TextStyle(
                    color: lightTextColor,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  groupId == 'default_group' ? 'No Group' : 'Group: $groupId',
                  style: const TextStyle(
                    color: lightTextColor,
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
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
              if (value == 'edit') {
                onEdit();
              } else if (value == 'delete') {
                onDelete();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, color: primaryColor, size: 20),
                    SizedBox(width: 10),
                    Text('Edit User'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_forever, color: Colors.red, size: 20),
                    SizedBox(width: 10),
                    Text('Delete User', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? primaryColor : borderColor,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : lightTextColor,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            fontFamily: appFontFamily,
          ),
        ),
      ),
    );
  }
}