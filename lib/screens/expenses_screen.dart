import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../constants.dart'; // Twoje stałe (primaryColor, backgroundColor, fonts...)
import '../models/expense_history_item.dart';
import '../services/firestore_service.dart';
import 'navigation_screen.dart';
import '../widgets/menu_bar.dart' as mb;

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  // --- ZARZĄDZANIE STANEM (Logika bez zmian) ---

  final FirestoreService _firestoreService = FirestoreService();
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  String _groupName = 'Loading...';
  String _userGroupId = '';
  bool _hasGroupError = false;

  int _selectedToggleIndex = 0;
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  Map<String, String> _splitWith = {};
  List<Map<String, String>> _roomies = [];
  bool _isLoadingRoomies = true;

  final double _netBalance = 50.00;
  bool _isNewExpenseFormVisible = false;

  // Symulacja backendu
  final Set<String> _mockMarkedAsPaid = {};
  final Set<String> _mockConfirmedReceived = {};

  @override
  void initState() {
    super.initState();
    if (_currentUserId.isNotEmpty) {
      _loadGroupData();
    } else {
      _isLoadingRoomies = false;
      _hasGroupError = true;
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _loadGroupData() async {
    try {
      final groupId = await _firestoreService.getCurrentUserGroupId();
      final name = await _firestoreService.getGroupName(groupId);
      final users = await _firestoreService.getCurrentApartmentUsers(groupId);

      if (mounted) {
        final Map<String, String> initialSplit = {};
        for (var user in users) {
          initialSplit[user['id']!] = 'true';
        }

        setState(() {
          _userGroupId = groupId;
          _groupName = name;
          _roomies = users;
          _splitWith = initialSplit;
          _isLoadingRoomies = false;
        });
      }
    } catch (e) {
      print('Group Loading Error: $e');
      if (mounted) {
        setState(() {
          _groupName = 'No group found';
          _isLoadingRoomies = false;
          _hasGroupError = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  void _addNewExpense() {
    final amount = double.tryParse(_amountController.text);
    final participantsIds = _splitWith.entries
        .where((e) => e.value == 'true')
        .map((e) => e.key)
        .toList();

    if (_descriptionController.text.isEmpty ||
        amount == null ||
        amount <= 0 ||
        participantsIds.isEmpty ||
        _userGroupId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(_userGroupId.isEmpty
                ? 'Error: You must belong to a group to add expenses.'
                : 'Please fill in details and select participants.'),
            backgroundColor: Colors.red),
      );
      return;
    }

    final newExpense = ExpenseHistoryItem(
      id: '', // Firestore nada ID, ale tu placeholder
      description: _descriptionController.text.trim(),
      payerId: _currentUserId,
      amount: amount,
      date: DateTime.now(),
      participantsIds: participantsIds,
      groupId: _userGroupId,
    );

    _firestoreService.addExpense(newExpense).then((_) {
      setState(() {
        _isNewExpenseFormVisible = false;
        _descriptionController.clear();
        _amountController.clear();
        _splitWith.updateAll((key, value) => 'true');
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Expense added successfully!'),
            backgroundColor: primaryColor),
      );
    }).catchError((e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error adding expense: $e'),
            backgroundColor: Colors.red),
      );
    });
  }

  String _getSubtext(ExpenseHistoryItem item) {
    final payer = _roomies.firstWhere((user) => user['id'] == item.payerId,
        orElse: () => {'name': 'Unknown User'});

    final payerName = item.payerId == _currentUserId ? 'You' : payer['name'];
    final splitCount = item.participantsIds.length;
    final currencyFormat =
        NumberFormat.currency(locale: 'pl_PL', symbol: 'PLN');

    if (splitCount == 1) {
      return '$payerName paid (not split)';
    }

    final shareAmount = item.amount / splitCount;
    final shareText = currencyFormat.format(shareAmount);

    return '$payerName paid. Split $shareText each';
  }

  // --- BUDOWANIE INTERFEJSU (UI) ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: CustomScrollView(
        slivers: [
          // --- APP BAR (Clean Style) ---
          SliverAppBar(
            backgroundColor: backgroundColor,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            floating: true,
            pinned: true,
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
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: primaryColor,
                    fontFamily: 'StackSansNotch', // Twoja czcionka
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  _groupName.isNotEmpty ? _groupName.toUpperCase() : '',
                  style: const TextStyle(
                    fontSize: 10,
                    color: lightTextColor,
                    fontWeight: FontWeight.bold,
                    fontFamily: appFontFamily,
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

          // --- GŁÓWNA ZAWARTOŚĆ ---
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
            sliver: SliverList(
              delegate: SliverChildListDelegate(
                [
                  // WYŚRODKOWANY NAPIS EXPENSES
                  const Center(
                    child: Text(
                      'Expenses',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                        fontFamily: appFontFamily,
                        letterSpacing: -1.0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Karta Balansu (Teraz Jasna)
                  _buildBalanceCard(),
                  const SizedBox(height: 20),

                  // Formularz (Animowany)
                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    child: Container(
                      child: _isNewExpenseFormVisible
                          ? Column(
                              children: [
                                _buildNewExpenseForm(),
                                const SizedBox(height: 20),
                              ],
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),

                  // Przełączniki (All / Owed / Lent)
                  _buildToggleButtons(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          
          // Lista wydatków
          _buildExpensesList(),
          
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
      drawer: mb.CustomDrawer(
        roomName: _groupName, 
        groupId: _userGroupId,
        currentRoute: 'expenses', 
      ),
    );
  }

  // --- WIDGETY POMOCNICZE (Clean UI) ---

  /// Karta "Your balance" - WERSJA JASNA (Light Theme)
  Widget _buildBalanceCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: surfaceColor, // Jasnoszary zamiast czarnego
        borderRadius: BorderRadius.circular(24),
        // Usunąłem cień, żeby było bardziej płasko, albo można dać bardzo delikatny
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your Balance',
                style: TextStyle(
                  color: lightTextColor, // Ciemniejszy szary dla tekstu
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  fontFamily: appFontFamily,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${_netBalance >= 0 ? '+' : ''}${_netBalance.toStringAsFixed(2)} PLN',
                style: const TextStyle(
                  color: textColor, // Ciemny tekst (czarny)
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  fontFamily: appFontFamily,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          // Przycisk "+" (Action Button)
          Material(
            color: primaryColor, // Kolor przewodni
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: () {
                setState(() {
                  _isNewExpenseFormVisible = !_isNewExpenseFormVisible;
                });
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Icon(
                      _isNewExpenseFormVisible ? Icons.close : Icons.add,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isNewExpenseFormVisible ? 'Close' : 'Add',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontFamily: appFontFamily,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Formularz dodawania nowego wydatku - Czysty styl
  Widget _buildNewExpenseForm() {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("New Expense", 
            style: TextStyle(
              fontSize: 18, 
              fontWeight: FontWeight.bold, 
              color: textColor,
              fontFamily: appFontFamily
            )
          ),
          const SizedBox(height: 16),
          
          TextField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              hintText: 'What is this for?',
              prefixIcon: Icon(Icons.description_outlined, color: lightTextColor),
            ),
            style: const TextStyle(color: textColor, fontFamily: appFontFamily),
          ),
          const SizedBox(height: 12),
          
          TextField(
            controller: _amountController,
            decoration: const InputDecoration(
              hintText: 'Amount',
              prefixIcon: Icon(Icons.attach_money_rounded, color: lightTextColor),
              suffixText: 'PLN',
            ),
            style: const TextStyle(color: textColor, fontFamily: appFontFamily),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 16),

          const Text("Split with:", 
            style: TextStyle(
              fontSize: 14, 
              fontWeight: FontWeight.w600, 
              color: lightTextColor,
              fontFamily: appFontFamily
            )
          ),
          const SizedBox(height: 8),

          // Lista współlokatorów
          Column(
            children: _roomies.map((user) {
              final userId = user['id']!;
              final userName = user['name']!;
              final isSelected = _splitWith[userId] == 'true';

              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      if (userId != _currentUserId) {
                        _splitWith[userId] = isSelected ? 'false' : 'true';
                      }
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? primaryColor.withOpacity(0.05) : surfaceColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? primaryColor : Colors.transparent,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
                          color: isSelected ? primaryColor : lightTextColor,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          userName,
                          style: TextStyle(
                            color: textColor,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            fontFamily: appFontFamily,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Przycisk "SUBMIT"
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _addNewExpense,
              child: const Text('Add Expense'),
            ),
          ),
        ],
      ),
    );
  }

  /// Przełączniki "All" / "Owed" / "Lent" - Styl pastylek
  Widget _buildToggleButtons() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(child: _buildToggleButton('All', 0)),
          Expanded(child: _buildToggleButton('Owed', 1)),
          Expanded(child: _buildToggleButton('Lent', 2)),
        ],
      ),
    );
  }

  Widget _buildToggleButton(String text, int index) {
    final isSelected = _selectedToggleIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedToggleIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: textColor.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ]
              : [],
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? textColor : lightTextColor,
            fontFamily: appFontFamily,
          ),
        ),
      ),
    );
  }

  /// Lista wydatków (filtrowana)
  Widget _buildExpensesList() {
    return StreamBuilder<List<ExpenseHistoryItem>>(
      stream: _firestoreService.getExpenses(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverToBoxAdapter(
            child: Center(child: Padding(
              padding: EdgeInsets.all(20.0),
              child: CircularProgressIndicator(color: primaryColor),
            )),
          );
        }
        if (snapshot.hasError) {
          return SliverToBoxAdapter(
            child: Center(
                child: Text('Error loading expenses',
                    style: const TextStyle(color: Colors.red, fontFamily: appFontFamily))),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SliverToBoxAdapter(
              child: Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 40.0),
                    child: Text('No expenses yet',
                        style: TextStyle(color: lightTextColor, fontFamily: appFontFamily)),
                  )));
        }

        final allTransactions = snapshot.data!;

        final filteredTransactions = allTransactions.where((item) {
          if (_selectedToggleIndex == 1) {
            // Owed
            return item.participantsIds.contains(_currentUserId) &&
                item.payerId != _currentUserId;
          }
          if (_selectedToggleIndex == 2) {
            // Lent
            return item.payerId == _currentUserId &&
                item.participantsIds.length > 1;
          }
          return true; // All
        }).toList();

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final item = filteredTransactions[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: _buildExpenseListItem(item),
              );
            },
            childCount: filteredTransactions.length,
          ),
        );
      },
    );
  }

  /// Pojedynczy element na liście wydatków (Clean Style)
  Widget _buildExpenseListItem(ExpenseHistoryItem item) {
    final currencyFormat =
        NumberFormat.currency(locale: 'pl_PL', symbol: 'PLN');

    Color amountColor = textColor;
    String prefix = '';
    if (item.payerId == _currentUserId && item.participantsIds.length > 1) {
      amountColor = Colors.green;
      prefix = '+';
    } else if (item.participantsIds.contains(_currentUserId) &&
        item.payerId != _currentUserId) {
      amountColor = Colors.red;
      prefix = '-';
    }

    final displayAmount = "$prefix${currencyFormat.format(item.amount)}";
    final bool isMarkedAsPaid = _mockMarkedAsPaid.contains(item.id);
    final bool isConfirmed = _mockConfirmedReceived.contains(item.id);

    bool showActions = false;
    Widget? actionButton;

    // --- LOGIKA PRZYCISKÓW ---
    if (_selectedToggleIndex == 1) { // Owed
      showActions = true;
      if (isMarkedAsPaid) {
        actionButton = _buildStatusBadge("Waiting for approval", Colors.orange);
      } else {
        actionButton = _buildActionButton("Mark as Paid", Icons.send_rounded, () {
          setState(() { _mockMarkedAsPaid.add(item.id); });
        });
      }
    } else if (_selectedToggleIndex == 2) { // Lent
      showActions = true;
      if (isConfirmed) {
        actionButton = _buildStatusBadge("Settled", Colors.green);
      } else {
        actionButton = _buildActionButton("Confirm Receipt", Icons.thumb_up_rounded, () {
          setState(() { _mockConfirmedReceived.add(item.id); });
        });
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: textColor.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.receipt_long_rounded, color: textColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.description,
                      style: const TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        fontFamily: appFontFamily,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getSubtext(item),
                      style: const TextStyle(
                        color: lightTextColor, 
                        fontSize: 12,
                        fontFamily: appFontFamily,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    displayAmount,
                    style: TextStyle(
                      color: amountColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      fontFamily: appFontFamily,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('dd MMM').format(item.date),
                    style: const TextStyle(
                      color: lightTextColor, 
                      fontSize: 12,
                      fontFamily: appFontFamily,
                    ),
                  ),
                ],
              ),
            ],
          ),

          if (showActions) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Divider(color: borderColor, height: 1),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: actionButton ?? const SizedBox(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 8, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              fontFamily: appFontFamily,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, VoidCallback onPressed) {
    return TextButton.icon(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: primaryColor),
        ),
      ),
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: appFontFamily)),
    );
  }
}