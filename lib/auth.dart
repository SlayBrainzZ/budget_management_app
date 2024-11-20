import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:budget_management_app/backend/User.dart' as testUser;
import 'package:budget_management_app/backend/firestore_service.dart';
import 'package:budget_management_app/backend/user_provider.dart';
import 'package:provider/provider.dart';

class Auth {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  User? get currentUser => _firebaseAuth.currentUser;

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  Future<void> signInWithEmailAndPassword({
    required BuildContext context, // Add context parameter
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential = await _firebaseAuth.signInWithEmailAndPassword(
          email: email,
          password: password
      );

      // Retrieve user data from Firestore
      testUser.User? user = await FirestoreService().getUser(userCredential.user!.uid);

      if (user != null) {
        // Store the user object in the UserProvider
        Provider.of<UserProvider>(context, listen: false).setUser(user);
      } else {
        print('User data not found in Firestore.');
      }

    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw Exception('No user found for that email.');
      } else if (e.code == 'wrong-password') {
        throw Exception('Wrong password provided for that user.');
      }
    }
  }

  Future<void> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
          email: email,
          password: password
      );

      // Create user document in Firestore
      testUser.User newUser = testUser.User(
        userId: userCredential.user!.uid,
        email: email,
        createdDate: DateTime.now(),
        name: '',
      );
      await FirestoreService().createUser(newUser);

    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        throw Exception('The password provided is too weak.');
      } else if (e.code == 'email-already-in-use') {
        throw Exception('The account already exists for that email.');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }
}