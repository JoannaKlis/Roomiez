import 'package:flutter/material.dart';
import 'package:roomies/services/firestore_service.dart';
import '../constants.dart';
import 'tasks_screen.dart';
import 'expenses_screen.dart';
import 'announcements_screen.dart';
import 'profile_edit_screen.dart';
import '../widgets/menu_bar.dart';

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
            icon: const Icon(Icons.notifications_none_rounded,
                size: 28, color: textColor),
            onPressed: () {},
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

              // --- SEKCJA: GRAFIK ---
              const _SectionHeader(title: 'Cleaning schedule'),
              const SizedBox(height: 12),
              const _CleaningCard(),

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
  final VoidCallback onGoToExpenses;

  const _ExpensesCard({super.key, required this.onGoToExpenses});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: textColor.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Your balance',
                      style: TextStyle(
                          color: lightTextColor,
                          fontFamily: appFontFamily,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                  SizedBox(height: 4),
                  Text('+50,00 PLN',
                      style: TextStyle(
                          color: textColor,
                          fontFamily: appFontFamily,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5)),
                ],
              ),
              ElevatedButton(
                onPressed: onGoToExpenses,
                style: ElevatedButton.styleFrom(
                  backgroundColor: textColor, // Ciemny przycisk dla kontrastu
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('See details',
                    style: TextStyle(
                        color: Colors.white, fontFamily: appFontFamily)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _expenseRow('Bread', 'Martin', '5,50 PLN', Icons.shopping_cart_outlined),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12.0),
            child: Divider(color: borderColor, height: 1),
          ),
          _expenseRow('Rent', 'Ana', '600 PLN', Icons.receipt_long_outlined),
        ],
      ),
    );
  }

  Widget _expenseRow(String item, String who, String cost, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: textColor, size: 20),
        ),
        const SizedBox(width: 15),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontFamily: appFontFamily,
                    fontSize: 15,
                    color: textColor)),
            Text(who,
                style: const TextStyle(
                    fontSize: 12,
                    fontFamily: appFontFamily,
                    color: lightTextColor)),
          ],
        ),
        const Spacer(),
        Text(cost,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: appFontFamily,
                fontSize: 15,
                color: textColor)),
      ],
    );
  }
}

class _CleaningCard extends StatelessWidget {
  const _CleaningCard({super.key});

  @override
  Widget build(BuildContext context) {
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
            child: const Icon(Icons.cleaning_services_outlined,
                size: 28, color: primaryColor),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text("TOMORROW",
                    style: TextStyle(
                        color: primaryColor,
                        fontFamily: appFontFamily,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                        letterSpacing: 1.0)),
                SizedBox(height: 2),
                Text("Kitchen Cleaning",
                    style: TextStyle(
                        color: textColor,
                        fontFamily: appFontFamily,
                        fontWeight: FontWeight.w800,
                        fontSize: 16)),
                Text("Next: Ana (Bathroom)",
                    style: TextStyle(
                        color: lightTextColor,
                        fontFamily: appFontFamily,
                        fontSize: 12)),
              ],
            ),
          )
        ],
      ),
    );
  }
}

// --- INTERAKTYWNA LISTA ZAKUPÓW ---
class _ShoppingCard extends StatefulWidget {
  const _ShoppingCard({super.key});

  @override
  State<_ShoppingCard> createState() => _ShoppingCardState();
}

class _ShoppingCardState extends State<_ShoppingCard> {
  List<Map<String, dynamic>> items = [
    {'name': 'Toilet paper', 'isPriority': true, 'isBought': false},
    {'name': 'Milk', 'isPriority': false, 'isBought': false},
    {'name': 'Dish soap', 'isPriority': false, 'isBought': false},
  ];

  void _toggleItem(int index) {
    setState(() {
      items[index]['isBought'] = !items[index]['isBought'];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8), // Mniejszy padding kontenera
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++)
            _ShoppingItem(
              key: ValueKey(items[i]['name']),
              name: items[i]['name'],
              isPriority: items[i]['isPriority'],
              isBought: items[i]['isBought'],
              onTap: () => _toggleItem(i),
            ),
        ],
      ),
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
              color: isBought ? primaryColor : borderColor, // Szary jak nieaktywny
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