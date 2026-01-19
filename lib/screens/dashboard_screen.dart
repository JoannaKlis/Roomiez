import 'package:flutter/material.dart';
import '../constants.dart';
import '../services/firestore_service.dart';
import 'home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _groupIdController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();

  /// Sign out user and navigate to login
  void _signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    } catch (e) {
      debugPrint('Sign out error: $e');
    }
  }

  /// Handle group creation
  void _handleCreate() async {
    if (_nameController.text.trim().isEmpty) {
      showSnackBarColor(context, 'Please enter the name of your place!', Colors.red);
      return;
    }

    final groupId = await _firestoreService.createNewGroup(_nameController.text);

    if (groupId != "") {
      showSnackBarColor(context, "Success", Colors.green);
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (_) => false,
      );
    } else {
      showSnackBarColor(context, "Cannot create a group", Colors.red);
    }
  }

  /// Handle joining existing group
  void _handleJoin() async {
    final groupIdInput = _groupIdController.text.trim();

    if (groupIdInput.isEmpty) {
      showSnackBarColor(context, 'Please enter an invite code!', Colors.red);
      return;
    }

    bool success = await _firestoreService.addUserToGroup(groupIdInput);

    if (success) {
      String realGroupName = await _firestoreService.getGroupName(groupIdInput);

      if (mounted) {
        showSnackBarColor(context, "Success! Joined $realGroupName", Colors.green);
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (_) => false,
        );
      }
    } else {
      if (mounted) {
        showSnackBarColor(context, "This group doesn't exist!", Colors.red);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _groupIdController.dispose();
    super.dispose();
  }

  /// Show snackbar with custom color
  static void showSnackBarColor(BuildContext context, String message, Color color) {
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
      body: SafeArea(
        child: CustomScrollView(
          slivers: <Widget>[
            SliverAppBar(
              backgroundColor: backgroundColor,
              elevation: 0,
              floating: true,
              leading: IconButton(
                icon: const Icon(Icons.logout_rounded, color: textColor),
                onPressed: () async {
                  _signOut();
                },
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 10),
                  Center(
                    child: Column(
                      children: [
                        Image.asset(
                          'assets/images/logo_roomies.png',
                          width: 80,
                          height: 80,
                        ),
                        const Text(
                          'ROOMIES',
                          style: TextStyle(
                            fontFamily: 'StackSansNotch',
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: primaryColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 30),
                        const Text(
                          "Hello! Let's get started",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Manage your home in one place.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: lightTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: borderColor),
                      boxShadow: [
                        BoxShadow(
                          color: textColor.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.add_home_rounded,
                                  size: 32, color: primaryColor),
                            ),
                            const SizedBox(width: 15),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Create a new place',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'You will be an admin.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: lightTextColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            hintText: 'Enter the name of your place',
                            prefixIcon: Icon(Icons.home_outlined,
                                color: lightTextColor),
                          ),
                        ),
                        const SizedBox(height: 15),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _handleCreate,
                            child: const Text('Create'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: borderColor),
                      boxShadow: [
                        BoxShadow(
                          color: textColor.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.group_add_rounded,
                                  size: 32, color: primaryColor),
                            ),
                            const SizedBox(width: 15),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Join an existing place',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Use an invite code.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: lightTextColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: _groupIdController,
                          decoration: const InputDecoration(
                            hintText: 'Enter an invite code',
                            prefixIcon:
                                Icon(Icons.key_outlined, color: lightTextColor),
                          ),
                        ),
                        const SizedBox(height: 15),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: _handleJoin,
                            child: const Text('Join'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 50),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}