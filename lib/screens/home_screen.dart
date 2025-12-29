import 'package:flutter/material.dart';
import 'package:roomies/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/task_model.dart';
import 'package:intl/intl.dart';
import '../constants.dart';
import 'tasks_screen.dart';
import 'expenses_screen.dart';
import 'announcements_screen.dart';
import 'profile_edit_screen.dart';
import '../widgets/menu_bar.dart';
import '../models/expense_history_item.dart'; 

class HomeScreen extends StatefulWidget {
  final String roomName;
  final String groupId;

  const HomeScreen({
    super.key,
    required this.roomName,
    required this.groupId,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  String _userName = 'Roomie'; // Domyślna wartość podczas ładowania

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  // Funkcja pobierająca imię z Firebase
  Future<void> _loadUserName() async {
    final userProfile = await _firestoreService.getCurrentUserProfile();
    if (mounted && userProfile != null) {
      setState(() {
        _userName = userProfile['firstName'] ?? 'Roomie';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor, // Czysta biel

      // --- APP BAR ---
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
        title: Column(
          children: [
            const Text(
              'ROOMIES',
              style: TextStyle(
                color: primaryColor,
                fontFamily: 'StackSansNotch', // Twoja czcionka firmowa
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
                fontSize: 20,
              ),
            ),
            if (widget.roomName.isNotEmpty)
              Text(
                widget.roomName.toUpperCase(),
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

      // --- BODY ---
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // --- Powitanie i Edycja Profilu ---
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Hello, $_userName!', // Dynamiczne imię
                    style: const TextStyle(
                      fontSize: 28,
                      fontFamily: appFontFamily,
                      fontWeight: FontWeight.w900, // Gruby Inter
                      color: textColor,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () async {
                      // Czekamy na powrót z edycji, żeby odświeżyć imię
                      await Navigator.pushNamed(context, ProfileEditScreen.id);
                      _loadUserName();
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: surfaceColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.edit_rounded,
                        color: primaryColor,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // --- KAFELKI NAWIGACYJNE (Modern Buttons) ---
              Row(
                children: [
                  Expanded(
                    child: _SquareActionCard(
                      icon: Icons.check_circle_outline_rounded,
                      label: 'Add task',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const TasksScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _SquareActionCard(
                      icon: Icons.notifications_active_outlined,
                      label: 'Announcements',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AnnouncementsScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // --- SEKCJA: WYDATKI ---
              const _SectionHeader(title: 'Recent expenses'),
              const SizedBox(height: 12),
              _ExpensesCard(
                groupId: widget.groupId,
                onGoToExpenses: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ExpensesScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 30),

              // --- SEKCJA: ZADANIA ---
              const _SectionHeader(title: 'Tasks'),
              const SizedBox(height: 12),
              const _TasksCard(),

              const SizedBox(height: 30),

              // --- SEKCJA: LISTA ZAKUPÓW ---
              const _SectionHeader(title: 'Shopping list'),
              const SizedBox(height: 12),
              const _ShoppingCard(),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
      // Drawer z poprawnymi danymi
      drawer: CustomDrawer(roomName: widget.roomName, groupId: widget.groupId),
    );
  }
}

// ==========================================
// WIDŻETY POMOCNICZE (STYLES MODERN / CLEAN UI)
// ==========================================

class _SquareActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _SquareActionCard({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 110,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor), // Delikatna ramka
          boxShadow: [
            BoxShadow(
              color: textColor.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1), // Jasne tło pod ikoną
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: primaryColor),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(
                color: textColor,
                fontFamily: appFontFamily,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpensesCard extends StatelessWidget {
  final String groupId; // Musimy to przekazać
  final VoidCallback onGoToExpenses;

  const _ExpensesCard({super.key, required this.groupId, required this.onGoToExpenses});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ExpenseHistoryItem>>(
      stream: FirestoreService().getRecentExpensesStream(groupId), // Pobieranie z bazy
      builder: (context, snapshot) {
        final expenses = snapshot.data ?? [];
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: borderColor)),
          child: Column(
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                 const Text("Recent Activity", style: TextStyle(fontWeight: FontWeight.bold, fontFamily: appFontFamily)),
                 GestureDetector(onTap: onGoToExpenses, child: const Text("See all", style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold))),
              ]),
              const Divider(height: 20, color: borderColor),
              if (expenses.isEmpty) const Padding(padding: EdgeInsets.all(8.0), child: Text("No recent expenses", style: TextStyle(color: lightTextColor))),
              ...expenses.map((e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: Row(children: [
                   const Icon(Icons.receipt_long, size: 18, color: lightTextColor),
                   const SizedBox(width: 8),
                   Expanded(child: Text(e.description, style: const TextStyle(fontWeight: FontWeight.w600))),
                   Text("${e.amount.toStringAsFixed(2)} PLN", style: const TextStyle(fontWeight: FontWeight.bold)),
                ]),
              )),
            ],
          ),
        );
      }
    );
  }
}

class _TasksCard extends StatelessWidget {
  const _TasksCard({super.key});

  String _dateLabel(DateTime due) {
    final now = DateTime.now();
    final diff = due.difference(DateTime(now.year, now.month, now.day));
    if (diff.inDays == 0) return 'TODAY';
    if (diff.inDays == 1) return 'TOMORROW';
    return DateFormat('dd MMM').format(due).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return StreamBuilder<List<Task>>(
      stream: FirestoreService().getTasks(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor),
            ),
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          final err = snapshot.error?.toString() ?? 'unknown error';
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor),
            ),
            child: Text('Error loading tasks: $err', style: const TextStyle(color: Colors.red)),
          );
        }

        final tasks = snapshot.data ?? [];
        final myTasks = tasks.where((t) => t.assignedToId == currentUserId).toList();

        if (myTasks.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.task_alt_outlined, size: 28, color: primaryColor),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text("NO TASKS",
                          style: TextStyle(
                              color: primaryColor,
                              fontFamily: appFontFamily,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                              letterSpacing: 1.0)),
                      SizedBox(height: 6),
                      Text("You have no assigned tasks",
                          style: TextStyle(
                              color: textColor,
                              fontFamily: appFontFamily,
                              fontWeight: FontWeight.w800,
                              fontSize: 16)),
                    ],
                  ),
                )
              ],
            ),
          );
        }

        myTasks.sort((a, b) => a.dueDate.compareTo(b.dueDate));
        final nearest = myTasks.first;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.task_alt_outlined, size: 28, color: primaryColor),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_dateLabel(nearest.dueDate),
                        style: const TextStyle(
                            color: primaryColor,
                            fontFamily: appFontFamily,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                            letterSpacing: 1.0)),
                    const SizedBox(height: 2),
                    Text(nearest.title,
                        style: const TextStyle(
                            color: textColor,
                            fontFamily: appFontFamily,
                            fontWeight: FontWeight.w800,
                            fontSize: 16)),
                    Text('Due: ${DateFormat('dd.MM.yyyy HH:mm').format(nearest.dueDate)}',
                        style: const TextStyle(
                            color: lightTextColor,
                            fontFamily: appFontFamily,
                            fontSize: 12)),
                  ],
                ),
              )
            ],
          ),
        );
      },
    );
  }
}

