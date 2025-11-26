import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../constants.dart'; // Importowanie Twoich stałych kolorów
import '../models/expense_history_item.dart'; // Import modelu danych
import '../services/firestore_service.dart';

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
  bool _hasGroupError = false;

  int _selectedToggleIndex = 0;
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  Map<String, String> _splitWith = {};

  List<Map<String, String>> _roomies = [];
  bool _isLoadingRoomies = true;

  final double _netBalance =
      50.00; // tymczasowe saldo dopóki nie ma logiki dzielenia rachunków
  bool _isNewExpenseFormVisible = false;

  // --- logika firestore ---
  // fetchowanie współlokatorów z Firestore, jeili użytkownik jest zalogowany
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

  // pobieranie nazwy mieszkania i współlokatorów z Firestore
  void _loadGroupData() async {
    try {
      // pobranie i weryfikacja groupId
      final groupId = await _firestoreService.getCurrentUserGroupId();

      // pobranie nazwy grupy
      final name = await _firestoreService.getGroupName(groupId);

      // pobranie współlokatorów
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
      // obsługa błędów
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

  // dodanie nowego wydatku
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

  // funkcja pomocnicza do wyliczenia "subtextu" na podstawie danych z firestore
  String _getSubtext(ExpenseHistoryItem item) {
    // znajdź imię płatnika
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
          // AppBar (taki sam jak na ekranie zadań)
          SliverAppBar(
            backgroundColor: backgroundColor,
            elevation: 0,
            floating: true,
            pinned: true,
            leading: IconButton(
              icon: const Icon(Icons.menu, color: textColor),
              onPressed: () {
                // TODO: Otwórz menu (Drawer)
              },
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
                  ),
                ),
                Text(
                  _groupName,
                  style: const TextStyle(
                    fontSize: 14,
                    color: lightTextColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            )),
            actions: [
              IconButton(
                icon:
                    const Icon(Icons.notifications_outlined, color: textColor),
                onPressed: () {
                  // TODO: Otwórz powiadomienia
                },
              ),
            ],
          ),

          // Reszta zawartości ekranu
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate(
                [
                  // Tytuł ekranu
                  const Center(
                    child: Text(
                      'Our expenses',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Karta "Your balance"
                  _buildBalanceCard(),
                  const SizedBox(height: 20),

                  // --- POPRAWKA 2: Animowane pojawianie się i znikanie formularza ---
                  // Formularz jest teraz owinięty w AnimatedSize i widoczny warunkowo.
                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: Container(
                      // Używamy `SizedBox` z `shrinkWrap`, aby animacja działała poprawnie
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
                  // --- Koniec POPRAWKI 2 ---

                  // Przełączniki "All" / "Owed" / "Lent"
                  _buildToggleButtons(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          // Lista wydatków (dynamicznie filtrowana)
          _buildExpensesList(),
        ],
      ),
    );
  }

  // --- WIDGETY POMOCNICZE ---

  /// Karta "Your balance"
  Widget _buildBalanceCard() {
    final cardBackgroundColor = accentColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: cardBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor, width: 2),
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
                    fontSize: 16),
              ),
              Text(
                '${_netBalance >= 0 ? '+' : ''}${_netBalance.toStringAsFixed(2)} PLN',
                style: TextStyle(
                  color: _netBalance >= 0 ? Colors.green[800] : Colors.red[800],
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          ElevatedButton(
            // --- POPRAWKA 3: Logika przełączania widoczności formularza ---
            onPressed: () {
              setState(() {
                _isNewExpenseFormVisible = !_isNewExpenseFormVisible;
              });
            },
            // Zmiana tekstu przycisku w zależności od stanu
            child: Text(_isNewExpenseFormVisible ? 'Cancel' : 'New expense'),
            // --- Koniec POPRAWKI 3 ---
          ),
        ],
      ),
    );
  }

  /// Formularz dodawania nowego wydatku
  Widget _buildNewExpenseForm() {
    final cardBackgroundColor = accentColor;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor, width: 2),
      ),
      child: Column(
        children: [
          // Pole "Description"
          TextField(
            controller: _descriptionController,
            decoration: _buildFormInputDecoration(hintText: 'Description'),
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 10),
          // Pole "Amount"
          TextField(
            controller: _amountController,
            decoration: _buildFormInputDecoration(hintText: 'Amount'),
            style: const TextStyle(color: Colors.white),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 10),

          // Lista współlokatorów (Checkbox)
          ..._roomies.map((user) {
            final userId = user['id']!;
            final userName = user['name']!;

            return CheckboxListTile(
              title: Text(userName, style: const TextStyle(color: textColor)),
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

          // Przycisk "SUBMIT"
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _addNewExpense,
              child: const Text('SUBMIT'),
            ),
          ),
        ],
      ),
    );
  }

  /// Pomocnicza funkcja do stylizacji pól formularza (Description, Amount)
  InputDecoration _buildFormInputDecoration({required String hintText}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: accentColor.withOpacity(0.8)),
      filled: true,
      fillColor: primaryColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: accentColor, width: 2.0),
      ),
    );
  }

  /// Przełączniki "All" / "Owed" / "Lent"
  Widget _buildToggleButtons() {
    return Row(
      children: [
        Expanded(
          child: _buildToggleButton(
            text: 'All',
            isSelected: _selectedToggleIndex == 0,
            onPressed: () => setState(() => _selectedToggleIndex = 0),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildToggleButton(
            text: 'Owed',
            isSelected: _selectedToggleIndex == 1,
            onPressed: () => setState(() => _selectedToggleIndex = 1),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildToggleButton(
            text: 'Lent',
            isSelected: _selectedToggleIndex == 2,
            onPressed: () => setState(() => _selectedToggleIndex = 2),
          ),
        ),
      ],
    );
  }

  /// Pomocniczy widget do budowania przycisków przełącznika
  Widget _buildToggleButton({
    required String text,
    required bool isSelected,
    required VoidCallback onPressed,
  }) {
    return isSelected
        ? ElevatedButton(
            onPressed: onPressed,
            child: Text(text),
          )
        : OutlinedButton(
            onPressed: onPressed,
            child: Text(text),
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

        // filtrowanie wydatków na podstawie wybranego przełącznika
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

  /// Pojedynczy element na liście wydatków
  Widget _buildExpenseListItem(ExpenseHistoryItem item) {
    final cardBackgroundColor = accentColor;
    final currencyFormat =
        NumberFormat.currency(locale: 'pl_PL', symbol: 'PLN');

    // Ustalanie koloru kwoty
    Color amountColor = textColor;
    if (item.payerId == _currentUserId && item.participantsIds.length > 1) {
      amountColor = Colors.green[800]!;
    } else if (item.participantsIds.contains(_currentUserId) &&
        item.payerId != _currentUserId) {
      amountColor = Colors.red[800]!;
    }

    // Ustalenie kwoty do wyświetlenia
    final displayAmount = currencyFormat.format(item.amount);

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cardBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor, width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Awatar, Tytuł i Podtekst
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: primaryColor,
                child: Icon(Icons.shopping_bag, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.description,
                    style: const TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    _getSubtext(item),
                    style: const TextStyle(color: lightTextColor, fontSize: 14),
                  ),
                ],
              ),
            ],
          ),
          // Kwota i Data
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                displayAmount,
                style: TextStyle(
                  color: amountColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              // formatowanie DateTime
              Text(
                item.date is DateTime
                    ? DateFormat('dd.MM.yyyy').format(item.date as DateTime)
                    : item.date.toString(),
                style: const TextStyle(color: lightTextColor, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
