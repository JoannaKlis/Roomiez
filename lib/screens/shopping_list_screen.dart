import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'dart:math';
import '../services/firestore_service.dart';
import '../constants.dart';
import '../widgets/menu_bar.dart';
import 'announcements_screen.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Potrzebne do ID usera
import '../models/expense_history_item.dart'; // Potrzebne do stworzenia wydatku
import 'home_screen.dart';

class ShoppingScreen extends StatefulWidget {
  const ShoppingScreen({super.key});

  @override
  State<ShoppingScreen> createState() => _ShoppingScreenState();
}

class _ShoppingScreenState extends State<ShoppingScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _itemController = TextEditingController();

  // Dane nagłówka
  String _groupId = '';
  String _groupName = '';
  bool _isLoadingHeader = true;
  bool _isPriority = false; // Stan checkboxa przy dodawaniu

  @override
  void initState() {
    super.initState();
    _loadHeaderData();
  }

  @override
  void dispose() {
    _itemController.dispose();
    super.dispose();
  }

  // Pobranie danych o grupie (dla nagłówka i ID do zapytań)
  Future<void> _loadHeaderData() async {
    try {
      final groupId = await _firestoreService.getCurrentUserGroupId();
      final groupName = await _firestoreService.getGroupName(groupId);
      if (mounted) {
        setState(() {
          _groupId = groupId;
          _groupName = groupName;
          _isLoadingHeader = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading group info: $e");
    }
  }

  // --- LOGIKA FIRESTORE (Lokalna dla tego ekranu) ---

  // 1. Dodawanie produktu
  Future<void> _addItem() async {
    final text = _itemController.text.trim();
    if (text.isEmpty) return;

    await _firestoreService.addShoppingItem(text, _isPriority);

    _itemController.clear();
    setState(() {
      _isPriority = false; // Reset priorytetu po dodaniu
    });
  }

  // --- ZMODYFIKOWANA METODA TOGGLE ---
  Future<void> _toggleBought(
      String docId, bool currentStatus, String itemName) async {
    // Jeśli przedmiot jest właśnie kupowany (zmieniamy z false na true)
    if (!currentStatus) {
      await _showAddToExpensesDialog(itemName);
    }
    // Wykonaj standardową zmianę statusu w bazie
    await _firestoreService.toggleShoppingItemStatus(docId, currentStatus);
  }

  // --- NOWY DIALOG "DODAJ DO WYDATKÓW" ---
  Future<void> _showAddToExpensesDialog(String itemName) async {
    final TextEditingController _priceController = TextEditingController();

    // Pytamy użytkownika
    bool? shouldAdd = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Bought '$itemName'?"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Do you want to add this cost to group expenses?"),
            const SizedBox(height: 16),
            TextField(
              controller: _priceController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              decoration: const InputDecoration(
                labelText: "Price",
                suffixText: "PLN",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false), // Nie dodawaj
            child: const Text("No, just mark check"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true), // Dodaj
            child: const Text("Add Expense"),
          ),
        ],
      ),
    );

    // Logika dodawania
    if (shouldAdd == true && _priceController.text.isNotEmpty) {
      final valStr =
          _priceController.text.replaceAll(',', '.'); // Fix dla przecinków
      final double? amount = double.tryParse(valStr);

      if (amount != null && amount > 0) {
        try {
          final currentUser = FirebaseAuth.instance.currentUser;
          if (currentUser == null) return;

          // Pobieramy członków grupy, żeby podzielić rachunek na wszystkich
          final users =
              await _firestoreService.getCurrentApartmentUsers(_groupId);
          var participantIds = users.map((u) => u['id']!).toList();

          // Fallback: jak lista pusta, dodaj chociaż siebie
          if (participantIds.isEmpty) participantIds.add(currentUser.uid);

          final newExpense = ExpenseHistoryItem(
            id: '',
            description: 'Shopping: $itemName',
            payerId: currentUser.uid,
            amount: amount,
            date: DateTime.now(),
            participantsIds: participantIds,
            groupId: _groupId,
          );

          await _firestoreService.addExpense(newExpense);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Expense added automatically!'),
                  backgroundColor: Colors.green),
            );
          }
        } catch (e) {
          debugPrint("Error adding expense from shopping list: $e");
        }
      }
    }
  }

  // 3. Usuwanie produktu
  Future<void> _deleteItem(String docId) async {
    await _firestoreService.deleteShoppingItem(docId);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
        canPop: false, // BLOKUJEMY normalne cofanie
        onPopInvoked: (didPop) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
            (route) => false, // USUWA CAŁY STACK
          );
        },
        child: Scaffold(
          backgroundColor: backgroundColor,

          // --- APP BAR ---
          appBar: AppBar(
            backgroundColor: backgroundColor,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            leading: Builder(
              builder: (context) => IconButton(
                icon:
                    const Icon(Icons.menu_rounded, size: 28, color: textColor),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
            title: Column(
              children: [
                const Text(
                  'ROOMIES',
                  style: TextStyle(
                    color: primaryColor,
                    fontFamily: 'StackSansNotch',
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                    fontSize: 20,
                  ),
                ),
                Text(
                  _groupName.isNotEmpty ? _groupName.toUpperCase() : 'SHOPPING',
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
                icon: const Icon(
                  Icons.notifications_none_rounded,
                  size: 28,
                  color: textColor,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AnnouncementsScreen(),
                    ),
                  );
                },
              ),
            ],
          ),

          drawer: CustomDrawer(
            groupId: _groupId,
            roomName: _groupName,
            currentRoute: 'shopping',
          ),

          body: Column(
            children: [
              // --- POLE DODAWANIA ---
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      const BorderRadius.vertical(bottom: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                      color: textColor.withOpacity(0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _itemController,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: InputDecoration(
                              hintText: 'Add new item...',
                              hintStyle: const TextStyle(color: lightTextColor),
                              fillColor: surfaceColor,
                              filled: true,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            onSubmitted: (_) => _addItem(), // Enter dodaje
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Przycisk Priorytetu (Gwiazdka/Wykrzyknik)
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _isPriority = !_isPriority;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _isPriority
                                  ? Colors.redAccent.withOpacity(0.1)
                                  : surfaceColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _isPriority
                                    ? Colors.redAccent
                                    : Colors.transparent,
                              ),
                            ),
                            child: Icon(
                              Icons.priority_high_rounded,
                              color: _isPriority
                                  ? Colors.redAccent
                                  : lightTextColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _addItem,
                        child: const Text('Add to list'),
                      ),
                    ),
                  ],
                ),
              ),

              // --- LISTA PRODUKTÓW ---
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _firestoreService.getShoppingList(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                          child:
                              CircularProgressIndicator(color: primaryColor));
                    }

                    if (snapshot.hasError) {
                      debugPrint(
                          'shopping_list_stream error: ${snapshot.error}');
                      return Center(
                        child: Text(
                            'Error loading shopping list: ${snapshot.error}'),
                      );
                    }

                    final allDocs = snapshot.data ?? [];

                    if (allDocs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.shopping_basket_outlined,
                                size: 64,
                                color: lightTextColor.withOpacity(0.3)),
                            const SizedBox(height: 16),
                            const Text(
                              'Your shopping list is empty.\nAdd items above!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: lightTextColor,
                                fontFamily: appFontFamily,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    // Filtrujemy items - pokazujemy tylko niekupione lub kupione w ostatniej godzinie
                    final now = DateTime.now();
                    final filteredItems = allDocs.where((item) {
                      final isBought = item['isBought'] ?? false;

                      // Jeśli nie kupione, pokazujemy
                      if (!isBought) return true;

                      // Jeśli kupione, sprawdzamy czy w ostatniej godzinie
                      if (isBought) {
                        final boughtAtRaw = item['boughtAt'];
                        if (boughtAtRaw is Timestamp) {
                          final boughtAt = boughtAtRaw.toDate();
                          final timeSinceBought = now.difference(boughtAt);
                          return timeSinceBought.inHours < 1;
                        }
                      }
                      return false;
                    }).toList();

                    if (filteredItems.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.shopping_basket_outlined,
                                size: 64,
                                color: lightTextColor.withOpacity(0.3)),
                            const SizedBox(height: 16),
                            const Text(
                              'Your shopping list is empty.\nAdd items above!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: lightTextColor,
                                fontFamily: appFontFamily,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.all(20),
                      itemCount: filteredItems.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final item = filteredItems[index];
                        final itemId = item['id'] as String;
                        final isBought = item['isBought'] ?? false;
                        final isPriority = item['isPriority'] ?? false;
                        final name = item['name'] ?? 'Unknown item';

                        return Dismissible(
                          key: Key(itemId),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            decoration: BoxDecoration(
                              color: Colors.redAccent,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(Icons.delete_outline,
                                color: Colors.white),
                          ),
                          onDismissed: (direction) {
                            _deleteItem(itemId);
                          },
                          child: GestureDetector(
                            onTap: () => _toggleBought(itemId, isBought, name),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 16),
                              decoration: BoxDecoration(
                                color: isBought
                                    ? surfaceColor.withOpacity(
                                        0.6) // Przygaszone tło dla kupionych
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isPriority && !isBought
                                      ? Colors.redAccent.withOpacity(0.3)
                                      : borderColor,
                                ),
                                boxShadow: isBought
                                    ? []
                                    : [
                                        BoxShadow(
                                          color: textColor.withOpacity(0.02),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                              ),
                              child: Row(
                                children: [
                                  // Checkbox customowy
                                  Icon(
                                    isBought
                                        ? Icons.check_circle_rounded
                                        : Icons.radio_button_unchecked_rounded,
                                    color: isBought
                                        ? primaryColor
                                        : (isPriority
                                            ? Colors.redAccent
                                            : lightTextColor),
                                    size: 24,
                                  ),
                                  const SizedBox(width: 16),

                                  // Nazwa i timer
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            fontFamily: appFontFamily,
                                            color: isBought
                                                ? lightTextColor
                                                : textColor,
                                            decoration: isBought
                                                ? TextDecoration.lineThrough
                                                : null,
                                            decorationColor: lightTextColor,
                                          ),
                                        ),
                                        // Timer dla kupionego itemu
                                        if (isBought &&
                                            item['boughtAt'] != null)
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(top: 4),
                                            child: _ShoppingItemTimer(
                                              boughtAt:
                                                  (item['boughtAt'] as Timestamp)
                                                      .toDate(),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),

                                  // Badge Priorytetu
                                  if (isPriority && !isBought)
                                    Container(
                                      margin: const EdgeInsets.only(right: 8),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color:
                                            Colors.redAccent.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        'PRIORITY',
                                        style: TextStyle(
                                          color: Colors.redAccent,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),

                                  // DODANO: Ikona kosza (Explicit delete button)
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline,
                                        color: lightTextColor, size: 20),
                                    onPressed: () => _deleteItem(itemId),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ));
  }
}

