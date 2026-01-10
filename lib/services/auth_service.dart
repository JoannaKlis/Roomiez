import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:roomies/utils/user_roles.dart';

class AuthService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  // Konstruktor pozwala wstrzyknąć instancje, a jeśli ich nie podamy, użyje domyślnych
  AuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  // rejestracja użytkownika z dodatkowymi danymi + WERYFIKACJA EMAILA
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
        // imię i naziwsko tymczasowo zapisywane w displayName
        await user.updateDisplayName('$firstName $lastName');
        
        // wysłanie maila weryfikacyjnego
        await user.sendEmailVerification();

        // dane nie są zapisywane do Firestore od razu, dopiero po weryfikacji emaila
        // wylogowanie usera
        await _auth.signOut();
      }

      return null;
    } on FirebaseAuthException catch (e) {
      // zwrócenie komunikatu o błędzie (np. gdy email jest już użyty)
      return e.message;
    } catch (e) {
      return 'An unexpected error occurred: ${e.toString()}';
    }
  }

  // logowanie użytkownika + SPRAWDZENIE WERYFIKACJI EMAILA
  Future<String?> signInUser(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;

      // odświeżenie tokenu aby emailVerified było aktualne
      await user?.reload();
      user = _auth.currentUser;

      // WERSJA DO TESTOWANIA - DO USUNIĘCIA PO WDROŻENIU !!!!!
      // sprawdzenie czy email został zweryfikowany
      if (user != null) {
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        final userData = userDoc.data();
        bool isVerifiedInDb = userDoc.exists && userData?['emailVerified'] == true;
        if (!user.emailVerified && !isVerifiedInDb) {
          await _auth.signOut(); // wylogowanie niezweryfikowanego użytkownika
          return 'Please verify your email address before logging in. Check your inbox for the verification link.';
        }

        if (!userDoc.exists) {
          String displayName = user.displayName ?? '';
          List<String> nameParts = displayName.split(' ');
        
          String firstName = nameParts.isNotEmpty ? nameParts[0] : 'User';
          String lastName = nameParts.length > 1 ? nameParts[1] : '';

          await _firestore.collection('users').doc(user.uid).set({
            'firstName': firstName,
            'lastName': lastName,
            'email': user.email,
            'role': UserRole.user,
            'groupId': 'default_group',
            'emailVerified': true,
          });
        } else {
          // AKTUALIZACJA DLA ISTNIEJĄCYCH (STARYCH) KONT
          Map<String, dynamic> updates = {'emailVerified': true};
          await _firestore.collection('users').doc(user.uid).update(updates);
        }
      }

      // FINALNA WERSJA - NIE USUWAĆ !!!!!
      // // PIERWSZE LOGOWANIE PO WERYFIKACJI - dodanie danych usera do Firestore
      // if (user != null && user.emailVerified) {
      //   final userDoc = await _firestore.collection('users').doc(user.uid).get();
        
      //   // jeśli użytkownik nie istnieje w bazie, dodaj go (pierwsze logowanie)
      //   if (!userDoc.exists) {
      //     // pobranie imienia i nazwiska z displayName (zapisane podczas rejestracji)
      //     String displayName = user.displayName ?? '';
      //     List<String> nameParts = displayName.split(' ');
      //     String firstName = nameParts.isNotEmpty ? nameParts[0] : 'User';
      //     String lastName = nameParts.length > 1 ? nameParts[1] : '';

      //     await _firestore.collection('users').doc(user.uid).set({
      //       'firstName': firstName,
      //       'lastName': lastName,
      //       'email': user.email,
      //       'role': UserRole.user,
      //       'groupId': 'default_group',
      //       'emailVerified': true
      //     });

      //     await user.updateDisplayName('$firstName $lastName');
      //   } else {
      //     // aktualizacja statusu weryfikacji dla istniejących użytkowników
      //     await _firestore.collection('users').doc(user.uid).update({
      //       'emailVerified': true,
      //     });
      //   }
      // }

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

  // ponowne wysłanie emaila weryfikacyjnego
  Future<String?> resendVerificationEmail(String email, String password) async {
    try {
      // tymczasowe zalogowanie użytkownika
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;

      if (user != null) {
        // odśwież status
        await user.reload();
        user = _auth.currentUser;

        if (user != null && user.emailVerified) {
          await _auth.signOut();
          return 'Your email is already verified. You can log in now.';
        }

        // ponowne wysłanie emaila weryfikacyjnego
        await user?.sendEmailVerification();
        await _auth.signOut();
        return null; // sukces
      }

      return 'Failed to resend verification email.';
    } on FirebaseAuthException catch (e) {
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

  // wyświetlenie komunikatu sukcesu
  static void showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}