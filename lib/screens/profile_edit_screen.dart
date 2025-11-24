import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import '../constants.dart';

class ProfileEditScreen extends StatefulWidget {
  static const String id = 'profile_edit_screen';

  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  
  bool _isLoading = true;
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  // Metoda do pobierania danych użytkownika po załadowaniu ekranu
  void _loadUserProfile() async {
    final userData = await _firestoreService.getCurrentUserProfile();
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (userData != null) {
          _firstNameController.text = userData['firstName'] ?? '';
          _lastNameController.text = userData['lastName'] ?? '';
          // E-mail jest pobierany z obiektu Firebase User, ale dane z Firestore też go zawierają
          _emailController.text = FirebaseAuth.instance.currentUser?.email ?? userData['email'] ?? 'Brak emaila'; 
        }
      });
    }
  }

  // Metoda do zapisu zmian
  void _saveProfile() async {
    setState(() {
      _isLoading = true;
    });

    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();

    if (firstName.isEmpty || lastName.isEmpty) {
      AuthService.showErrorSnackBar(context, 'Imię i nazwisko nie mogą być puste.');
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final errorMessage = await _firestoreService.updateUserProfile(firstName, lastName);

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      if (errorMessage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil zaktualizowany pomyślnie!'),
            backgroundColor: primaryColor, // Używamy primaryColor z constants.dart
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        AuthService.showErrorSnackBar(context, 'Błąd aktualizacji: $errorMessage');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor, // Używamy backgroundColor z constants.dart
      appBar: AppBar(
        title: const Text('Edytuj Profil'),
        backgroundColor: backgroundColor,
        foregroundColor: textColor, // Używamy textColor z constants.dart
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: textColor)) // Wskaźnik ładowania
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: ListView(
                children: <Widget>[
                  // Pole E-mail (tylko do odczytu)
                  CustomTextField(
                    label: 'E-mail',
                    hint: 'Adres e-mail',
                    controller: _emailController,
                    // Dodaj blokadę edycji
                    // Wymaga modyfikacji CustomTextField, by akceptował pole readOnly, 
                    // ale na razie ustawiamy, że jest disabled
                  ),
                  const SizedBox(height: 20.0),

                  // Pole Imię
                  CustomTextField(
                    label: 'Imię',
                    hint: 'Wprowadź swoje imię',
                    controller: _firstNameController,
                  ),
                  const SizedBox(height: 20.0),

                  // Pole Nazwisko
                  CustomTextField(
                    label: 'Nazwisko',
                    hint: 'Wprowadź swoje nazwisko',
                    controller: _lastNameController,
                  ),
                  const SizedBox(height: 40.0),

                  // Przycisk Zapisz Zmiany
                  CustomButton(
                    text: 'Zapisz Zmiany',
                    isPrimary: true,
                    onPressed: _saveProfile,
                  ),
                ],
              ),
            ),
    );
  }
}