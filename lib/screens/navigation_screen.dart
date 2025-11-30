import 'package:flutter/material.dart';
import 'package:roomies/screens/home_screen.dart';
import 'tasks_screen.dart';
import 'expenses_screen.dart';
import '../constants.dart';

class NavigationMenuScreen extends StatelessWidget {
  final String groupId;
  final String roomName;
  const NavigationMenuScreen({super.key, required this.groupId, required String this.roomName});

  @override
  Widget build(BuildContext context) {

    return Scaffold(

        appBar: AppBar(
        toolbarHeight: 80,
        backgroundColor: backgroundColor,
        elevation: 0,
        leading:IconButton(
                icon: const Icon(Icons.menu, size: 30, color: textColor),
                onPressed: () => Navigator.pop(context),
              ),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                    builder: (context) => HomeScreen(roomName: roomName, groupId: groupId,)));
              },
                style: ElevatedButton.styleFrom(
                backgroundColor: backgroundColor,
                minimumSize: const Size.fromHeight(50),
                ),
                child:const Text(
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
            Text (
              roomName,
              style: const TextStyle(
                color: lightTextColor,
                fontFamily: appFontFamily,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, size: 30, color: textColor),
            onPressed: () {},
          ),
        ],
      ),
      
      backgroundColor: backgroundColor,
      body:Align(
        alignment: Alignment.topLeft,
        child: Container(
          width: MediaQuery.of(context).size.width,
          color: backgroundColor,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 60),
              Center(
                child: Text("Invite code: $groupId", style: const TextStyle(
                  color: lightTextColor,
                  fontFamily: appFontFamily,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),),
              ),
              const SizedBox(height: 20),
              InkWell(
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ExpensesScreen())),
                child: Column(
                  children: [ 
                    Divider(color: textColor, height: 1),
                    Container (width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                  margin: const EdgeInsets.only(bottom: 8),
                  color: backgroundColor,
                  child: const Text("Our expenses", 
              style: TextStyle(
                color: textColor,
                fontFamily: appFontFamily,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                fontSize: 22,
              )),),
              Divider(color: textColor, height: 1),]
                 
              ),
              ),
              InkWell(
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const TasksScreen())),
                child: Column(
                  children: [ 
                    Container (width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                  margin: const EdgeInsets.only(bottom: 8),
                  color: backgroundColor,
                  child: const Text("Tasks", 
              style: TextStyle(
                color: textColor,
                fontFamily: appFontFamily,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                fontSize: 22,
              )),),
              Divider(color: textColor, height: 1),]
                 
              ),
              ),
              InkWell(
                // onTap: () => Navigator.push(context,
                //     MaterialPageRoute(builder: (_) => const TasksScreen())), //TODO screen shopping list
                child: Column(
                  children: [ 
                    Container (width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                  margin: const EdgeInsets.only(bottom: 8),
                  color: backgroundColor,
                  child: const Text("Shopping list", 
              style: TextStyle(
                color: textColor,
                fontFamily: appFontFamily,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                fontSize: 22,
              )),),
              Divider(color: textColor, height: 1),]
                 
              ),
              ),
              InkWell(
                // onTap: () => Navigator.push(context,
                //     MaterialPageRoute(builder: (_) => const TasksScreen())), //TODO okienko z Members
                child: Column(
                  children: [ 
                    Container (width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                  margin: const EdgeInsets.only(bottom: 8),
                  color: backgroundColor,
                  child: const Text("See memebers", 
              style: TextStyle(
                color: textColor,
                fontFamily: appFontFamily,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                fontSize: 22,
              )),),
              Divider(color: textColor, height: 1),]
                 
              ),
              ),
                            InkWell(
                // onTap: () => Navigator.push(context,
                //     MaterialPageRoute(builder: (_) => const TasksScreen())), //TODO okienko czy na pewno chcesz sie wylogowac
                child: Column(
                  children: [ 
                    Container (width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                  margin: const EdgeInsets.only(bottom: 8),
                  color: backgroundColor,
                  child: const Text("Log out", 
              style: TextStyle(
                color: textColor,
                fontFamily: appFontFamily,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                fontSize: 22,
              )),),
              Divider(color: textColor, height: 1),]
                 
              ),
              ),
                            InkWell(
                // onTap: () => Navigator.push(context,
                //     MaterialPageRoute(builder: (_) => const TasksScreen())),  //TODO okienko czy na pewno chcesz wyjść
                child: Column(
                  children: [ 
                    Container (width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                  margin: const EdgeInsets.only(bottom: 8),
                  color: backgroundColor,
                  child: const Text("Exit current place", 
              style: TextStyle(
                color: textColor,
                fontFamily: appFontFamily,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                fontSize: 22,
              )),),
              Divider(color: textColor, height: 1),]
                 
              ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
