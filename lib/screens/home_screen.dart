import 'package:flutter/material.dart';
import 'package:roomies/services/firestore_service.dart';
import '../constants.dart';
import 'tasks_screen.dart';
import 'expenses_screen.dart';
import 'announcements_screen.dart';
import 'profile_edit_screen.dart'; // Używamy dla ProfileEditScreen.id
import 'navigation_screen.dart';
import '../widgets/menu_bar.dart' as mb;

class HomeScreen extends StatelessWidget {
  final String roomName;
  final String groupId;

  const HomeScreen({
    super.key,
    required this.roomName, required this.groupId
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,

      // --- APP BAR ---
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
leading: Builder(
  builder: (context) => IconButton(
    icon: const Icon(Icons.menu, size: 30, color: textColor),
    onPressed: () {
      Scaffold.of(context).openDrawer();
    },
  ),
),

        title: Column(
          children: [
            const Text(
              'ROOMIEZ',
              style: TextStyle(
                color: textColor,
                fontFamily: appFontFamily,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                fontSize: 22,
              ),
            ),
            Text(
              roomName,
              style: const TextStyle(
                color: lightTextColor,
                fontFamily: appFontFamily,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, size: 30, color: textColor),
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
                mainAxisSize:
                    MainAxisSize.min, // Ogranicza szerokość Row do zawartości
                mainAxisAlignment:
                    MainAxisAlignment.center, // Centruje zawartość
                children: [
                  // Powitanie
                  const Text(
                    'Hello, Jack!',
                    style: TextStyle(
                      fontSize: 26,
                      fontFamily: appFontFamily,
                      fontWeight: FontWeight.w900,
                      color: textColor,
                    ),
                  ),
                  // Ikonka edycji profilu
                  IconButton(
                    icon: const Icon(
                      Icons.edit, // Ikonka ołówka/edytowania
                      color: lightTextColor, // Używamy jaśniejszego koloru
                      size: 26,
                    ),
                    // Używamy minimalnego paddingu/ograniczeń dla lepszego dopasowania
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      // Nawigacja do ekranu edycji profilu
                      Navigator.pushNamed(context, ProfileEditScreen.id);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 25), // Odstęp po sekcji powitania

              // --- KAFELKI NAWIGACYJNE (Add Task / Announcements) ---
              Row(
                // Dodanie const do Row
                children: [
                  Expanded(
                    child: _SquareActionCard(
                      icon: Icons.check_circle_outline,
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
                  SizedBox(width: 15),
                  Expanded(
                    child: _SquareActionCard(
                        icon: Icons.error_outline,
                        label: 'Announcements',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AnnouncementsScreen(),
                            ),
                          );
                        }),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // --- SEKCJA: WYDATKI ---
              const _SectionHeader(title: 'Recent expenses'),
              const SizedBox(height: 10),
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
              const SizedBox(height: 10),
              const _CleaningCard(),

              const SizedBox(height: 30),

              // --- SEKCJA: LISTA ZAKUPÓW (TERAZ INTERAKTYWNA) ---
              const _SectionHeader(title: 'Shopping list'),
              const SizedBox(height: 10),
              const _ShoppingCard(), // To teraz jest StatefulWidget

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
      drawer: mb.MenuBar(roomName: roomName, groupId: groupId),
    );
  }
}

// ==========================================
// WIDŻETY POMOCNICZE
// ==========================================

class _SquareActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap; // Dodajemy ? aby mogło być null

  const _SquareActionCard({
    super.key, // Dodajemy super.key
    required this.icon,
    required this.label,
    this.onTap, // onTap jest teraz opcjonalny
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      // onTap: () {
      //   // Obsługa nawigacji w _SquareActionCard
      //   if (label == 'Add task') {
      //     ScaffoldMessenger.of(context).showSnackBar(
      //       const SnackBar(
      //         content: Text('Tu bedzie tasks screen'),
      //         duration: Duration(seconds: 2),
      //       ),
      //     );
      //   } else if (label == 'Announcements') {
      //     Navigator.push(
      //       context,
      //       MaterialPageRoute(builder: (context) => const AnnouncementsScreenPlaceholder()),
      //     );
      //   } else if (onTap != null) {
      //       onTap!();
      //   }
      // },
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: lightTextColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: textColor.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 45, color: textColor),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: textColor,
                fontFamily: appFontFamily,
                fontWeight: FontWeight.bold,
                fontSize: 16,
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

  const _ExpensesCard(
      {super.key, required this.onGoToExpenses}); // Dodanie super.key

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accentColor,
        borderRadius: BorderRadius.circular(20),
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
                          fontWeight: FontWeight.bold)),
                  Text('+50,00 PLN',
                      style: TextStyle(
                          color: textColor,
                          fontFamily: appFontFamily,
                          fontSize: 22,
                          fontWeight: FontWeight.w900)),
                ],
              ),
              ElevatedButton(
                onPressed: onGoToExpenses,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Go to expenses',
                    style: TextStyle(
                        color: Colors.white, fontFamily: appFontFamily)),
              ),
            ],
          ),
          const Divider(color: lightTextColor, thickness: 1, height: 24),
          _expenseRow('Bread', 'Martin', '5,50 PLN', Icons.shopping_cart),
          const SizedBox(height: 12),
          _expenseRow('Rent', 'Ana', '600 PLN', Icons.receipt),
        ],
      ),
    );
  }

  Widget _expenseRow(String item, String who, String cost, IconData icon) {
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: lightTextColor,
          radius: 18,
          child: Icon(icon, color: textColor, size: 20),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontFamily: appFontFamily,
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
                color: textColor)),
      ],
    );
  }
}

