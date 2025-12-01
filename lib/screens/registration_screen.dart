import 'package:flutter/material.dart';
import '../constants.dart';
import 'login_screen.dart';
import 'package:roomies/services/auth_service.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({Key? key}) : super(key: key);

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

// kontrolery do zarządzania wprowadzonymi danymi
class _RegistrationScreenState extends State<RegistrationScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _surnameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final AuthService _authService = AuthService();

  // sprawdzenie czy hasło i potwierdzenie hasła są takie same (LOGIKA BEZ ZMIAN)
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
            backgroundColor: Colors.green, // Sukces na zielono
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    } else {
      // błąd rejestracji
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
      body: SafeArea(
        child: CustomScrollView(
          slivers: <Widget>[
            // Pasek nawigacji (powrót)
            SliverAppBar(
              backgroundColor: backgroundColor,
              elevation: 0,
              floating: true,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: textColor),
                onPressed: () => Navigator.pop(context),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              sliver: SliverList(
                delegate: SliverChildListDelegate(
                  [
                    const SizedBox(height: 10),

                    // --- SEKCJA NAGŁÓWKA ---
                    Center(
                      child: Column(
                        children: [
                          // Logo
                          Image.asset(
                            'assets/images/logo_roomies.png',
                            width: 80, // Trochę mniejsze, bo formularz jest długi
                            height: 80,
                          ),
                          // Tytuł ROOMIES
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
                          const SizedBox(height: 20),

                          // Nagłówek ekranu - WYŚRODKOWANY
                          const Text(
                            'Create Account',
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
                            'Please enter your details to register.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: lightTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    // --- FORMULARZ ---

                    // Email
                    const Text("Email address",
                        style: TextStyle(
                            fontWeight: FontWeight.w600, color: textColor)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        hintText: 'Enter your email address',
                        prefixIcon:
                            Icon(Icons.email_outlined, color: lightTextColor),
                      ),
                    ),

                    const SizedBox(height: 15),

                    // Name
                    const Text("Name",
                        style: TextStyle(
                            fontWeight: FontWeight.w600, color: textColor)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        hintText: 'Enter your name',
                        prefixIcon:
                            Icon(Icons.person_outline, color: lightTextColor),
                      ),
                    ),

                    const SizedBox(height: 15),

                    // Surname
                    const Text("Surname",
                        style: TextStyle(
                            fontWeight: FontWeight.w600, color: textColor)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _surnameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        hintText: 'Enter your surname',
                        prefixIcon:
                            Icon(Icons.person_outline, color: lightTextColor),
                      ),
                    ),

                    const SizedBox(height: 15),

                    // Password
                    const Text("Password",
                        style: TextStyle(
                            fontWeight: FontWeight.w600, color: textColor)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        hintText: 'Create a password',
                        prefixIcon: Icon(Icons.lock_outline_rounded,
                            color: lightTextColor),
                      ),
                    ),

                    const SizedBox(height: 15),

                    // Confirm Password
                    const Text("Confirm Password",
                        style: TextStyle(
                            fontWeight: FontWeight.w600, color: textColor)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _confirmPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        hintText: 'Confirm your password',
                        prefixIcon: Icon(Icons.lock_outline_rounded, // Zmiana na działającą ikonę
                            color: lightTextColor),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Regulamin
                    const Text(
                      'By signing up, you agree to our Terms of Service and Privacy Policy',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: lightTextColor),
                    ),

                    const SizedBox(height: 20),

                    // --- PRZYCISK REJESTRACJI ---
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _handleRegistration,
                        child: const Text('Register'),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // --- LINK DO LOGOWANIA ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Already have an account? ",
                          style: TextStyle(color: lightTextColor),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const LoginScreen()),
                            );
                          },
                          child: const Text(
                            "Log in",
                            style: TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}