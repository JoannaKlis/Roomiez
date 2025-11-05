import 'package:flutter/material.dart';
import '../constants.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import 'login_screen.dart';

class RegistrationScreen extends StatelessWidget {
  const RegistrationScreen({Key? key}) : super(key: key);

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
                    crossAxisAlignment: CrossAxisAlignment.stretch,
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
                            Text('Registration',
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: textColor)),
                            SizedBox(height: 5),
                            Text('Please enter your details to register.',
                                style: TextStyle(
                                    fontSize: 14, color: lightTextColor)),
                            SizedBox(height: 40),
                          ],
                        ),
                      ),
                      // wprowadzanie danych
                      const CustomTextField(
                          label: 'Email address',
                          hint: 'Enter your email address'),
                      const SizedBox(height: 15),
                      const CustomTextField(
                          label: 'Name', hint: 'Enter your name'),
                      const SizedBox(height: 15),
                      const CustomTextField(
                          label: 'Surname', hint: 'Enter your surname'),
                      const SizedBox(height: 15),
                      const CustomTextField(
                          label: 'Password',
                          hint: 'Enter your password',
                          isPassword: true),
                      const SizedBox(height: 15),
                      const CustomTextField(
                          label: 'Confirm password',
                          hint: 'Confirm your password',
                          isPassword: true),
                      const SizedBox(height: 50),
                      // Regulamin i polityka prywatności
                      const Text(
                        'By signing up, you agree to our Terms of Service and Privacy Policy',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: lightTextColor),
                      ),
                      const SizedBox(height: 15),
                      // Przycisk rejestracji
                      CustomButton(
                        text: 'Register',
                        isPrimary: true,
                        onPressed: () {},
                      ),
                      const SizedBox(height: 30),
                      // Link do logowania
                      Center(
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const LoginScreen()));
                          },
                          child: const Text(
                            "Already have an account? Log in!",
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
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
