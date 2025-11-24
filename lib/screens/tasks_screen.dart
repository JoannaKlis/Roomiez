/*import 'package:flutter/material.dart';
import '../constants.dart';
import '../models/task_model.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  // --- ZARZĄDZANIE STANEM (Logika) ---

  int _selectedToggleIndex = 0;
  String? _selectedRoomie;
  final List<String> _roomies = ['Jack', 'Ana', 'Martin'];
  final TextEditingController _descriptionController = TextEditingController();
  final String _currentUser = 'Jack';

  // --- POPRAWKA 1: Nowa zmienna stanu do zarządzania widocznością formularza ---
  bool _isNewTaskFormVisible = false;
  // --- Koniec POPRAWKI 1 ---

  // --- DANE TYMCZASOWE (Mock Data) ---
  final List<Task> _allTasks = [
    Task(
      id: '1',
      title: 'Kitchen cleaning',
      assignedTo: 'Jack',
      isDone: false,
      dueDate: 'Tomorrow',
    ),
    Task(
      id: '2',
      title: 'Go shopping',
      assignedTo: 'Martin',
      isDone: false,
      dueDate: 'Today',
    ),
    Task(
      id: '3',
      title: 'Bathroom cleaning',
      assignedTo: 'Ana',
      isDone: true,
      dueDate: '31.10.2025',
    ),
  ];

  List<Task> get _displayedTasks {
    if (_selectedToggleIndex == 1) { // "My tasks"
      return _allTasks.where((task) => task.assignedTo == _currentUser).toList();
    }
    return _allTasks; // "All tasks"
  }
  
  void _toggleTaskStatus(Task taskToUpdate, bool newStatus) {
    final taskIndex = _allTasks.indexWhere((t) => t.id == taskToUpdate.id);
    if (taskIndex != -1) {
      setState(() {
        _allTasks[taskIndex].isDone = newStatus;
      });
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  // --- BUDOWANIE INTERFEJSU (UI) ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // AppBar z obrazka
          SliverAppBar(
            backgroundColor: backgroundColor,
            elevation: 0,
            floating: true,
            pinned: true,
            centerTitle: true,
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
                      'Tasks',
                      style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Karta "Your task"
                  _buildTaskSummaryCard(),
                  const SizedBox(height: 20),

                  // --- POPRAWKA 2: Animowane pojawianie się i znikanie formularza ---
                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: Container(
                      height: _isNewTaskFormVisible ? null : 0,
                      child: _isNewTaskFormVisible
                          ? Column(
                              children: [
                                _buildNewTaskForm(),
                                const SizedBox(height: 20),
                              ],
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),
                  // --- Koniec POPRAWKI 2 ---

                  // Przełączniki "All tasks" / "My tasks"
                  _buildToggleButtons(),
                  const SizedBox(height: 20),

                  // Lista zadań (dynamicznie filtrowana)
                  _buildTaskList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGETY POMOCNICZE ---

  /// Karta podsumowania (Your task / No tasks for today)
  Widget _buildTaskSummaryCard() {
    final cardBackgroundColor = accentColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: cardBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor, width: 2), // Obramowanie
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your task',
                style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
              Text(
                'No tasks for today',
                style: TextStyle(color: lightTextColor, fontSize: 14),
              ),
            ],
          ),
          ElevatedButton(
            // --- POPRAWKA 3: Logika przełączania widoczności formularza ---
            onPressed: () {
              setState(() {
                _isNewTaskFormVisible = !_isNewTaskFormVisible;
              });
            },
            // Zmiana tekstu przycisku w zależności od stanu
            child: Text(_isNewTaskFormVisible ? 'Cancel' : 'New task'),
            // --- Koniec POPRAWKI 3 ---
          ),
        ],
      ),
    );
  }

  /// Formularz dodawania nowego zadania
  Widget _buildNewTaskForm() {
    final cardBackgroundColor = accentColor;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor, width: 2), // Obramowanie
      ),
      child: Column(
        children: [
          // Pole "Description"
          TextField(
            controller: _descriptionController,
            decoration: InputDecoration(
              hintText: 'Description',
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
            ),
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 10),

          // Lista współlokatorów (Radio buttons)
          Column(
            children: _roomies.map((name) {
              return RadioListTile<String>(
                title: Text(name, style: const TextStyle(color: textColor)),
                value: name,
                groupValue: _selectedRoomie,
                onChanged: (String? value) {
                  setState(() {
                    _selectedRoomie = value;
                  });
                },
                activeColor: textColor,
                contentPadding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              );
            }).toList(),
          ),
          const SizedBox(height: 10),

          // Przycisk "SUBMIT"
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // --- LOGIKA SUBMIT ---
                print('New Task Submitted:');
                print('Description: ${_descriptionController.text}');
                print('Assigned To: $_selectedRoomie');

                // --- POPRAWKA 4: Ukryj formularz i wyczyść pola po wysłaniu ---
                setState(() {
                  _isNewTaskFormVisible = false;
                  _descriptionController.clear();
                  _selectedRoomie = null; // Resetowanie wyboru
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

  /// Przełączniki "All tasks" / "My tasks"
  Widget _buildToggleButtons() {
    return Row(
      children: [
        Expanded(
          child: _buildToggleButton(
            text: 'All tasks',
            isSelected: _selectedToggleIndex == 0,
            onPressed: () {
              setState(() {
                _selectedToggleIndex = 0;
              });
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildToggleButton(
            text: 'My tasks',
            isSelected: _selectedToggleIndex == 1,
            onPressed: () {
              setState(() {
                _selectedToggleIndex = 1;
              });
            },
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

  /// Lista zadań (filtrowana)
  Widget _buildTaskList() {
    return Column(
      children: _displayedTasks.map((task) {
        return _buildTaskListItem(task);
      }).toList(),
    );
  }

  /// Pojedynczy element na liście zadań
  Widget _buildTaskListItem(Task task) {
    final cardBackgroundColor = accentColor;
    final bool isMyTask = task.assignedTo == _currentUser;
    
    Widget leadingWidget;
    if (isMyTask) {
      leadingWidget = SizedBox(
        width: 40.0,
        height: 40.0,
        child: Checkbox(
          value: task.isDone,
          onChanged: (bool? newValue) {
            if (newValue != null) {
              _toggleTaskStatus(task, newValue);
            }
          },
          activeColor: primaryColor,
        ),
      );
    } else {
      leadingWidget = CircleAvatar(
        backgroundColor: primaryColor,
        child: Text(
          task.assignedTo[0], // Pierwsza litera imienia
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cardBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor, width: 2), // Obramowanie
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Awatar (lub Checkbox), Tytuł i Przypisany
          Row(
            children: [
              leadingWidget,
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: const TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    task.assignedTo,
                    style: const TextStyle(color: lightTextColor, fontSize: 14),
                  ),
                ],
              ),
            ],
          ),
          // Status i Data
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                task.isDone ? 'Done' : 'To do',
                style: TextStyle(
                  color: task.isDone ? lightTextColor : textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                task.dueDate,
                style: const TextStyle(color: lightTextColor, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}*/
