import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';

class LoginController {
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Sign in existing user
  Future<UserCredential?> authenticate(String email, String password) async {
  try {
    final firebaseAuth = FirebaseAuth.instance;
    final userCredential = await firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = userCredential.user;
    if (user != null && user.emailVerified) {
      return userCredential;
    } else {
      await firebaseAuth.signOut(); // Sign out unverified user
      throw FirebaseAuthException(
        code: 'email-not-verified',
        message: 'Email not verified. Please check your inbox.',
      );
    }
  } catch (e) {
    if (e is FirebaseAuthException) {
      // Propagate FirebaseAuthException
      throw e;
    } else {
      // Handle non-Firebase exceptions
      throw Exception('Authentication failed: $e');
    }
  }
}


  // Register new user and store in Firestore
  Future<UserCredential?> register(String email, String password) async {
    try {
      final firebaseUser = await _authService.signUpWithEmail(email, password);
      if (firebaseUser != null) {
        await _firestore.collection('users').doc(firebaseUser.uid).set({
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
        });

        return await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      }
      return null;
    } catch (e) {
      throw Exception("Registration failed: $e");
    }
  }

  String? getCurrentUserId() => _authService.currentUser?.uid;

  Future<void> signOut() async => _authService.signOut();
}
