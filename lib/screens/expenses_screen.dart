import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../constants.dart'; // Importowanie Twoich stałych kolorów
import '../models/expense_history_item.dart'; // Import modelu danych
import '../services/firestore_service.dart';
import 'navigation_screen.dart';
import '../widgets/menu_bar.dart' as mb;

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  // --- ZARZĄDZANIE STANEM (Logika) ---

  final FirestoreService _firestoreService = FirestoreService();
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  String _groupName = 'Loading...';
  String _userGroupId = '';
  // ignore: unused_field
  bool _hasGroupError = false;

  int _selectedToggleIndex = 0;
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  Map<String, String> _splitWith = {};

  List<Map<String, String>> _roomies = [];
  // ignore: unused_field
  bool _isLoadingRoomies = true;

  final double _netBalance =
      50.00; // tymczasowe saldo dopóki nie ma logiki dzielenia rachunków
  bool _isNewExpenseFormVisible = false;

  // --- SYMULACJA BACKENDU (Nowe zmienne) ---
  final Set<String> _mockMarkedAsPaid = {};
  final Set<String> _mockConfirmedReceived = {};

  // --- logika firestore ---
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
      id: '',
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
            backgroundColor: Colors.green),
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

    return '$payerName paid. Split $shareText each ($splitCount people)';
  }

  // --- BUDOWANIE INTERFEJSU (UI) ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // AppBar
          SliverAppBar(
            backgroundColor: backgroundColor,
            elevation: 0,
            floating: true,
            pinned: true,
            leading: Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu, color: textColor),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              ),
            ),
            title: Center(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'ROOMIES',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    fontFamily: appFontFamily,
                  ),
                ),
                Text(
                  _groupName,
                  style: const TextStyle(
                    fontSize: 14,
                    color: lightTextColor,
                    fontWeight: FontWeight.bold,
                    fontFamily: appFontFamily,
                  ),
                ),
              ],
            )),
            actions: [
              IconButton(
                icon:
                    const Icon(Icons.notifications_outlined, color: textColor),
                onPressed: () {},
              ),
            ],
          ),

          // Reszta zawartości ekranu
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate(
                [
                  const Center(
                    child: Text(
                      'Our expenses',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                        fontFamily: appFontFamily,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  _buildBalanceCard(),
                  const SizedBox(height: 20),

                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: Container(
                      height: _isNewExpenseFormVisible ? null : 0,
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

                  _buildToggleButtons(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          _buildExpensesList(),
        ],
      ),
      drawer: mb.CustomDrawer(roomName: _groupName, groupId: _userGroupId),
    );
  }

  // --- WIDGETY POMOCNICZE ---

  /// Karta "Your balance" - MODERN
  Widget _buildBalanceCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6), // Nowoczesne, jasne tło
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: textColor.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your balance',
                style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    fontFamily: appFontFamily),
              ),
              Text(
                '${_netBalance >= 0 ? '+' : ''}${_netBalance.toStringAsFixed(2)} PLN',
                style: TextStyle(
                  color: _netBalance >= 0 ? Colors.green[800] : Colors.red[800],
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: appFontFamily,
                ),
              ),
            ],
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _isNewExpenseFormVisible = !_isNewExpenseFormVisible;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: textColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              _isNewExpenseFormVisible ? 'Cancel' : 'New expense',
              style: const TextStyle(
                  color: backgroundColor, fontFamily: appFontFamily),
            ),
          ),
        ],
      ),
    );
  }

  /// Formularz dodawania nowego wydatku - MODERN
  Widget _buildNewExpenseForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: textColor.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          TextField(
            controller: _descriptionController,
            decoration: _buildFormInputDecoration(hintText: 'Description'),
            style: const TextStyle(color: textColor),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _amountController,
            decoration: _buildFormInputDecoration(hintText: 'Amount'),
            style: const TextStyle(color: textColor),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 10),
          ..._roomies.map((user) {
            final userId = user['id']!;
            final userName = user['name']!;

            return CheckboxListTile(
              title: Text(userName,
                  style: const TextStyle(
                      color: textColor, fontFamily: appFontFamily)),
              value: _splitWith[userId] == 'true',
              onChanged: (bool? value) {
                setState(() {
                  if (userId != _currentUserId) {
                    _splitWith[userId] = value == true ? 'true' : 'false';
                  }
                });
              },
              activeColor: textColor,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              visualDensity: VisualDensity.compact,
            );
          }).toList(),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _addNewExpense,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('SUBMIT',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontFamily: appFontFamily)),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _buildFormInputDecoration({required String hintText}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: textColor.withOpacity(0.5)),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(color: primaryColor, width: 2.0),
      ),
    );
  }

  /// Przełączniki "All" / "Owed" / "Lent" - MODERN
  Widget _buildToggleButtons() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(25),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: _buildToggleButton(
              text: 'All',
              isSelected: _selectedToggleIndex == 0,
              onPressed: () => setState(() => _selectedToggleIndex = 0),
            ),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: _buildToggleButton(
              text: 'Owed',
              isSelected: _selectedToggleIndex == 1,
              onPressed: () => setState(() => _selectedToggleIndex = 1),
            ),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: _buildToggleButton(
              text: 'Lent',
              isSelected: _selectedToggleIndex == 2,
              onPressed: () => setState(() => _selectedToggleIndex = 2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton({
    required String text,
    required bool isSelected,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? primaryColor : Colors.transparent,
        foregroundColor: isSelected ? Colors.white : textColor,
        elevation: isSelected ? 2 : 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12),
        shadowColor: Colors.transparent, // usuwa cień dla nieaktywnych
      ),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontFamily: appFontFamily,
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
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return SliverToBoxAdapter(
            child: Center(
                child: Text('Error loading expenses: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red))),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SliverToBoxAdapter(
              child: Center(
                  child: Text('No expenses found!',
                      style: TextStyle(color: textColor))));
        }

        final allTransactions = snapshot.data!;

        final filteredTransactions = allTransactions.where((item) {
          if (_selectedToggleIndex == 1) {
            return item.participantsIds.contains(_currentUserId) &&
                item.payerId != _currentUserId;
          }
          if (_selectedToggleIndex == 2) {
            return item.payerId == _currentUserId &&
                item.participantsIds.length > 1;
          }
          return true;
        }).toList();

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final item = filteredTransactions[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: _buildExpenseListItem(item),
              );
            },
            childCount: filteredTransactions.length,
          ),
        );
      },
    );
  }

  /// Pojedynczy element na liście wydatków (MODERN + FIX OVERFLOW)
  Widget _buildExpenseListItem(ExpenseHistoryItem item) {
    // Karta z półprzezroczystym tłem (szkło/bubble effect)
    final cardBackgroundColor = Colors.white.withOpacity(0.7);
    final currencyFormat =
        NumberFormat.currency(locale: 'pl_PL', symbol: 'PLN');

    Color amountColor = textColor;
    if (item.payerId == _currentUserId && item.participantsIds.length > 1) {
      amountColor = Colors.green[800]!;
    } else if (item.participantsIds.contains(_currentUserId) &&
        item.payerId != _currentUserId) {
      amountColor = Colors.red[800]!;
    }

    final displayAmount = currencyFormat.format(item.amount);
    final bool isMarkedAsPaid = _mockMarkedAsPaid.contains(item.id);
    final bool isConfirmed = _mockConfirmedReceived.contains(item.id);

    bool showActions = false;
    Widget? actionButton;

    // --- LOGIKA PRZYCISKÓW I STATUSÓW ---

    if (_selectedToggleIndex == 1) {
      // OWED
      showActions = true;
      if (isMarkedAsPaid) {
        actionButton = Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.hourglass_top_rounded,
                  size: 18, color: Colors.orange[800]),
              const SizedBox(width: 8),
              Text(
                "Waiting for confirmation",
                style: TextStyle(
                  color: Colors.orange[800],
                  fontWeight: FontWeight.bold,
                  fontFamily: appFontFamily,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        );
      } else {
        actionButton = ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          ),
          icon: const Icon(Icons.send_rounded, size: 18),
          label: const Text("Mark as Paid",
              style: TextStyle(
                  fontFamily: appFontFamily, fontWeight: FontWeight.bold)),
          onPressed: () {
            setState(() {
              _mockMarkedAsPaid.add(item.id);
            });
          },
        );
      }
    } else if (_selectedToggleIndex == 2) {
      // LENT
      showActions = true;
      if (isConfirmed) {
        actionButton = Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.check_circle_rounded, size: 18, color: Colors.green),
              SizedBox(width: 8),
              Text("Settled",
                  style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontFamily: appFontFamily)),
            ],
          ),
        );
      } else {
        actionButton = ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          ),
          icon: const Icon(Icons.thumb_up_alt_rounded, size: 18),
          label: const Text("Confirm Receipt",
              style: TextStyle(
                  fontFamily: appFontFamily, fontWeight: FontWeight.bold)),
          onPressed: () {
            setState(() {
              _mockConfirmedReceived.add(item.id);
            });
          },
        );
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardBackgroundColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: textColor.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // GÓRA KARTY
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // LEWA STRONA (Expanded naprawia overflow)
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CircleAvatar(
                      backgroundColor: primaryColor,
                      child: Icon(Icons.shopping_bag_outlined,
                          color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.description,
                            style: const TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.w900,
                              fontSize: 17,
                              fontFamily: appFontFamily,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getSubtext(item),
                            style: const TextStyle(
                              color: lightTextColor,
                              fontSize: 13,
                              fontFamily: appFontFamily,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // PRAWA STRONA
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    displayAmount,
                    style: TextStyle(
                      color: amountColor,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      fontFamily: appFontFamily,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('dd.MM.yyyy').format(item.date),
                    style: const TextStyle(
                        color: lightTextColor,
                        fontSize: 12,
                        fontFamily: appFontFamily),
                  ),
                ],
              ),
            ],
          ),

          // DÓŁ KARTY (Akcje)
          if (showActions) ...[
            const SizedBox(height: 16),
            Divider(color: lightTextColor.withOpacity(0.3), height: 1),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: actionButton ?? const SizedBox(),
            ),
          ],
        ],
      ),
    );
  }
}