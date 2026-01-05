import 'package:flutter/material.dart';
import '../constants.dart';
import 'registration_screen.dart';
import 'package:roomies/services/auth_service.dart';
import 'dashboard_screen.dart';
import 'home_screen.dart';
import '../services/firestore_service.dart';
import 'admin_dashboard_screen.dart';
import '../utils/user_roles.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

// kontrolery do zarządzania wprowadzonymi danymi
class _LoginScreenState extends State<LoginScreen> {
  bool _isLoggingIn = false;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  // admin do testowania:
  // email: admin@admin.com
  // hasło: adminadmin
  // funkcja do obsługi logowania
  void _handleLogin() async {
  if (_isLoggingIn) return;
  setState(() => _isLoggingIn = true);
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      AuthService.showErrorSnackBar(
          context, 'Please enter both email and password.');
      setState(() => _isLoggingIn = false);
      return;
    }

    // logowanie w Firebase Authentication
    final errorMessage = await _authService.signInUser(
      _emailController.text.trim(),
      _passwordController.text,
    );

  if (errorMessage != null) {
    AuthService.showErrorSnackBar(context, errorMessage);
    setState(() => _isLoggingIn = false);
    return;
  }

    if (errorMessage == null) {
      // uwierzytelnienie sukces -> pobieranie roli i  grupy z Firestore
      try {
        final userRole = await _firestoreService
            .getCurrentUserRole(); // Zwraca 'admin' lub 'user'
        final userProfile = await _firestoreService
            .getCurrentUserProfile(); // Pobiera resztę danych (groupId)

        if (!mounted) {
          setState(() => _isLoggingIn = false);
          return;
        }

        // przekierowanie na podstawie roli usera
        if (userRole == UserRole.administrator) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Welcome back, Admin! 🕵️‍♂️'),
              backgroundColor: Colors.black87,
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 2),
            ),
          );

          // przekierowanie admina
          setState(() => _isLoggingIn = false);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => const AdminDashboardScreen()),
          );
          return;
        }

        // przekierowanie zwykłych użytkowników
        final String groupId = userProfile?['groupId'];
        final String roomName = await _firestoreService.getGroupName(
            groupId ?? ''); // Pobierz nazwę lub domyślny komunikat

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Login successful!'),
            backgroundColor: primaryColor,
            behavior: SnackBarBehavior.floating,
            duration: Duration(milliseconds: 1500),
          ),
        );
        setState(() => _isLoggingIn = false);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => groupId != "default_group"
          ? HomeScreen(roomName: roomName, groupId: groupId,)
          : const DashboardScreen(),),
          //jeśli już ma groupId (nie default_group) to nie pokazuj ekranu z dołączeniem/tworzeniem miejsca
        );
      } catch (e) {
        if (mounted) {
          AuthService.showErrorSnackBar(
              context, 'Login successful, but failed to load user data: $e');
              setState(() => _isLoggingIn = false);
        }
      }
    } else {
      setState(() => _isLoggingIn = false);
      if (mounted) {
        AuthService.showErrorSnackBar(context, errorMessage);
      }
    }
  }

  // zwolnienie kontrolerów
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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
              // leading: IconButton(
              //   icon: const Icon(Icons.arrow_back_ios_new_rounded,
              //       color: textColor), // Nowocześniejsza strzałka
              //   onPressed: () => Navigator.pop(context),
              // ),
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
                          // Logo (spójne z WelcomeScreen)
                          Image.asset(
                            'assets/images/logo_roomies.png',
                            width: 100, // Nieco mniejsze niż na WelcomeScreen
                            height: 100,
                          ),
                          // Napis ROOMIES (Logotyp)
                          const Text(
                            'ROOMIES',
                            style: TextStyle(
                              fontFamily:
                                  'StackSansNotch', // Twoja czcionka firmowa
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: primaryColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 30),

                          // Powitanie
                          const Text(
                            'Welcome back!',
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
                            'Please enter your details to log in.',
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

                    // --- FORMULARZ (Inputy biorą styl z main.dart) ---

                    // Email
                    const Text("Email address",
                        style: TextStyle(
                            fontWeight: FontWeight.w600, color: textColor)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        hintText: 'Enter your email',
                        prefixIcon:
                            Icon(Icons.email_outlined, color: lightTextColor),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Hasło
                    const Text("Password",
                        style: TextStyle(
                            fontWeight: FontWeight.w600, color: textColor)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _handleLogin(),
                      decoration: const InputDecoration(
                        hintText: 'Enter your password',
                        prefixIcon: Icon(Icons.lock_outline_rounded,
                            color: lightTextColor),
                      ),
                    ),

                    // Link "Forgot Password"
                    // Align(
                    //   alignment: Alignment.centerRight,
                    //   child: TextButton(
                    //     onPressed: () {},
                    //     style: TextButton.styleFrom(
                    //       foregroundColor: lightTextColor,
                    //     ),
                    //     child: const Text('Forgot password?'),
                    //   ),
                    // ),

                    const SizedBox(height: 30),

                    // --- PRZYCISK LOGOWANIA ---
                    SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                          onPressed: _handleLogin, // blokada kliknięcia
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor, // zawsze kolor tła
                          ),
                          child: _isLoggingIn
                            ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                              color: Colors.white, // kolor spinnera biały
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Log In'),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // --- LINK DO REJESTRACJI ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Don't have an account? ",
                          style: TextStyle(color: lightTextColor),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const RegistrationScreen()),
                            );
                          },
                          child: const Text(
                            "Create one",
                            style: TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Regulamin (Mały druk na dole)
                    const Text(
                      'By signing in, you agree to our Terms of Service and Privacy Policy',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: lightTextColor),
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