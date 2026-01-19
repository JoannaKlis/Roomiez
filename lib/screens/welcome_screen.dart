import 'package:flutter/material.dart';
import '../constants.dart';
import 'login_screen.dart';
import 'registration_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight, // Wymuś minimalną wysokość ekranu
                ),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        const Spacer(flex: 2), 
                        
                        // --- SEKCJA LOGO ---
                        Image.asset(
                          'assets/images/logo_roomies.png', // Twoje logo
                          width: 200,
                          height: 200,
                        ),
                        
                        // --- NAPIS Z NOWĄ CZCIONKĄ ---
                        const Text(
                          'ROOMIES',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'StackSansNotch', // <-- Tutaj nowa czcionka!
                            fontSize: 42, 
                            fontWeight: FontWeight.w900, 
                            color: primaryColor,
                            letterSpacing: 0.5, 
                          ),
                        ),
                        
                        const Spacer(flex: 1),

                        // --- SEKCJA TEKSTU (Inter) ---
                        const Text(
                          'Manage your place\ntogether.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                            height: 1.2, 
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Bill splitting, manage duties and groceries. All in one place.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: lightTextColor, 
                            height: 1.5, 
                          ),
                        ),

                        const Spacer(flex: 3), 

                        // --- PRZYCISKI ---
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const RegistrationScreen()),
                              );
                            },
                            child: const Text('Get Started'),
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const LoginScreen()),
                              );
                            },
                            child: const Text('I have an account'),
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}