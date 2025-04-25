import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Function to add a user to Firestore (this is used for creating the user document)
  Future<void> addUser(String username, String password) async {
    try {
      // Register the user in Firebase Authentication
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: username,  // For now, using the username as email
        password: password,
      );
      
      // Create a user document in Firestore with the authenticated user UID
      await _db.collection('users').doc(userCredential.user!.uid).set({
        'username': username,
        'createdAt': FieldValue.serverTimestamp(),
      });

    } catch (e) {
      print("Error adding user: $e");
    }
  }

  // Function to get user from Firestore using the username
  Future<DocumentSnapshot> getUser(String username) async {
    try {
      return await _db.collection('users')
          .where('username', isEqualTo: username)
          .limit(1)
          .get()
          .then((snapshot) => snapshot.docs.first);
    } catch (e) {
      print("Error getting user: $e");
      throw Exception('Error fetching user');
    }
  }

  // Function to sign in a user
  Future<User?> signInWithEmailPassword(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } catch (e) {
      print("Error signing in: $e");
      return null;
    }
  }

  // Function to get current user
  User? get currentUser => _auth.currentUser;
}
