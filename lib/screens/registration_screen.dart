import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../constants.dart';
import 'login_screen.dart';
import 'package:roomies/services/auth_service.dart';
import 'package:url_launcher/url_launcher.dart';

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
  bool _isRegistering = false;
  bool _acceptedPrivacyPolicy = false;

  // sprawdzenie czy hasło i potwierdzenie hasła są takie same
  void _handleRegistration() async {
    if (_isRegistering) return;
    
    // Walidacja akceptacji Privacy Policy
    if (!_acceptedPrivacyPolicy) {
      AuthService.showErrorSnackBar(context, 'Please accept the Terms of Privacy Policy to continue.');
      return;
    }
    
    setState(() => _isRegistering = true);

    String password = _passwordController.text;

    // Walidacja pustych pól
    if (_emailController.text.isEmpty ||
        _nameController.text.isEmpty ||
        _surnameController.text.isEmpty ||
        password.isEmpty) {
      AuthService.showErrorSnackBar(context, 'Please fill in all fields.');
      setState(() => _isRegistering = false);
      return;
    }

    final passwordRegex = RegExp(r'^(?=.*[A-Z])(?=.*\d)(?=.*[#$@!%&*?]).{9,}$');

    if (!passwordRegex.hasMatch(password)) {
      AuthService.showErrorSnackBar(
        context, 
        'Password must be at least 9 characters long, include an uppercase letter, a digit, and a special character.'
      );
      setState(() => _isRegistering = false);
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      AuthService.showErrorSnackBar(context, 'Passwords do not match.');
      setState(() => _isRegistering = false);
      return;
    }

    final errorMessage = await _authService.registerUser(
      _emailController.text.trim(),
      _passwordController.text,
      _nameController.text.trim(),
      _surnameController.text.trim(),
    );

    setState(() => _isRegistering = false);

    if (errorMessage == null) {
      // po udanej rejestracji pokaż dialog z informacją o weryfikacji
      if (mounted) {
        _showVerificationDialog();
      }
    } else {
      // błąd rejestracji
      if (mounted) {
        AuthService.showErrorSnackBar(context, errorMessage);
      }
    }
  }

  // Funkcja do otworzenia linku Privacy Policy
  void _openPrivacyPolicy() async {
    const String url = 'https://docs.google.com/document/d/1FSz3qdZZWYgxsZ6H9PwFyjhSn5bUT5JWXF0oqCarrJc/edit?usp=sharing';
    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        AuthService.showErrorSnackBar(context, 'Could not open Privacy Policy');
      }
    }
  }

  // Dialog informujący o konieczności weryfikacji emaila
  void _showVerificationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: backgroundColor,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.mark_email_unread_outlined,
                  color: primaryColor,
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Verify Your Email',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: textColor,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'StackSansNotch',
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'We\'ve sent a verification link to:',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: lightTextColor,
                  fontFamily: appFontFamily,
                ),
              ),
              const SizedBox(height: 10),
              // wyróżniony adres email
              Text(
                _emailController.text.trim(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                  fontFamily: appFontFamily,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Check your inbox and click the link to activate your account.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: textColor,
                  height: 1.5,
                  fontFamily: appFontFamily,
                ),
              ),
              const SizedBox(height: 24),
              // info o spamie
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, size: 18, color: lightTextColor),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Don\'t see it? Check your spam folder.',
                        style: TextStyle(
                          fontSize: 12,
                          color: lightTextColor,
                          fontFamily: appFontFamily,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                  );
                },
                child: const Text('OK, Got it!'),
              ),
            ),
          ],
        );
      },
    );
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
            const SliverAppBar(
              backgroundColor: backgroundColor,
              elevation: 0,
              floating: true,
              leading: SizedBox(height: 10),
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
                        hintText: 'Create a password (min. 9 characters, 1 uppercase, 1 digit, 1 special char)',
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

                    // --- CHECKBOX REGULAMINU ---
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Checkbox(
                          value: _acceptedPrivacyPolicy,
                          onChanged: (bool? value) {
                            setState(() {
                              _acceptedPrivacyPolicy = value ?? false;
                            });
                          },
                          activeColor: primaryColor,
                          side: const BorderSide(color: primaryColor),
                        ),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              children: [
                                const TextSpan(
                                  text: 'I accept the ',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: textColor,
                                    fontFamily: appFontFamily,
                                  ),
                                ),
                                TextSpan(
                                  text: 'Terms of Privacy Policy',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: primaryColor,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: appFontFamily,
                                    decoration: TextDecoration.underline,
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = _openPrivacyPolicy,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

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