// --- INTERAKTYWNA LISTA ZAKUPÓW ---
class _ShoppingCard extends StatelessWidget {
  const _ShoppingCard(); // Usuń state, teraz to Stateless

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: FirestoreService().getShoppingList(),
      builder: (context, snapshot) {
        final items = (snapshot.data ?? []).take(3).toList(); // Pokaż max 3
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: borderColor)),
          child: Column(
            children: [
               if (items.isEmpty) const Text("List is empty! Add something.", style: TextStyle(color: lightTextColor)),
               for (var item in items)
                 GestureDetector(
                    onTap: () => FirestoreService().toggleShoppingItemStatus(item['id'], item['isBought'] ?? false),
                    child: Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Row(children: [
                        Icon(item['isBought'] == true ? Icons.check_circle : Icons.circle_outlined, color: item['isBought'] == true ? primaryColor : borderColor),
                        const SizedBox(width: 12),
                        Text(item['name'], style: TextStyle(decoration: item['isBought'] == true ? TextDecoration.lineThrough : null)),
                    ])),
                 )
            ],
          ),
        );
      }
    );
  }
}



class _ShoppingItem extends StatelessWidget {
  final String name;
  final bool isPriority;
  final bool isBought;
  final VoidCallback onTap;

  const _ShoppingItem({
    super.key,
    required this.name,
    required this.isPriority,
    required this.isBought,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 4), // Mniejszy odstęp
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          // Subtelne tło dla zrobionych zakupów
          color: isBought ? surfaceColor.withOpacity(0.5) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              isBought
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color:
                  isBought ? primaryColor : borderColor, // Szary jak nieaktywny
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontFamily: appFontFamily,
                  color: isBought ? lightTextColor : textColor,
                  decoration: isBought ? TextDecoration.lineThrough : null,
                  decorationColor: lightTextColor,
                ),
              ),
            ),
            if (isPriority && !isBought)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Priority',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontFamily: appFontFamily,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          color: textColor,
          fontFamily: appFontFamily,
          fontSize: 18,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
      ),
    );
  }
}
