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

void _signOut() async {
  try {
    await FirebaseAuth.instance.signOut(); //wylogowanie użytkownika
    if(!mounted) return; // mounted = flaga informująca czy widget jest teraz widoczny dla uzytkownika
    //jeśli nie jest - np. wyłączono nagle aplikacje (przypadek brzegowy) nie powinno być przekierowania
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()), //przekierowanie na ekran logowania
        (_) => false, // usunięcie poprzednich ekranów ze stosu - brak możliwości cofnięcia się do widoków chronionych po wylogowaniu
      );
    } catch (e) {
      debugPrint('Sign out error: $e');
    }
  }


  void _handleCreate() async {
    if (_nameController.text.trim().isEmpty) { // sprawdzenie czy podano nazwę grupy
      showSnackBarColor( // jeśli nie podano nazwy grupy wywoływana jest funkcja, która wyświetla komunikat o podanym kolorze i treści
          context, 'Please enter the name of your place!', Colors.red); //informacja o brakującej nazwie grupy
      return; // brak nazwy grupy powoduje zakończenie funkcji tworzenia grupy
    }

    final groupId =
        await _firestoreService.createNewGroup(_nameController.text); //wywoływana jest funkcja z firestrore_srevice.dart
        //która odpowiada za utworzenie grupy - wygenerowanie unikalnego kodu i zapisanie danych w bazie
        // jesli uda się utworzyć grupę to funkcja zwróci jej unikalny kod dołączenia

    if (groupId != "") { //jeśli nie udało się utworzyć grupy funkcja createNewGroup zwróciła pusty String
      showSnackBarColor(context, "Success", Colors.green); //informacja o sukcesie tworzenia grupy
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const HomeScreen(),
        ),
        (_) => false, //usunięcie wszelkich poprzednich ekranów ze stosu - nie powinno być możliwości 'cofnięcia się' do ekranu logowania
        //(w tym celu trzeba się wylogować)
      );
    } else {
      showSnackBarColor(context, "Cannot create a group", Colors.red); //jeśli nie udało się utworzyć grupy pojawia się odpowiedni komunikat
    }
  }

  void _handleJoin() async {
    final groupIdInput = _groupIdController.text.trim(); //usunięcie ewentualnych spacji z początku i końca wpisanego kodu grupy

    if (groupIdInput.isEmpty) { //sprawdzenie czy podano cokolwiek w miejscu na kod dołączenia do grupy
      showSnackBarColor(context, 'Please enter an invite code!', Colors.red); //jeśli nie podano żadnego teksu komunikat z prośbą o podanie kodu
      return;
    }

    //wywołanie funkcji z firestore_service.dart która dodaje użytkownika jeśli istnieje grupa o podanym kodzie (wówczas funkcja zwróci true)
    bool success = await _firestoreService.addUserToGroup(groupIdInput); 

    if (success) {
      //pobranie nazwy grupy jeśli pomyślnie dołączono 
      String realGroupName = await _firestoreService.getGroupName(groupIdInput);

      if (mounted) {
        //wyświetlenie komunikatu o pomyślnym dołączeniu do grupy o pobranej nazwie
        showSnackBarColor(context, "Success! Joined $realGroupName", Colors.green);
        // przeniesienie do ekranu głównego danej grupy i usunięcie wszelkich poprzednich ekranów ze stosu
        // nie powinno byc możliwości powrotu do ekranu logowania lub dołączenia -
        // - jedynym sposobem wyjścia z grupy / wylogowania się powinny być przyciski w menu_bar
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => const HomeScreen(),
          ),
          (_) => false,
        );
      }
    } else {
      if (mounted) {
        showSnackBarColor(context, "This group doesn't exist!", Colors.red);
      }
    }
  }

  // zwolnienie kontrolerów
  @override
  void dispose() {
    _nameController.dispose();
    _groupIdController.dispose();
    super.dispose();
  }

// funkcja do wyświetlania komunikatu w formie małego paska na dole ekranu, który po chwili znika
// przyjmuje treść wiadomości i kolor tła 
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
      body: SafeArea(
        child: CustomScrollView(
          slivers: <Widget>[
            // Pasek nawigacji (tylko strzałka powrotu, czysty styl)
            SliverAppBar(
              backgroundColor: backgroundColor,
              elevation: 0,
              floating: true,
              leading: IconButton(
                icon: const Icon(Icons.logout_rounded,
                    color: textColor),
                onPressed: () async {
                  _signOut();
                }
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
                            width: 80,
                            height: 80,
                          ),
                          // Napis ROOMIES
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

                          // Powitanie - WYŚRODKOWANE
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

                    // --- KARTA: CREATE NEW PLACE ---
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white, // Białe tło karty
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: borderColor), // Delikatna ramka
                        boxShadow: [
                          BoxShadow(
                            color: textColor.withOpacity(0.05), // Subtelny cień
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

                    // --- KARTA: JOIN EXISTING PLACE ---
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
                              // Używamy OutlinedButton dla drugiej akcji
                              onPressed: _handleJoin,
                              child: const Text('Join'),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 50),
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