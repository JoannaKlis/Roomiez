import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
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
          _emailController.text = FirebaseAuth.instance.currentUser?.email ?? userData['email'] ?? 'No email'; 
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
      AuthService.showErrorSnackBar(context, 'First name and last name cannot be empty.');
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
            content: Text('Profile updated successfully!'),
            backgroundColor: primaryColor, // Używamy primaryColor z constants.dart
            behavior: SnackBarBehavior.floating,
          ),
        );
        // Opcjonalnie: cofnij się po zapisie
        // Navigator.pop(context); 
      } else {
        AuthService.showErrorSnackBar(context, 'Update error: $errorMessage');
      }
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor, 
      
      // --- APP BAR ---
      appBar: AppBar(
        title: const Text('Edit Profile'), // Angielski dla spójności
        backgroundColor: backgroundColor,
        foregroundColor: textColor, 
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryColor)) 
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                child: ListView(
                  children: <Widget>[
                    
                    // --- ZDJĘCIE PROFILOWE (Opcjonalnie - placeholder) ---
                    Center(
                      child: Stack(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: surfaceColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: borderColor, width: 2),
                            ),
                            child: const Icon(Icons.person, size: 50, color: lightTextColor),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: primaryColor,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 30),

                    // --- FORMULARZ ---

                    // 1. Imię
                    const Text("First Name", style: TextStyle(fontWeight: FontWeight.w600, color: textColor)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _firstNameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        hintText: 'Enter your first name',
                        prefixIcon: Icon(Icons.person_outline, color: lightTextColor),
                      ),
                    ),
                    const SizedBox(height: 20.0),

                    // 2. Nazwisko
                    const Text("Last Name", style: TextStyle(fontWeight: FontWeight.w600, color: textColor)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _lastNameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        hintText: 'Enter your last name',
                        prefixIcon: Icon(Icons.person_outline, color: lightTextColor),
                      ),
                    ),
                    const SizedBox(height: 20.0),

                    // 3. E-mail (Tylko do odczytu)
                    const Text("Email Address", style: TextStyle(fontWeight: FontWeight.w600, color: lightTextColor)), // Szary nagłówek bo nieaktywne
                    const SizedBox(height: 8),
                    TextField(
                      controller: _emailController,
                      readOnly: true, // Zablokowane
                      style: const TextStyle(color: lightTextColor), // Szary tekst
                      decoration: InputDecoration(
                        hintText: 'Email address',
                        prefixIcon: const Icon(Icons.email_outlined, color: lightTextColor),
                        fillColor: surfaceColor.withOpacity(0.5), // Ciemniejszy/inny odcień tła
                        enabledBorder: OutlineInputBorder( // Szara ramka dla nieaktywnego
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: borderColor.withOpacity(0.5)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: borderColor.withOpacity(0.5)),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 40.0),

                    // --- PRZYCISK ZAPISU ---
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveProfile,
                        child: const Text('Save Changes'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}