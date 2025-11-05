import 'package:flutter/material.dart';
import '../constants.dart';
import '../widgets/custom_button.dart';
import 'login_screen.dart';
import 'registration_screen.dart';

// ekran główny aplikacji
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor, // tło ekranu
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            // Logo i Nazwa Aplikacji
            const Column(
              children: [
                Icon(
                  Icons.house,
                  size: 80.0,
                  color: textColor,
                ),
                SizedBox(height: 10),
                Text(
                  'ROOMIES',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ],
            ),
            // Tytuł i Opis
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40.0),
              child: Column(
                children: [
                  Text(
                    'Manage your place together',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Split bills, manage duties and groceries all in one place.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: lightTextColor,
                    ),
                  ),
                ],
              ),
            ),
            // Przycisk logowania i rejestracji
            Padding(
              padding: const EdgeInsets.only(bottom: 40.0, left: 20, right: 20),
              child: Column(
                children: <Widget>[
                  // Przycisk Rejestracji
                  CustomButton(
                    text: 'Register',
                    isPrimary: true,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const RegistrationScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 15),
                  // Przycisk Logowania
                  CustomButton(
                    text: 'Log In',
                    isPrimary: false,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const LoginScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
