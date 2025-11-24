import 'package:flutter/material.dart';
import '../constants.dart';
import 'expenses_screen.dart';
import 'tasks_screen.dart';

class HomeScreen extends StatelessWidget {
  final String roomName;

  const HomeScreen({
    super.key,
    required this.roomName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: textColor),
        title: Text(
          roomName,
          style: const TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your place overview',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Switch between your expenses and shared tasks.',
              style: TextStyle(
                fontSize: 14,
                color: lightTextColor,
              ),
            ),
            const SizedBox(height: 30),

            // Dwa duże kafelki z przyciskami
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 450),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _HomeActionCard(
                        icon: Icons.attach_money,
                        title: 'Expenses',
                        subtitle: 'Track and split your home costs.',
                        buttonLabel: 'Go to expenses',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              //builder: (_) => const ExpensesScreen(),
                              builder: (_) =>
                                  const HomeScreen(roomName: 'My Place'),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      _HomeActionCard(
                        icon: Icons.check_circle_outline,
                        title: 'Tasks',
                        subtitle: 'Manage chores and to-dos together.',
                        buttonLabel: 'Go to tasks',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              //builder: (_) => const TasksScreen(),
                              builder: (_) =>
                                  const HomeScreen(roomName: 'My Place'),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String buttonLabel;
  final VoidCallback onPressed;

  const _HomeActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: accentColor,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 50, color: textColor),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 14,
                        color: lightTextColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                minimumSize: const Size.fromHeight(48),
              ),
              child: Text(buttonLabel),
            ),
          ),
        ],
      ),
    );
  }
}
