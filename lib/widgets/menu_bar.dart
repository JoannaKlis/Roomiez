import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:roomies/screens/dashboard_screen.dart';
import 'package:roomies/services/firestore_service.dart';
import '../constants.dart';

// --- IMPORTY EKRANÓW ---
import '../screens/home_screen.dart'; 
import '../screens/tasks_screen.dart';
import '../screens/expenses_screen.dart';
import '../screens/login_screen.dart';
import '../screens/members_screen.dart';
import '../screens/shopping_list_screen.dart'; // <--- DODANO: Import listy zakupów

class CustomDrawer extends StatelessWidget {
  final String groupId;
  final String roomName;
  final String currentRoute; 

  CustomDrawer({
    super.key,
    required this.groupId,
    required this.roomName,
    this.currentRoute = 'dashboard', 
  });

  final FirestoreService _firestoreService = FirestoreService();

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

void _showExitGroupDialog(BuildContext context) {
  bool isProcessing = false; // zmienna do blokady przycisku 'Yes'
  final parentContext = context;

  showDialog(
    context: parentContext,
    barrierDismissible: false,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (sbContext, setState) {
          //styl okienka (zaokrąglenie krawędzi, rozmieszczenie elementów i tekstu)
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Exit group?'),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(dialogContext).pop(), //zamknięcie okna po kliknięciu X
                ),
              ],
            ),
            content: const Text('Are you sure you want to exit the group?'), //treść komunikatu
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(), //zamknięcie okna po kliknięciu anuluj
                child: const Text('Cancel'),
              ),
              TextButton(
              onPressed: isProcessing // konstrukcja zabezpieczająca przed wielokrotnym wykonaniem wyjścia z grupy w jednej chwili 
                  ? null //  przypadek brzegowy, kliknięcie 'tak' szybko kilka razy
                  : () async {
                      setState(() => isProcessing = true);
                        try {
                          await _firestoreService.userExitsAGroup(); //funkcja usuwająca użytkownika z bazy
                          if (parentContext.mounted) { // przeniesienie na ekran dołączania/tworzenia grupy jeśli widget widoczny
                            Navigator.of(parentContext).pushAndRemoveUntil(
                              MaterialPageRoute(builder: (_) => const DashboardScreen()),
                              (route) => false, //usunięcie poprzednich ekranów ze stosu. Po wyjściu z grupy nie powinno być możliwości powrotu
                            );
                          }
                        } catch (e) {
                          debugPrint('Error exiting group: $e');
                        }
                      },
              style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
              child: const Text('Yes'),
            ),
            ],
          );
        },
      );
    },
  );
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
            // --- NAGŁÓWEK ---
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 40, 24, 20),
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
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
                    isActive: currentRoute == 'dashboard' || currentRoute == '',
                    onTap: () {
                      Navigator.pop(context);
                      if (currentRoute != 'dashboard' && currentRoute != '') {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const HomeScreen(),
                          ),
                          (route) => false,
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
                        Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const TasksScreen()));
                      }
                    },
                  ),
                  
                  // --- SHOPPING LIST (TERAZ DZIAŁA) ---
                  _DrawerItem(
                    icon: Icons.shopping_cart_outlined,
                    label: 'Shopping List',
                    isActive: currentRoute == 'shopping',
                    onTap: () {
                      Navigator.pop(context);
                      if (currentRoute != 'shopping') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ShoppingScreen()),
                        );
                      }
                    },
                  ),
                  
                  // --- MEMBERS ---
                  _DrawerItem(
                    icon: Icons.group_outlined,
                    label: 'Members',
                    isActive: currentRoute == 'members',
                    onTap: () {
                      Navigator.pop(context);
                      if (currentRoute != 'members') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const MembersScreen()),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
            const Divider(color: borderColor, height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Column(
                children: [
                  _DrawerItem(
                    icon: Icons.waving_hand_outlined,
                    label: 'Exit current group',
                    textColor: Colors.redAccent,
                    iconColor: Colors.redAccent,
                    onTap: () => _showExitGroupDialog(context),
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