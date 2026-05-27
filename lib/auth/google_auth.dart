import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

class FirebaseServices {
  final FirebaseAuth auth = FirebaseAuth.instance;
  // ✅ Kept your original instance
  final GoogleSignIn googleSignIn = GoogleSignIn.instance;
  bool _isGoogleInitialized = false;

  // ✅ Kept your original initialization logic
  Future<void> _initializeGoogleSignIn() async {
    try {
      await googleSignIn.initialize();
      _isGoogleInitialized = true;
    } catch (e) {
      debugPrint('Google Sign-In initialization failed: $e');
    }
  }

  // ✅ Kept your original Google Sign-In logic
  Future<UserCredential?> signInWithGoogle() async {
    if (!_isGoogleInitialized) {
      await _initializeGoogleSignIn();
    }
    try {
      // Using 'authenticate()' as per your working version
      final GoogleSignInAccount? googleUser = await googleSignIn.authenticate();

      if (googleUser == null) {
        debugPrint('Sign-in aborted by user');
        return null;
      }

      final googleAuth = await googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null) {
        debugPrint('No ID token retrieved from Google.');
        return null;
      }

      final credential = GoogleAuthProvider.credential(
        idToken: idToken,
      );

      final userCredential = await auth.signInWithCredential(credential);
      debugPrint('User signed in with Google.');
      return userCredential;
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('Error during Google Sign-In: $e');
      return null;
    }
  }

  // ✅ UPGRADED: Improved Sign-Up Error Handling
  Future<String?> signUpWithEmail(String email, String password) async {
    try {
      final userCredential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await userCredential.user?.sendEmailVerification();

      return null; // no error
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
          return "This email is already registered.";
        case 'invalid-email':
          return "Invalid email format.";
        case 'weak-password':
          return "Password is too weak.";
        default:
          return e.message ?? "Something went wrong. Please try again.";
      }
    } catch (e) {
      return "Unexpected error. Please try again later.";
    }
  }

  // ✅ UPGRADED: Improved Login Error Handling
  // Now throws exceptions so the UI can show the Red SnackBar
  Future<UserCredential?> loginWithEmail(String email, String password) async {
    try {
      final userCredential = await auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      debugPrint('User logged in with email.');
      return userCredential;
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException: ${e.message}');
      // Throw the error message to the UI
      throw e.message ?? "Login failed";
    } catch (e) {
      debugPrint('Error during Email Login: $e');
      throw "An unexpected error occurred.";
    }
  }

  // ✅ Kept your original Sign Out logic
  Future<void> signOut() async {
    try {
      await auth.signOut();
      await googleSignIn.signOut();
      debugPrint('User signed out.');
    } catch (e) {
      debugPrint('Error signing out: $e');
    }
  }
}