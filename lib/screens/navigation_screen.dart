import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Do kopiowania (Clipboard)
import 'package:firebase_auth/firebase_auth.dart';
import '../constants.dart';
import '../screens/home_screen.dart'; // Import konieczny do nawigacji
import '../screens/tasks_screen.dart';
import '../screens/expenses_screen.dart';
import '../screens/login_screen.dart';

class NavigationMenuScreen extends StatelessWidget {
  final String groupId;
  final String roomName;
  // Dodajemy parametr, żeby wiedzieć, gdzie jesteśmy
  final String currentRoute;

  const NavigationMenuScreen({
    super.key,
    required this.groupId,
    required this.roomName,
    this.currentRoute = 'dashboard', // Domyślnie zakładamy, że to Dashboard/Home
  });

  // Funkcja kopiowania kodu zaproszenia
  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: groupId));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Invite code copied!'),
        backgroundColor: primaryColor,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 1),
      ),
    );
  }

  // Funkcja wylogowania
  void _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    // Czyścimy stos nawigacji i wracamy do logowania
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (Route<dynamic> route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: backgroundColor,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(0),
          bottomRight: Radius.circular(0),
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER ---
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 30, 24, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image.asset(
                    'assets/images/logo_roomies.png',
                    width: 50,
                    height: 50,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.home, size: 50, color: primaryColor),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'ROOMIES',
                    style: TextStyle(
                      fontFamily: 'StackSansNotch',
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: textColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    roomName.isNotEmpty ? roomName : 'My Place',
                    style: const TextStyle(
                      fontFamily: appFontFamily,
                      fontSize: 14,
                      color: lightTextColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // --- KARTA KODU ZAPROSZENIA ---
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'INVITE CODE',
                    style: TextStyle(
                      fontSize: 10,
                      color: lightTextColor,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          groupId,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                            fontFamily: 'Monospace',
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      InkWell(
                        onTap: () => _copyToClipboard(context),
                        borderRadius: BorderRadius.circular(8),
                        child: const Padding(
                          padding: EdgeInsets.all(6.0),
                          child: Icon(Icons.copy_rounded,
                              size: 18, color: primaryColor),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // --- LISTA OPCJI ---
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  // --- DASHBOARD ---
                  _DrawerItem(
                    icon: Icons.dashboard_rounded,
                    label: 'Dashboard',
                    isActive: currentRoute == 'dashboard', // Dynamiczne podświetlenie
                    onTap: () {
                      Navigator.pop(context); // 1. Zamykamy drawer
                      
                      // 2. Sprawdzamy: Jeśli NIE jesteśmy na dashboardzie, to nawigujemy
                      if (currentRoute != 'dashboard') {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => HomeScreen(
                              groupId: groupId,
                              roomName: roomName,
                            ),
                          ),
                          (route) => false, // Czyści historię wstecz
                        );
                      }
                      // Jeśli currentRoute == 'dashboard', nic więcej się nie dzieje (tylko zamknięcie drawera)
                    },
                  ),
                  
                  // --- EXPENSES ---
                  _DrawerItem(
                    icon: Icons.receipt_long_rounded,
                    label: 'Expenses',
                    isActive: currentRoute == 'expenses',
                    onTap: () {
                      Navigator.pop(context);
                      if (currentRoute != 'expenses') {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const ExpensesScreen()));
                      }
                    },
                  ),
                  
                  // --- TASKS ---
                  _DrawerItem(
                    icon: Icons.check_circle_outline_rounded,
                    label: 'Tasks',
                    isActive: currentRoute == 'tasks',
                    onTap: () {
                      Navigator.pop(context);
                      if (currentRoute != 'tasks') {
                        Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const TasksScreen()));
                      }
                    },
                  ),
                  
                  // --- SHOPPING LIST ---
                  _DrawerItem(
                    icon: Icons.shopping_cart_outlined,
                    label: 'Shopping List',
                    isActive: currentRoute == 'shopping',
                    onTap: () {
                      Navigator.pop(context);
                      // TODO: Ekran listy zakupów
                    },
                  ),
                  
                  // --- MEMBERS ---
                  _DrawerItem(
                    icon: Icons.group_outlined,
                    label: 'Members',
                    isActive: currentRoute == 'members',
                    onTap: () {
                      Navigator.pop(context);
                      // TODO: Ekran członków
                    },
                  ),
                ],
              ),
            ),

            // --- FOOTER (WYLOGOWANIE) ---
            const Divider(color: borderColor, height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Column(
                children: [
                  _DrawerItem(
                    icon: Icons.logout_rounded,
                    label: 'Log out',
                    textColor: Colors.redAccent,
                    iconColor: Colors.redAccent,
                    onTap: () => _signOut(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- WIDŻET POJEDYNCZEJ POZYCJI W MENU ---
class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isActive;
  final Color? textColor;
  final Color? iconColor;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isActive = false,
    this.textColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = textColor ?? (isActive ? primaryColor : textColor);
    final iconCol = iconColor ?? (isActive ? primaryColor : lightTextColor);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: isActive ? primaryColor.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(icon, size: 22, color: iconCol),
              const SizedBox(width: 16),
              Text(
                label,
                style: TextStyle(
                  fontFamily: appFontFamily,
                  fontSize: 15,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                  color: isActive ? primaryColor : (color ?? textColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}