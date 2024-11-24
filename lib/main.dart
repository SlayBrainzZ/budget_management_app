import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:budget_management_app/backend/firestore_service.dart';
import 'package:budget_management_app/backend/User.dart' as testUser;
import 'package:budget_management_app/backend/Category.dart' as testCat;
import 'package:budget_management_app/backend/Transaction.dart' as testTrans;
import 'package:budget_management_app/auth.dart';
import 'package:budget_management_app/widget_tree.dart';
import 'package:flutter/foundation.dart';
import 'dart:math'; // For random selection

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensure bindings are initialized for Firebase

  try {
    if (kIsWeb) { // For Web
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "AIzaSyBRElGRhjY1HjJqe7Zt-PKLn1YRy9IEkXs",
          authDomain: "budget-management-app-a9b5e.firebaseapp.com",
          projectId: "budget-management-app-a9b5e",
          storageBucket: "budget-management-app-a9b5e.appspot.com",
          messagingSenderId: "528312897299",
          appId: "1:528312897299:web:e19b90d51e49dba62b54e6",
          measurementId: "G-LKZ75WL9T7",
        ),
      );
    } else { // For Mobile (Android, iOS)
      await Firebase.initializeApp();
    }

    runApp(const MyApp());

    // Perform CRUD operations (combined test)
    await performCombinedTest();

  } catch (e) {
    print("Firebase initialization failed: $e");
  }
}

// Perform Combined Test: Creating user, category, transaction, and fetching them
Future<void> performCombinedTest() async {
  try {
    // Step 1: Listen for auth state changes and create user document
    Auth().authStateChanges.listen((user) async {
      if (user != null) {
        print('User registered: ${user.email}');

        // Now that a user is registered, let's create the User document in Firestore
        await FirestoreService().createUser(testUser.User(
          userId: user.uid,
          email: user.email!,
          createdDate: DateTime.now(),
        ));

        // Step 2: Retrieve the user's categories
        List<testCat.Category> categories = await FirestoreService().getUserCategories(user.uid);
        if (categories.isEmpty) {
          print('No categories found for user');
          return;
        }

        // Step 3: Choose a random category
        Random random = Random();
        testCat.Category randomCategory = categories[random.nextInt(categories.length)];

        print('Random category selected: ${randomCategory.name}');

        // Step 4: Create a transaction under the selected category
        testTrans.Transaction newTransaction = testTrans.Transaction(
          userId: user.uid,
          amount: 50.0,
          date: DateTime.now(),
          categoryId: randomCategory.id, // Link transaction to the random category
          type: 'Expense',
          importance: true,
        );
        await FirestoreService().createTransactionUnderCategory(user.uid, newTransaction, randomCategory.id!);

        // Step 5: Retrieve and print all transactions for the selected category
        List<testTrans.Transaction> transactions = await FirestoreService().getCategoryTransactions(user.uid, randomCategory.id!);
        print('Transactions for category ${randomCategory.name}:');
        for (var transaction in transactions) {
          print(transaction.toMap());
        }
      }
    });

  } catch (e) {
    print("Error performing combined test: $e");
  }
}

// Main application widget
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Budget Management App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const WidgetTree(), // Use WidgetTree for authentication
    );
  }
}
