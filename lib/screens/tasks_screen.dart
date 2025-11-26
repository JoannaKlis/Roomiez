import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../constants.dart';
import '../models/task_model.dart';
import '../services/firestore_service.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  // --- ZARZĄDZANIE STANEM (Logika) ---

  final FirestoreService _firestoreService = FirestoreService();

  // pobieranie UID z zalogowanego użytkownika
  // jeśli null, będzie pusty string
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  String _groupName = 'Loading...';
  String _userGroupId = '';
  bool _hasGroupError = false;

  int _selectedToggleIndex = 0;
  String? _selectedRoomieId;
  String? _selectedRoomieName;
  final TextEditingController _descriptionController = TextEditingController();
  bool _isNewTaskFormVisible = false;
  DateTime _selectedDueDate =
      DateTime.now().add(const Duration(days: 1)); // domyślnie jutro

  List<Map<String, String>> _roomies = [];
  bool _isLoadingRoomies = true;

  // --- logika firestore ---
  // fetchowanie współlokatorów z Firestore, jeili użytkownik jest zalogowany
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
    super.dispose();
  }

  // pobieranie współlokatorów z Firestore
  void _fetchRoomies(String groupId) async {
    // jeśli nie ma grupy, nie pobieraj
    if (groupId.isEmpty) return;

    final users = await _firestoreService.getCurrentApartmentUsers(groupId);
    setState(() {
      _roomies = users;
      _isLoadingRoomies = false;

      // wybór bieżącego użytkownika (jeśli jest na liście)
      final self = _roomies.firstWhere((u) => u['id'] == _currentUserId,
          orElse: () => {});
      if (self.isNotEmpty) {
        _selectedRoomieId = self['id'];
        _selectedRoomieName = self['name'];
      } else if (_roomies.isNotEmpty) {
        // jeśli nie jesteśmy w domyślnej grupie, wybieramy pierwszego
        _selectedRoomieId = _roomies.first['id'];
        _selectedRoomieName = _roomies.first['name'];
      }
    });
  }

  // pobieranie nazwy grupy i ID użytkownika
  void _loadGroupData() async {
    try {
      // pobranie groupId
      final groupId = await _firestoreService.getCurrentUserGroupId();
      // pobranie nazwy grupy
      final name = await _firestoreService.getGroupName(groupId);

      if (mounted) {
        setState(() {
          _userGroupId = groupId;
          _groupName = name;
        });
        // pobranie współlokatorów
        _fetchRoomies(groupId);
      }
    } catch (e) {
      // obsługa błędów rzuconych przez getCurrentUserGroupId
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

  // wybór daty i godziny dueDate
  void _selectDateTime() async {
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),

      // własny motyw
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            textTheme:
                Theme.of(context).textTheme.apply(fontFamily: 'Baloo Bhai'),

            colorScheme: ColorScheme.light(
              primary:
                  primaryColor, // kolor nagłówka, aktywnych dni, przycisków
              onPrimary: backgroundColor, // kolor tekstu na tle primary
              surface: backgroundColor, // kolor tła kalendarza
              onSurface: textColor, // kolor tekstu (dni)
            ),
            // styl przycisków akcji (OK/CANCEL)
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: primaryColor, // solor tekstu przycisków akcji
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (date == null) return;

    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDueDate),

      // nałożenie motywu
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            textTheme:
                Theme.of(context).textTheme.apply(fontFamily: 'Baloo Bhai'),
            colorScheme: ColorScheme.light(
              primary:
                  primaryColor, // kolor akcentu (wskazówka zegara, tło wybranego numeru)
              onPrimary: backgroundColor, // kolor tekstu na tle primary
              surface: backgroundColor, // tło całego zegara
              onSurface: textColor, // kolor cyfr
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: primaryColor,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (time == null) {
      // jeśli anulowano wybór czasu, używamy daty z domyślnym czasem
      setState(() {
        _selectedDueDate = date;
      });
      return;
    }

    setState(() {
      _selectedDueDate = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  // dodawanie nowego zadania
  void _addNewTask() {
    if (_descriptionController.text.isEmpty ||
        _selectedRoomieId == null ||
        _userGroupId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(_userGroupId.isEmpty
                ? 'Error: You must belong to a group to add tasks.'
                : 'Please fill all fields.'),
            backgroundColor: Colors.red),
      );
      return;
    }

    final newTask = Task(
      id: '', // firestore wygeneruje ID
      title: _descriptionController.text.trim(),
      assignedToId: _selectedRoomieId!,
      assignedToName: _selectedRoomieName!,
      groupId: _userGroupId,
      isDone: false,
      dueDate: _selectedDueDate,
    );

    _firestoreService.addTask(newTask).then((_) {
      setState(() {
        _isNewTaskFormVisible = false;
        _descriptionController.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Task added successfully!'),
            backgroundColor: Colors.green),
      );
    }).catchError((e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error adding task: $e'),
            backgroundColor: Colors.red),
      );
    });
  }

  // aktualizacja statusu zadania
  void _toggleTaskStatus(String taskId, bool newStatus) {
    _firestoreService.updateTaskStatus(taskId, newStatus).catchError((e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error updating task: $e'),
            backgroundColor: Colors.red),
      );
    });
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
                ],
              ),
            ),
          ),
          // Lista zadań (dynamicznie filtrowana)
          _buildTaskList(),
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
            onPressed: () {
              setState(() {
                _isNewTaskFormVisible = !_isNewTaskFormVisible;
                // zresetuj pole opisu jeśli anulowano
                if (!_isNewTaskFormVisible) {
                  _descriptionController.clear();
                  _selectedDueDate =
                      DateTime.now().add(const Duration(days: 1)); // reset daty
                }
              });
            },
            // Zmiana tekstu przycisku w zależności od stanu
            child: Text(_isNewTaskFormVisible ? 'Cancel' : 'New task'),
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

          // Lista współlokatorów
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: 'Assigned to',
              labelStyle: const TextStyle(color: textColor),
              filled: true,
              fillColor: primaryColor.withAlpha(38),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: const BorderSide(color: primaryColor, width: 2.0),
              ),
            ),
            value: _selectedRoomieId,
            hint: _isLoadingRoomies
                ? const Text('Loading users...')
                : const Text('Select a roomie'),
            items: _roomies.map((user) {
              return DropdownMenuItem<String>(
                value: user['id'],
                child: Text(user['name']!),
              );
            }).toList(),
            onChanged: _isLoadingRoomies
                ? null
                : (String? newValue) {
                    setState(() {
                      _selectedRoomieId = newValue;
                      _selectedRoomieName = _roomies
                          .firstWhere((user) => user['id'] == newValue)['name'];
                    });
                  },
          ),
          const SizedBox(height: 10),

          // wybór daty i godziny
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _selectDateTime,
                  icon: const Icon(Icons.calendar_today),
                  label: Text(
                    'Due: ${DateFormat('dd.MM.yyyy HH:mm').format(_selectedDueDate)}',
                    textAlign: TextAlign.left,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Przycisk "SUBMIT"
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _addNewTask,
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
    return StreamBuilder<List<Task>>(
      stream: _firestoreService.getTasks(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // zwracamy SliverToBoxAdapter dla RenderBoxa (ładowanie)
          return const SliverToBoxAdapter(
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return SliverToBoxAdapter(
            child: Center(
                child: Text('Error loading tasks: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red))),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SliverToBoxAdapter(
              child: Center(
                  child: Text('No tasks found!',
                      style: TextStyle(color: textColor))));
        }

        final allTasks = snapshot.data!;
        final filteredTasks = allTasks.where((task) {
          if (_selectedToggleIndex == 1) {
            // My tasks
            return task.assignedToId == _currentUserId;
          }
          return true; // All tasks
        }).toList();

        // zwracamy SliverList
        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final task = filteredTasks[index];
              return Padding(
                // dodajemy Padding do elementu listy, aby uzyskać marginesy boczne
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: _buildTaskListItem(task),
              );
            },
            childCount: filteredTasks.length,
          ),
        );
      },
    );
  }

  // Pojedynczy element na liście zadań
  Widget _buildTaskListItem(Task task) {
    final cardBackgroundColor = accentColor;
    final bool isMyTask = task.assignedToId == _currentUserId;

    Widget leadingWidget;
    if (isMyTask) {
      leadingWidget = SizedBox(
        width: 40.0,
        height: 40.0,
        child: Checkbox(
          value: task.isDone,
          onChanged: (bool? newValue) {
            if (newValue != null) {
              _toggleTaskStatus(task.id, newValue);
            }
          },
          activeColor: primaryColor,
        ),
      );
    } else {
      leadingWidget = CircleAvatar(
        backgroundColor: primaryColor,
        child: Text(
          task.assignedToName[0], // Pierwsza litera imienia
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
                    task.assignedToName,
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
                task.dueDate is DateTime
                    ? DateFormat('dd.MM.yyyy').format(task.dueDate as DateTime)
                    : task.dueDate.toString(),
                style: const TextStyle(color: lightTextColor, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
