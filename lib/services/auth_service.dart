import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:roomies/utils/user_roles.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // rejestracja użytkownika z dodatkowymi danymi
  Future<String?> registerUser(
      String email, String password, String firstName, String lastName) async {
    try {
      // rejestracja w Firebase Authentication
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;
      if (user != null) {
        // zapisanie dodatkowych danych do Firestore Database (users)
        await _firestore.collection('users').doc(user.uid).set({
          'firstName': firstName,
          'lastName': lastName,
          'email': email,
          'role': UserRole.user, // domyślna rola
          'groupId': 'default_group', // domyślna grupa DO ZMIANY W PRZYSZŁOŚCI
          // hasło nie jest przechowywane w Firestore, bo jest w Auth i jest hashowane
        });
      }

      return null;
    } on FirebaseAuthException catch (e) {
      // zwrócenie komunikatu o błędzie (np. gdy email jest już użyty)
      return e.message;
    } catch (e) {
      return 'An unexpected error occurred: ${e.toString()}';
    }
  }

  // logowanie użytkownika
  Future<String?> signInUser(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return null;
    } on FirebaseAuthException catch (e) {
      // zwrócenie komunikatu o błędzie
      if (e.code == 'user-not-found') {
        return 'No user found for that email.';
      } else if (e.code == 'wrong-password') {
        return 'Wrong password provided for that user.';
      }
      return e.message;
    } catch (e) {
      return 'An unexpected error occurred: ${e.toString()}';
    }
  }

  // wyświetlenie komunikatu o błędzie
  static void showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
