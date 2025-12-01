import 'package:flutter/material.dart';
import 'constants.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/welcome_screen.dart';

// testing screens
import 'screens/expenses_screen.dart';
import 'screens/tasks_screen.dart';
import 'screens/profile_edit_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ROOMIES',
      debugShowCheckedModeBanner: false,
      
      // --- NOWY STYL (CLEAN UI) ---
      theme: ThemeData(
        useMaterial3: true, // Włączamy nowsze standardy UI
        fontFamily: appFontFamily,
        primaryColor: primaryColor,
        scaffoldBackgroundColor: backgroundColor,

        // Nowoczesna paleta kolorów
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          primary: primaryColor,
          surface: backgroundColor,
          onSurface: textColor,
          background: backgroundColor,
        ),
        
        // GLOBALNY STYL TEKSTU
        textTheme: ThemeData.light().textTheme.apply(
          fontFamily: appFontFamily,
          bodyColor: textColor,
          displayColor: textColor,
        ),
        
        // Styl paska aplikacji (Czysty, płaski, biały)
        appBarTheme: const AppBarTheme(
          backgroundColor: backgroundColor,
          surfaceTintColor: Colors.transparent, // Zapobiega zmianie koloru przy scrollu
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: textColor),
          titleTextStyle: TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            fontFamily: appFontFamily,
            letterSpacing: -0.5,
          ),
        ),
        
        // Styl przycisków głównych (Płaskie, lekko zaokrąglone)
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            elevation: 0, // Zero cienia -> Flat Design
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              fontFamily: appFontFamily,
            ),
          ),
        ),
        
        // Styl przycisków pobocznych (Delikatna szara ramka)
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: textColor,
            elevation: 0,
            side: const BorderSide(color: borderColor, width: 1), // borderColor z constants.dart
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              fontFamily: appFontFamily,
            ),
          ),
        ),
        
        // Styl pól wprowadzania tekstu (Szare tło, brak ramki domyślnie)
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surfaceColor, // Jasnoszary z constants.dart
          contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
          hintStyle: const TextStyle(color: lightTextColor, fontFamily: appFontFamily),
          
          // Stan spoczynku - bez ramki
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide.none,
          ),
          
          // Stan aktywny - ramka w kolorze głównym
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: const BorderSide(color: primaryColor, width: 1.5),
          ),
          
          // Stan błędu
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: const BorderSide(color: Colors.redAccent, width: 1),
          ),
        ),
        
        // Styl Checkboxów
        checkboxTheme: CheckboxThemeData(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          fillColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
              return primaryColor;
            }
            return null; // Domyślny kolor
          }),
        ),
      ),

      routes: {
        ProfileEditScreen.id: (context) => const ProfileEditScreen(), 
      },
      
      home: const WelcomeScreen(),
      // zakomentowane ekrany do testowania - ZOSTAWIŁEM NIETKNIĘTE
      // home: const TasksScreen(),
      // home: const ExpensesScreen(), 
      // home: const ProfileEditScreen(),
    );
  }
}