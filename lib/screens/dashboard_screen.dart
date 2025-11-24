import 'package:flutter/material.dart';
import '../constants.dart';
import '../widgets/custom_text_field.dart';
import '../services/firestore_service.dart';
import 'home_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _groupIdController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();

  void _handleCreate() async {
    if (_nameController.text.isEmpty) {
      showSnackBarColor(
          context, 'Please enter the name of your place!', Colors.red);
      return;
    }

    final groupId =
        await _firestoreService.createNewGroup(_nameController.text);

    if (groupId != "") {
      showSnackBarColor(context, "Success", Colors.green);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomeScreen(
            roomName: _nameController.text.trim(),
          ),
        ),
      );
    } else {
      showSnackBarColor(context, "Cannot create a group", Colors.red);
    }
  }

  void _handleJoin() async {
    if (_groupIdController.text.isEmpty) {
      showSnackBarColor(context, 'Please enter an invite code!', Colors.red);
      return;
    }

    bool success =
        await _firestoreService.addUserToGroup(_groupIdController.text);

    if (success) {
      showSnackBarColor(context, "Success", Colors.green);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomeScreen(
            roomName: _groupIdController.text.trim(), // tymczasowo
          ),
        ),
      );
    } else {
      showSnackBarColor(context, "This group doesn't exist!", Colors.red);
    }
  }

  // zwolnienie kontrolerów
  @override
  void dispose() {
    _nameController.dispose();
    _groupIdController.dispose();
    super.dispose();
  }

  static void showSnackBarColor(
      BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar(
            backgroundColor: backgroundColor,
            elevation: 0,
            floating: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: textColor),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate(
              [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      // Logo i Tytuł
                      const Center(
                        child: Column(
                          children: [
                            Icon(Icons.house, size: 80.0, color: textColor),
                            SizedBox(height: 10),
                            Text('ROOMIES',
                                style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: textColor)),
                            SizedBox(height: 5),
                            Text('Hello! Let\'s get started',
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: textColor)),
                            SizedBox(height: 5),
                            Text('Manage your home in one place.',
                                style: TextStyle(
                                    fontSize: 14, color: lightTextColor)),
                            SizedBox(height: 40),
                          ],
                        ),
                      ),
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 450),
                          child: Container(
                            decoration: BoxDecoration(
                              color: accentColor,
                              //border: Border.all(color: accentColor, width: 2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 15, vertical: 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(Icons.house,
                                        size: 60, color: textColor),
                                    SizedBox(width: 15),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Create a new place',
                                            style: TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                                color: textColor),
                                          ),
                                          SizedBox(height: 5),
                                          Text(
                                            'You will be an admin and invite others.',
                                            style: TextStyle(
                                                fontSize: 14,
                                                color: lightTextColor),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                CustomTextField(
                                  controller: _nameController,
                                  label: '',
                                  hint: 'Enter the name of your place',
                                ),
                                const SizedBox(height: 10),
                                ElevatedButton(
                                  onPressed: () {
                                    _handleCreate();
                                    //przejście na główną
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryColor,
                                    minimumSize: const Size.fromHeight(50),
                                  ),
                                  child: const Text('Create'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 450),
                          child: Container(
                            decoration: BoxDecoration(
                              color: accentColor,
                              //border: Border.all(color: accentColor, width: 2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 15, vertical: 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment
                                  .start, //wyrównanie do lewej
                              children: [
                                const Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(Icons.house,
                                        size: 60, color: textColor),
                                    SizedBox(width: 15),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Join an existing place',
                                            style: TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                                color: textColor),
                                          ),
                                          SizedBox(height: 5),
                                          Text(
                                            'Use an invite code from the admin',
                                            style: TextStyle(
                                                fontSize: 14,
                                                color: lightTextColor),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                CustomTextField(
                                  controller: _groupIdController,
                                  label: '',
                                  hint: 'Enter an invite code',
                                ),
                                const SizedBox(height: 10),
                                ElevatedButton(
                                  onPressed: () {
                                    _handleJoin();
                                    //przejście na główną
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryColor,
                                    minimumSize: const Size.fromHeight(50),
                                  ),
                                  child: const Text('Join'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
