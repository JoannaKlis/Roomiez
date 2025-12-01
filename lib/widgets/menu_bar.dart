import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants.dart';
// Importujemy ekrany
import '../screens/tasks_screen.dart';
import '../screens/expenses_screen.dart';
import '../screens/login_screen.dart';
import '../screens/home_screen.dart'; // <--- DODANO: Musimy widzieć HomeScreen

class CustomDrawer extends StatelessWidget {
  final String groupId;
  final String roomName;
  // Parametr opcjonalny (domyślnie pusty)
  final String currentRoute; 

  const CustomDrawer({
    super.key,
    required this.groupId,
    required this.roomName,
    this.currentRoute = '', 
  });

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

  void _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
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
        borderRadius: BorderRadius.zero,
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- NAGŁÓWEK (Bez logo, wyśrodkowany) ---
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 40, 24, 20),
              child: SizedBox(
                width: double.infinity, // Rozciąga na całą szerokość
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center, // Centruje w poziomie
                  children: [
                    const Text(
                      'ROOMIES',
                      style: TextStyle(
                        fontFamily: 'StackSansNotch',
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: primaryColor,
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
            ),
            
            // --- INVITE CODE ---
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
            
            // --- LISTA MENU ---
            const SizedBox(height: 10),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  // --- DASHBOARD (HOME) ---
                  _DrawerItem(
                    icon: Icons.dashboard_rounded,
                    label: 'Dashboard',
                    // Podświetla się, jeśli currentRoute to 'dashboard' lub puste (domyślnie Home)
                    isActive: currentRoute == 'dashboard' || currentRoute == '', 
                    onTap: () {
                      Navigator.pop(context); // Zamykamy drawer
                      
                      // Jeśli NIE jesteśmy na dashboardzie (tylko np. na Expenses), to nawigujemy
                      if (currentRoute != 'dashboard' && currentRoute != '') {
                         Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) => HomeScreen(
                                roomName: roomName,
                                groupId: groupId,
                              ),
                            ),
                            (route) => false, // Czyści historię wstecz
                         );
                      }
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
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const TasksScreen()));
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
                      // Tu dodaj nawigację do ShoppingScreen
                    },
                  ),
                  
                  // --- MEMBERS ---
                  _DrawerItem(
                    icon: Icons.group_outlined,
                    label: 'Members',
                    isActive: currentRoute == 'members',
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
            const Divider(color: borderColor, height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
              child: _DrawerItem(
                icon: Icons.logout_rounded,
                label: 'Log out',
                textColor: Colors.redAccent,
                iconColor: Colors.redAccent,
                onTap: () => _signOut(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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