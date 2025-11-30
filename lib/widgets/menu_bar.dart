import 'package:flutter/material.dart';
import 'package:roomies/screens/home_screen.dart';
import '../screens/tasks_screen.dart';
import '../screens/expenses_screen.dart';
import '../constants.dart';

class MenuBar extends StatelessWidget {
  final String roomName;
  final String groupId;

  const MenuBar({
    super.key,
    required this.roomName,
    required this.groupId,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: backgroundColor,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
              color: backgroundColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => HomeScreen(roomName: roomName, groupId: groupId,),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: backgroundColor,
                      minimumSize: const Size.fromHeight(50),
                    ),
                    child: const Text(
                      'ROOMIEZ',
                      style: TextStyle(
                        color: textColor,
                        fontFamily: appFontFamily,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                        fontSize: 32,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    roomName,
                    style: const TextStyle(
                      color: lightTextColor,
                      fontFamily: appFontFamily,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Invite code: $groupId",
                    style: const TextStyle(
                      color: lightTextColor,
                      fontFamily: appFontFamily,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const Divider(color: textColor, height: 1),

            _drawerItem(context, title: "Our expenses", onTap: () {
              Navigator.pop(context);
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ExpensesScreen()));
            }),
            _drawerItem(context, title: "Tasks", onTap: () {
              Navigator.pop(context);
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const TasksScreen()));
            }),
            _drawerItem(context, title: "Shopping list", onTap: () {
              // TODO: implement shopping list screen
            }),
            _drawerItem(context, title: "See members", onTap: () {
              // TODO: implement members screen
            }),
            _drawerItem(context, title: "Log out", onTap: () {
              // TODO: implement logout
            }),
            _drawerItem(context, title: "Exit current place", onTap: () {
              // TODO: implement exit
            }),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(BuildContext context,
      {required String title, VoidCallback? onTap}) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            color: backgroundColor,
            child: Text(
              title,
              style: const TextStyle(
                color: textColor,
                fontFamily: appFontFamily,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                fontSize: 22,
              ),
            ),
          ),
        ),
        const Divider(color: textColor, height: 1),
      ],
    );
  }
}