class _CleaningCard extends StatelessWidget {
  const _CleaningCard({super.key}); // Dodanie const i super.key

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accentColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: lightTextColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child:
                const Icon(Icons.cleaning_services, size: 28, color: textColor),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text("It's your turn tomorrow!",
                    style: TextStyle(
                        color: lightTextColor,
                        fontFamily: appFontFamily,
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
                Text("Kitchen Cleaning",
                    style: TextStyle(
                        color: textColor,
                        fontFamily: appFontFamily,
                        fontWeight: FontWeight.w900,
                        fontSize: 17)),
                Text("Next in line: Ana",
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
  const _ShoppingCard({super.key}); // Dodanie const i super.key

  @override
  State<_ShoppingCard> createState() => _ShoppingCardState();
}

class _ShoppingCardState extends State<_ShoppingCard> {
  // Prosta lista, żeby symulować dane
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accentColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          // Użycie wyodrębnionego widżetu _ShoppingItem zamiast metody
          for (int i = 0; i < items.length; i++)
            _ShoppingItem(
              key: ValueKey(
                  items[i]['name']), // Dodanie ValueKey dla lepszej wydajności
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

// NOWY WIDŻET: Wyodrębnienie logiki wizualnej pojedynczego elementu listy zakupów
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
      onTap: onTap, // Kliknięcie gdziekolwiek w wiersz
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          border: isPriority
              ? Border.all(color: Colors.redAccent, width: 1.5)
              : null,
          borderRadius: BorderRadius.circular(12),
          color: isBought ? Colors.grey.withOpacity(0.1) : Colors.transparent,
        ),
        child: Row(
          children: [
            // IKONKA: Ptaszek lub puste kółko
            Icon(
              isBought ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isBought ? primaryColor : textColor,
            ),
            const SizedBox(width: 10),

            // NAZWA PRODUKTU
            Text(
              name,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: appFontFamily,
                color: isBought ? lightTextColor : textColor,
                decoration: isBought
                    ? TextDecoration.lineThrough
                    : null, // Przekreślenie
              ),
            ),

            const Spacer(),

            // OZNACZENIE PRIORYTETU
            if (isPriority)
              const Text(
                'Priority',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontFamily: appFontFamily,
                  fontWeight: FontWeight.bold,
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
  const _SectionHeader(
      {super.key, required this.title}); // Dodanie const i super.key

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          color: textColor,
          fontFamily: appFontFamily,
          fontSize: 19,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

// --- TYMCZASOWA ZAŚLEPKA DLA OGŁOSZEŃ ---
class AnnouncementsScreenPlaceholder extends StatelessWidget {
  const AnnouncementsScreenPlaceholder(
      {super.key}); // Dodanie const i super.key

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: textColor),
        title: const Text('Announcements',
            style: TextStyle(color: textColor, fontFamily: appFontFamily)),
      ),
      body: const Center(
        child: Text('Tu będą ogłoszenia od Landlorda! 🏠',
            style: TextStyle(color: textColor, fontFamily: appFontFamily)),
      ),
    );
  }
}
