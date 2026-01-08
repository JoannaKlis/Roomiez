import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'dart:math';
import '../constants.dart';
import '../models/task_model.dart';
import '../services/firestore_service.dart';
import 'navigation_screen.dart';
import '../widgets/menu_bar.dart' as mb;
import 'announcements_screen.dart';
import 'home_screen.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  // --- ZARZĄDZANIE STANEM (Logika bez zmian) ---

  final FirestoreService _firestoreService = FirestoreService();
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
    super.dispose();
  }

  void _fetchRoomies(String groupId) async {
    if (groupId.isEmpty) return;

    final users = await _firestoreService.getCurrentApartmentUsers(groupId);
    if (mounted) {
      setState(() {
        _roomies = users;
        _isLoadingRoomies = false;

        final self = _roomies.firstWhere((u) => u['id'] == _currentUserId,
            orElse: () => {});
        if (self.isNotEmpty) {
          _selectedRoomieId = self['id'];
          _selectedRoomieName = self['name'];
        } else if (_roomies.isNotEmpty) {
          _selectedRoomieId = _roomies.first['id'];
          _selectedRoomieName = _roomies.first['name'];
        }
      });
    }
  }

  void _loadGroupData() async {
    try {
      final groupId = await _firestoreService.getCurrentUserGroupId();
      final name = await _firestoreService.getGroupName(groupId);

      if (mounted) {
        setState(() {
          _userGroupId = groupId;
          _groupName = name;
        });
        _fetchRoomies(groupId);
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

  void _selectDateTime() async {
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: primaryColor,
              onPrimary: Colors.white,
              surface: backgroundColor,
              onSurface: textColor,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: primaryColor),
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
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: primaryColor,
              onPrimary: Colors.white,
              surface: backgroundColor,
              onSurface: textColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (time == null) {
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
      id: '',
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

  void _toggleTaskStatus(String taskId, bool newStatus) {
    _firestoreService.updateTaskStatus(taskId, newStatus).catchError((e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error updating task: $e'),
            backgroundColor: Colors.red),
      );
    });
  }

  // --- BUDOWANIE INTERFEJSU (UI - Clean Style) ---
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
      body: CustomScrollView(
        slivers: [
          // AppBar
          SliverAppBar(
            backgroundColor: backgroundColor,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            floating: true,
            pinned: true,
            leading: Builder(
              builder: (context) => IconButton(
                icon:
                    const Icon(Icons.menu_rounded, size: 28, color: textColor),
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
                    fontFamily: 'StackSansNotch',
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

          // Reszta zawartości
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
            sliver: SliverList(
              delegate: SliverChildListDelegate(
                [
                  const Center(
                    child: Text(
                      'Tasks',
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

                  // Karta podsumowania (JASNA WERSJA)
                  _buildTaskSummaryCard(),
                  const SizedBox(height: 20),

                  // Formularz (Animowany)
                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    child: Container(
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

                  // Przełączniki
                  _buildToggleButtons(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // Lista zadań
          _buildTaskList(),

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
      drawer: mb.CustomDrawer(
        roomName: _groupName, // lub pobrana nazwa
        groupId: _userGroupId, // lub pobrane ID
        currentRoute: 'tasks', // <--- TO SPRAWIA ŻE ŚWIECI NA ZIELONO
      ),
    ));
  }

  // --- WIDGETY POMOCNICZE (Clean UI) ---

  /// Karta podsumowania - ZMIENIONA NA JASNĄ
  Widget _buildTaskSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: surfaceColor, // ZMIANA: Białe tło
        borderRadius: BorderRadius.circular(24),
        /*border: Border.all(color: borderColor), // ZMIANA: Delikatna ramka
        boxShadow: [
          BoxShadow(
            color: textColor.withOpacity(0.05), // Delikatny cień
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],*/
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your Tasks',
                style: TextStyle(
                  color: lightTextColor, // ZMIANA: Ciemny szary
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  fontFamily: appFontFamily,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Check updates',
                style: TextStyle(
                  color: textColor, // ZMIANA: Ciemny tekst
                  fontSize: 24,
                  fontWeight: FontWeight.w800, // Bardzo gruby
                  fontFamily: appFontFamily,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          Material(
            color: primaryColor, // Kolor przewodni
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: () {
                setState(() {
                  _isNewTaskFormVisible = !_isNewTaskFormVisible;
                  if (!_isNewTaskFormVisible) {
                    _descriptionController.clear();
                    _selectedDueDate =
                        DateTime.now().add(const Duration(days: 1));
                  }
                });
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Icon(
                      _isNewTaskFormVisible ? Icons.close : Icons.add,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isNewTaskFormVisible ? 'Close' : 'Add',
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

  /// Formularz dodawania nowego zadania
  Widget _buildNewTaskForm() {
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
          const Text("New Task",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                  fontFamily: appFontFamily)),
          const SizedBox(height: 16),

          TextField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              hintText: 'Task description',
              prefixIcon: Icon(Icons.edit_note, color: lightTextColor),
            ),
            style: const TextStyle(color: textColor, fontFamily: appFontFamily),
          ),
          const SizedBox(height: 12),

          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              hintText: 'Assigned to',
              prefixIcon: Icon(Icons.person_outline, color: lightTextColor),
            ),
            value: _selectedRoomieId,
            hint: _isLoadingRoomies
                ? const Text('Loading users...')
                : const Text('Select a roomie'),
            items: _roomies.map((user) {
              return DropdownMenuItem<String>(
                value: user['id'],
                child: Text(user['name']!,
                    style: const TextStyle(color: textColor)),
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
            icon: const Icon(Icons.arrow_drop_down_rounded, color: textColor),
            dropdownColor: Colors.white,
          ),
          const SizedBox(height: 12),

          // Wybór daty
          InkWell(
            onTap: _selectDateTime,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.transparent),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_rounded,
                      color: lightTextColor),
                  const SizedBox(width: 12),
                  Text(
                    DateFormat('dd.MM.yyyy HH:mm').format(_selectedDueDate),
                    style: const TextStyle(
                        color: textColor,
                        fontSize: 16,
                        fontFamily: appFontFamily),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _addNewTask,
              child: const Text('Create Task'),
            ),
          ),
        ],
      ),
    );
  }

  /// Przełączniki "All tasks" / "My tasks"
  Widget _buildToggleButtons() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(child: _buildToggleButton('All tasks', 0)),
          Expanded(child: _buildToggleButton('My tasks', 1)),
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

  /// Lista zadań (filtrowana)
  Widget _buildTaskList() {
    return StreamBuilder<List<Task>>(
      stream: _firestoreService.getTasks(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverToBoxAdapter(
            child: Center(
                child: Padding(
              padding: EdgeInsets.all(20.0),
              child: CircularProgressIndicator(color: primaryColor),
            )),
          );
        }
        if (snapshot.hasError) {
          return SliverToBoxAdapter(
            child: Center(
                child: Text('Error loading tasks',
                    style: const TextStyle(
                        color: Colors.red, fontFamily: appFontFamily))),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SliverToBoxAdapter(
              child: Center(
                  child: Padding(
            padding: EdgeInsets.only(top: 40.0),
            child: Text('No tasks found!',
                style: TextStyle(
                    color: lightTextColor, fontFamily: appFontFamily)),
          )));
        }

        final allTasks = snapshot.data!;
        
        // Filtrujemy zadania - chowamy zrobione starsze niż 1h
        final now = DateTime.now();
        final filteredTasks = allTasks.where((task) {
          // Jeśli zadanie jest zrobione
          if (task.isDone && task.completedAt != null) {
            // Sprawdzamy czy zostało oznaczone jako zrobione ponad 1h temu
            final timeSinceCompletion = now.difference(task.completedAt!);
            if (timeSinceCompletion.inHours >= 1) {
              return false; // Ukrywamy to zadanie
            }
          }
          
          // Filtrujemy po przypisaniu (jeśli wybrany "My tasks")
          if (_selectedToggleIndex == 1) {
            return task.assignedToId == _currentUserId;
          }
          return true;
        }).toList();

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final task = filteredTasks[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
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
    final bool isMyTask = task.assignedToId == _currentUserId;

    Widget leadingWidget;
    if (isMyTask) {
      leadingWidget = Transform.scale(
        scale: 1.2,
        child: Checkbox(
          value: task.isDone,
          onChanged: (bool? newValue) {
            if (newValue != null) {
              _toggleTaskStatus(task.id, newValue);
            }
          },
          activeColor: primaryColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          side: const BorderSide(color: lightTextColor, width: 1.5),
        ),
      );
    } else {
      leadingWidget = Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          task.assignedToName.isNotEmpty
              ? task.assignedToName[0].toUpperCase()
              : '?',
          style: const TextStyle(
              color: primaryColor, fontWeight: FontWeight.w900, fontSize: 16),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: task.isDone ? surfaceColor.withOpacity(0.5) : Colors.white,
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          leadingWidget,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: TextStyle(
                    color: task.isDone ? lightTextColor : textColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    fontFamily: appFontFamily,
                    decoration: task.isDone ? TextDecoration.lineThrough : null,
                    decorationColor: lightTextColor,
                  ),
                ),
                if (!isMyTask)
                  Text(
                    'Assigned to: ${task.assignedToName}',
                    style: const TextStyle(
                        color: lightTextColor,
                        fontSize: 12,
                        fontFamily: appFontFamily),
                  ),
                // Timer dla zrobionego zadania
                if (task.isDone && task.completedAt != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: _TaskCompletionTimer(completedAt: task.completedAt!),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: task.isDone ? Colors.green.withOpacity(0.1) : surfaceColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              DateFormat('dd MMM').format(task.dueDate),
              style: TextStyle(
                color: task.isDone ? Colors.green : lightTextColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                fontFamily: appFontFamily,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget stateful do pokazywania countdown'u dla zrobionego zadania
class _TaskCompletionTimer extends StatefulWidget {
  final DateTime completedAt;

  const _TaskCompletionTimer({required this.completedAt});

  @override
  State<_TaskCompletionTimer> createState() => _TaskCompletionTimerState();
}

class _TaskCompletionTimerState extends State<_TaskCompletionTimer> {
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
    final timeSinceCompletion = now.difference(widget.completedAt);
    final remainingSeconds = max(0, (60 * 60) - timeSinceCompletion.inSeconds); // 1h = 3600s
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
        fontSize: 11,
        fontStyle: FontStyle.italic,
        fontFamily: appFontFamily,
      ),
    );
  }
}
