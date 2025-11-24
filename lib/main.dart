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
      theme: ThemeData(
        fontFamily: appFontFamily,
        primaryColor: primaryColor,
        scaffoldBackgroundColor: backgroundColor,
        
        // GLOBALNY STYL TEKSTU - Uproszczone: narzuca textColor na wszystkie style.
        textTheme: ThemeData.light().textTheme.apply(
          bodyColor: textColor,
          displayColor: textColor,
        ),
        
        // Styl paska aplikacji
        appBarTheme: const AppBarTheme(
          backgroundColor: backgroundColor,
          elevation: 0,
          iconTheme: IconThemeData(color: textColor),
          titleTextStyle: TextStyle(
              color: textColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: appFontFamily),
        ),
        // Styl przycisków rejestracji
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: textColor,
            foregroundColor: backgroundColor,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0)),
            textStyle: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: appFontFamily),
          ),
        ),
        // Styl przycisków logowania
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: accentColor, width: 2),
            foregroundColor: textColor,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0)),
            textStyle: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: appFontFamily),
          ),
        ),
        // Styl pól wprowadzania tekstu
        inputDecorationTheme: InputDecorationTheme(
          hintStyle:
              const TextStyle(color: lightTextColor, fontFamily: appFontFamily),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 15.0, horizontal: 15.0),
          filled: true,
          fillColor: primaryColor.withAlpha(38),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: const BorderSide(color: primaryColor, width: 2.0),
          ),
        ),
      ),
      routes: {
        // Wszystkie trasy powinny być zdefiniowane w jednym miejscu
        ProfileEditScreen.id: (context) => const ProfileEditScreen(), 
      },
      home: const WelcomeScreen(),
      // zakomentowane ekrany do testowania
      // home: const TasksScreen(),
      // home: const ExpensesScreen(), 
      // home: const ProfileEditScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}