/// Widget stateful do pokazywania countdown'u dla kupionego przedmiotu
class _ShoppingItemTimer extends StatefulWidget {
  final DateTime boughtAt;

  const _ShoppingItemTimer({required this.boughtAt});

  @override
  State<_ShoppingItemTimer> createState() => _ShoppingItemTimerState();
}

class _ShoppingItemTimerState extends State<_ShoppingItemTimer> {
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final timeSinceBought = now.difference(widget.boughtAt);
    final remainingSeconds =
        max(0, (60 * 60) - timeSinceBought.inSeconds); // 1h = 3600s
    final minutesRemaining = remainingSeconds ~/ 60;
    final secondsRemaining = remainingSeconds % 60;

    // Renderujemy jako zniknie za X minut Y sekund
    final timeText = minutesRemaining > 0
        ? '$minutesRemaining min ${secondsRemaining}s'
        : '${secondsRemaining}s';

    // Zmiana koloru w zależności od czasu
    Color textColor = Colors.green;
    if (remainingSeconds < 300) {
      // Ostatnie 5 minut - czerwone
      textColor = Colors.red;
    } else if (remainingSeconds < 600) {
      // Ostatnie 10 minut - pomarańczowe
      textColor = Colors.orange;
    }

    return Text(
      'Disappears in: $timeText',
      style: TextStyle(
        color: textColor,
        fontSize: 10,
        fontStyle: FontStyle.italic,
        fontFamily: appFontFamily,
      ),
    );
  }
}