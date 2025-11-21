import 'package:flutter/material.dart';
import '../constants.dart'; // Importowanie Twoich stałych kolorów
import '../models/expense_history_item.dart'; // Import modelu danych

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  // --- ZARZĄDZANIE STANEM (Logika) ---

  int _selectedToggleIndex = 0;
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  final Map<String, bool> _splitWith = {
    'Ana': false,
    'Martin': false,
  };
  
  // --- POPRAWKA 1: Nowa zmienna stanu do zarządzania widocznością formularza ---
  bool _isNewExpenseFormVisible = false;
  // --- Koniec POPRAWKI 1 ---

  final String _currentUser = 'Jack';
  final double _netBalance = 50.00;

  // --- DANE TYMCZASOWE (Mock Data) ---
  final List<ExpenseHistoryItem> _allTransactions = [
    ExpenseHistoryItem(
      id: '1',
      description: 'Pizza',
      subtext: 'Ana and Martin owe you',
      amount: 40.00,
      date: 'Today',
      type: 'lent',
    ),
    ExpenseHistoryItem(
      id: '2',
      description: 'Bread',
      subtext: 'You owe Martin',
      amount: -2.25,
      date: 'Yesterday',
      type: 'owed',
    ),
    ExpenseHistoryItem(
      id: '3',
      description: 'Rent',
      subtext: 'Settled',
      amount: -200.00,
      date: '31.10.2025',
      type: 'settled',
    ),
  ];

  // --- LOGIKA FILTROWANIA ---
  List<ExpenseHistoryItem> get _filteredTransactions {
    switch (_selectedToggleIndex) {
      case 1: // Owed
        return _allTransactions.where((t) => t.type == 'owed').toList();
      case 2: // Lent
        return _allTransactions.where((t) => t.type == 'lent').toList();
      case 0: // All
      default:
        return _allTransactions;
    }
  }
  
  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
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
            title: const Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'ROOMIES',
                    style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    ),
                  ),
                  Text(
                    'Sunset Valley 8',
                    style: TextStyle(
                    fontSize: 14,
                    color: lightTextColor,
                    fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              )
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: textColor),
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

                  // Lista wydatków (dynamicznie filtrowana)
                  _buildExpensesList(),
                ],
              ),
            ),
          ),
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
          ..._splitWith.keys.map((name) {
            return CheckboxListTile(
              title: Text(name, style: const TextStyle(color: textColor)),
              value: _splitWith[name],
              onChanged: (bool? value) {
                setState(() {
                  _splitWith[name] = value ?? false;
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
              onPressed: () {
                // --- LOGIKA SUBMIT ---
                print('New Expense Submitted:');
                print('Description: ${_descriptionController.text}');
                print('Amount: ${_amountController.text}');
                print('Split with: $_splitWith');
                
                // --- POPRAWKA 4: Ukryj formularz i wyczyść pola po wysłaniu ---
                setState(() {
                  _isNewExpenseFormVisible = false;
                  _descriptionController.clear();
                  _amountController.clear();
                  // Resetowanie wszystkich checkboxów
                  _splitWith.updateAll((key, value) => false);
                });
                // --- Koniec POPRAWKI 4 ---
              },
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
    // Używamy `Column` zamiast `ListView`, aby uniknąć błędów zagnieżdżenia w `SliverList`
    return Column(
      children: _filteredTransactions.map((item) {
        return _buildExpenseListItem(item);
      }).toList(),
    );
  }

  /// Pojedynczy element na liście wydatków
  Widget _buildExpenseListItem(ExpenseHistoryItem item) {
    final cardBackgroundColor = accentColor;
    
    // Ustalanie koloru kwoty
    Color amountColor;
    if (item.type == 'lent') {
      amountColor = Colors.green[800]!; // Pożyczyłeś (na plus)
    } else if (item.type == 'owed') {
      amountColor = Colors.red[800]!; // Wisisz (na minus)
    } else {
      amountColor = textColor; // Rozliczone (neutralne)
    }

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
              CircleAvatar(
                backgroundColor: primaryColor,
                child: Text(
                  item.description[0],
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
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
                    item.subtext,
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
                '${item.amount >= 0 ? '+' : ''}${item.amount.toStringAsFixed(2)} PLN',
                style: TextStyle(
                  color: amountColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                item.date,
                style: const TextStyle(color: lightTextColor, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}