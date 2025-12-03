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

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Nasłuchujemy zmian w polu wyszukiwania, żeby odświeżać widok
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
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
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
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

            // --- WYSZUKIWARKA ---
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

            // --- LISTA GRUP Z FIREBASE ---
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                // Używamy metody z Twojego FirestoreService
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

                  // Filtrowanie listy na podstawie wpisanego tekstu
                  final filteredGroups = allGroups.where((group) {
                    final name = (group['name'] ?? '').toString().toLowerCase();
                    final id = (group['id'] ?? '').toString().toLowerCase();
                    return name.contains(_searchQuery) ||
                        id.contains(_searchQuery);
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
                      // W Twoim kodzie widziałem, że liczysz członków.
                      // W Firebase zazwyczaj trzeba to dociągnąć osobno lub mieć licznik w dokumencie grupy.
                      // Na razie wyświetlimy 'members' jeśli jest w dokumencie, lub '?'
                      final membersCount = group['members'] ?? '?';

                      return _AdminGroupCard(
                        group: group,
                        membersCount: membersCount.toString(),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- WIDŻET KARTY GRUPY ---
class _AdminGroupCard extends StatelessWidget {
  final Map<String, dynamic> group;
  final String membersCount;

  const _AdminGroupCard({
    required this.group,
    this.membersCount = '?',
  });

  @override
  Widget build(BuildContext context) {
    final status = group['status'] ?? 'Active';
    final bool isBlocked = status == 'Blocked';
    final bool isFlagged = status == 'Flagged';

    // Ustalanie koloru ikony w zależności od statusu
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
        // Nawigacja do drugiego pliku (szczegóły)
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
            // Ikona statusu
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                statusIcon,
                color: statusColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),

            // Informacje o grupie
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

            // Strzałka
            const Icon(Icons.chevron_right_rounded, color: lightTextColor),
          ],
        ),
      ),
    );
  }
}