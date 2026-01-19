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

class CustomDrawer extends StatefulWidget {
  final String groupId;
  final String roomName;
  final String currentRoute; 

  CustomDrawer({
    super.key,
    required this.groupId,
    required this.roomName,
    this.currentRoute = 'dashboard', 
  });

  @override
  State<CustomDrawer> createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> {
  final FirestoreService _firestoreService = FirestoreService();
  bool _isApartmentManager = false;
  bool _isLoadingRole = true;

  @override
  void initState() {
    super.initState();
    _checkIfManager();
  }

  Future<void> _checkIfManager() async {
    try {
      final isManager = await _firestoreService.isCurrentUserApartmentManager(widget.groupId);
      if (mounted) {
        setState(() {
          _isApartmentManager = isManager;
          _isLoadingRole = false;
        });
      }
    } catch (e) {
      debugPrint('Error checking manager status: $e');
      if (mounted) {
        setState(() {
          _isLoadingRole = false;
        });
      }
    }
  }

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: widget.groupId));
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
    bool isProcessing = false;
    final parentContext = context;

    showDialog(
      context: parentContext,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (sbContext, setState) {
            return FutureBuilder<Map<String, dynamic>>(
              future: _firestoreService.getExitSummary(),
              builder: (ctx, snapshot) {
                // Loader podczas pobierania danych
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    content: const SizedBox(
                      height: 100,
                      child: Center(child: CircularProgressIndicator(color: primaryColor)),
                    ),
                  );
                }

                final summaryData = snapshot.data ?? 
                    {'debtAmount': 0.0, 'incompleteTasks': 0, 'pendingSettlements': 0, 'isManager': false};
                
                final debtAmount = (summaryData['debtAmount'] as num?)?.toDouble() ?? 0.0;
                final incompleteTasks = summaryData['incompleteTasks'] as int? ?? 0;
                final pendingSettlements = summaryData['pendingSettlements'] as int? ?? 0; // NOWE
                final isManager = summaryData['isManager'] as bool? ?? false;
                
                final hasDebts = debtAmount > 0.01;
                final hasTasks = incompleteTasks > 0;
                final hasPendingSettlements = pendingSettlements > 0; // NOWE

                // --- BLOKADA: Jeśli są wiszące rozliczenia ---
                if (hasPendingSettlements) {
                  return AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    title: const Row(
                      children: [
                        Icon(Icons.error_outline_rounded, color: Colors.red, size: 28),
                        SizedBox(width: 12),
                        Text('Cannot Exit', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'You have $pendingSettlements pending settlement(s).',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'You cannot leave the group while you have payments waiting for confirmation (either sent by you or waiting for your approval).',
                          style: TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Please confirm or cancel them in the Expenses tab before leaving.',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  );
                }

                // --- STANDARDOWE OSTRZEŻENIA (Jeśli brak blokady) ---
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
                        onPressed: () => Navigator.of(dialogContext).pop(),
                      ),
                    ],
                  ),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Ostrzeżenie o długach
                        if (hasDebts) ...[
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.red.withOpacity(0.4), width: 2),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.warning_rounded, color: Colors.red, size: 24),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'You have debts!',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.red,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'You owe: ${debtAmount.toStringAsFixed(2)} PLN',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Leaving now will delete your history, but you technically still owe this money.',
                                  style: TextStyle(fontSize: 11, color: Colors.red),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Ostrzeżenie dla Managera
                        if (isManager) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.amber.withOpacity(0.5)),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.admin_panel_settings, color: Colors.amber, size: 20),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'You are the Manager. Role will be auto-transferred.',
                                    style: TextStyle(fontSize: 12, color: Colors.amber),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Ostrzeżenie o zadaniach
                        if (hasTasks) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.orange.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.task_alt_rounded, color: Colors.orange, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  '$incompleteTasks incomplete task(s) will be removed.',
                                  style: const TextStyle(fontSize: 12, color: Colors.orange),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        if (!hasDebts && !hasTasks && !isManager)
                          const Text(
                            'Are you sure you want to leave? You will need an invite code to join again.',
                            style: TextStyle(fontSize: 14),
                          ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: isProcessing
                          ? null
                          : () async {
                              setState(() => isProcessing = true);
                              try {
                                await _firestoreService.userExitsAGroup();
                                if (parentContext.mounted) {
                                  Navigator.of(parentContext).pushAndRemoveUntil(
                                    MaterialPageRoute(builder: (_) => const DashboardScreen()),
                                    (route) => false,
                                  );
                                }
                              } catch (e) {
                                debugPrint('Error exiting group: $e');
                                setState(() => isProcessing = false);
                              }
                            },
                      style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                      child: const Text('Yes, Exit'),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

void _showResetExpensesDialog(BuildContext context) {
  bool isProcessing = false;
  final parentContext = context;

  showDialog(
    context: parentContext,
    barrierDismissible: false,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (sbContext, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Reset all expenses?'),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(dialogContext).pop(),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.withOpacity(0.4), width: 2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.warning_rounded, color: Colors.orange, size: 24),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'This action cannot be undone!',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'This will:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '• Delete ALL expenses in the group\n• Reset everyone\'s balance to 0.00 PLN\n• Clear all pending settlement requests',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: isProcessing
                    ? null
                    : () async {
                        setState(() => isProcessing = true);
                        try {
                          await _firestoreService.deleteAllExpenses();
                          if (parentContext.mounted) {
                            Navigator.of(parentContext).pop();
                            ScaffoldMessenger.of(parentContext).showSnackBar(
                              const SnackBar(
                                content: Text('All expenses have been reset!'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        } catch (e) {
                          debugPrint('Error resetting expenses: $e');
                          if (parentContext.mounted) {
                            ScaffoldMessenger.of(parentContext).showSnackBar(
                              SnackBar(
                                content: Text('Error: $e'),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        }
                      },
                style: TextButton.styleFrom(foregroundColor: Colors.orange),
                child: const Text('Yes, Reset All'),
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
                      widget.roomName.isNotEmpty ? widget.roomName : 'My Place',
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
            
            // --- KARTA KODU ZAPROSZENIA (Tylko dla apartment managera) ---
            if (_isLoadingRole)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: const SizedBox(
                  height: 40,
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            else if (_isApartmentManager)
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
                            widget.groupId,
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
                    isActive: widget.currentRoute == 'dashboard' || widget.currentRoute == '',
                    onTap: () {
                      Navigator.pop(context);
                      if (widget.currentRoute != 'dashboard' && widget.currentRoute != '') {
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
                    isActive: widget.currentRoute == 'expenses',
                    onTap: () {
                      Navigator.pop(context);
                      if (widget.currentRoute != 'expenses') {
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
                    isActive: widget.currentRoute == 'tasks',
                    onTap: () {
                      Navigator.pop(context);
                      if (widget.currentRoute != 'tasks') {
                        Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const TasksScreen()));
                      }
                    },
                  ),
                  
                  // --- SHOPPING LIST (TERAZ DZIAŁA) ---
                  _DrawerItem(
                    icon: Icons.shopping_cart_outlined,
                    label: 'Shopping List',
                    isActive: widget.currentRoute == 'shopping',
                    onTap: () {
                      Navigator.pop(context);
                      if (widget.currentRoute != 'shopping') {
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
                    isActive: widget.currentRoute == 'members',
                    onTap: () {
                      Navigator.pop(context);
                      if (widget.currentRoute != 'members') {
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
            
            // --- MANAGER OPTIONS ---
            if (_isApartmentManager)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Column(
                  children: [
                    _DrawerItem(
                      icon: Icons.delete_sweep_rounded,
                      label: 'Reset all expenses',
                      textColor: Colors.orangeAccent,
                      iconColor: Colors.orangeAccent,
                      onTap: () => _showResetExpensesDialog(context),
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