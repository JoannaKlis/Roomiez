import 'package:flutter/material.dart';
import '../constants.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import 'registration_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({Key? key}) : super(key: key);

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
            // strzałka powrotu
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
                      // Logo i tytuł
                      const Center(
                        child: Column(
                          children: [
                            Icon(Icons.house, size: 80.0, color: textColor),
                            SizedBox(height: 10),
                            Text('ROOMIEZ',
                                style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: textColor)),
                            SizedBox(height: 20),
                            Text('Welcome back!',
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: textColor)),
                            SizedBox(height: 5),
                            Text('Please enter your details to log in.',
                                style: TextStyle(
                                    fontSize: 14, color: lightTextColor)),
                            SizedBox(height: 40),
                          ],
                        ),
                      ),
                      // wprowadzanie danych (email, hasło)
                      const CustomTextField(
                        label: 'Email address',
                        hint: 'Enter your email address',
                      ),
                      const SizedBox(height: 20),
                      const CustomTextField(
                        label: 'Password',
                        hint: 'Enter your password',
                        isPassword: true,
                      ),
                      // Link "zapomniałem hasła"
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {},
                          child: const Text('Forgot your password?',
                              style: TextStyle(color: textColor)),
                        ),
                      ),
                      const SizedBox(height: 50),
                      // Regulamin i polityka prywatności
                      const Text(
                        'By signing in, you agree to our Terms of Service and Privacy Policy',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: lightTextColor),
                      ),
                      const SizedBox(height: 15),
                      // Przycisk logowania
                      CustomButton(
                        text: 'Log In',
                        isPrimary: true,
                        onPressed: () {},
                      ),
                      const SizedBox(height: 30),
                      // Link do rejestracji
                      Center(
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const RegistrationScreen()));
                          },
                          child: const Text(
                            "Don't have an account? Create one!",
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
