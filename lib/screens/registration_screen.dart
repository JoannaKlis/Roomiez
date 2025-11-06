import 'package:flutter/material.dart';
import '../constants.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import 'login_screen.dart';
import 'package:roomies/services/auth_service.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({Key? key}) : super(key: key);

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

// konrtolery do zarządzania wprowadzonymi danymi
class _RegistrationScreenState extends State<RegistrationScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _surnameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final AuthService _authService = AuthService();

  // sprawdzenie czy hasło i potwierdzenie hasła są takie same
  void _handleRegistration() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      AuthService.showErrorSnackBar(context, 'Passwords do not match.');
      return;
    }

    // walidacja pustych pól
    if (_emailController.text.isEmpty ||
        _nameController.text.isEmpty ||
        _surnameController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      AuthService.showErrorSnackBar(context, 'Please fill in all fields.');
      return;
    }

    final errorMessage = await _authService.registerUser(
      _emailController.text.trim(),
      _passwordController.text,
      _nameController.text.trim(),
      _surnameController.text.trim(),
    );

    if (errorMessage == null) {
      // po udanej rejestracji przejdź do ekranu logowania
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration successful! Please log in.'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pushReplacement(
          // zmiana na pushReplacement, aby zapobiec powrotowi
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    } else {
      // błąd rejestracji (np. gdy email jest już zajęty)
      if (mounted) {
        AuthService.showErrorSnackBar(context, errorMessage);
      }
    }
  }

  // zwolnienie kontrolerów
  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    _surnameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
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
                      CustomTextField(
                          controller: _emailController,
                          label: 'Email address',
                          hint: 'Enter your email address'),
                      const SizedBox(height: 15),
                      CustomTextField(
                          controller: _nameController,
                          label: 'Name',
                          hint: 'Enter your name'),
                      const SizedBox(height: 15),
                      CustomTextField(
                          controller: _surnameController,
                          label: 'Surname',
                          hint: 'Enter your surname'),
                      const SizedBox(height: 15),
                      CustomTextField(
                          controller: _passwordController,
                          label: 'Password',
                          hint: 'Enter your password',
                          isPassword: true),
                      const SizedBox(height: 15),
                      CustomTextField(
                          controller: _confirmPasswordController,
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
                        onPressed: _handleRegistration,
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
