import 'dart:async';
import 'package:budget_management_app/backend/BankAccount.dart';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:budget_management_app/backend/firestore_service.dart';
import 'package:budget_management_app/backend/User.dart' as testUser;
import 'package:budget_management_app/backend/Category.dart' as testCat;
import 'package:budget_management_app/backend/Transaction.dart' as testTrans;
import 'package:budget_management_app/auth.dart';
import 'package:budget_management_app/widget_tree.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'dart:io'; // For File handling on mobile/desktop
import 'dart:html' as html;
import 'backend/ImportedTransaction.dart'; // For File handling on web



void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensure bindings are initialized for Firebase

  try {
    // Firebase initialization
    if (kIsWeb) {
      // For Web
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
    } else {
      // For Mobile (Android, iOS)
      await Firebase.initializeApp();
    }



    // Listen to auth state changes
    Auth().authStateChanges.listen((user) async {
      if (user != null) {
        print("User logged in: ${user.email}");

        // Get user's bank accounts
        FirestoreService firestoreService = FirestoreService();
        List<BankAccount> accounts = await firestoreService.getUserBankAccounts2(user.uid);

        if (accounts.isNotEmpty) {
          String? hardcodedAccountId = accounts[0].id;

          // 1. Create one category
          testCat.Category category = testCat.Category(
            userId: user.uid,
            name: "Nike",
            budgetLimit: 999,
            accountId: hardcodedAccountId,
          );
          String categoryId = await firestoreService.createCategoryV2(user.uid, hardcodedAccountId!, category);
          print("Category created successfully on account $hardcodedAccountId");

          // 2. Create one transaction with the created category
          testTrans.Transaction transaction = testTrans.Transaction(
            userId: user.uid,
            amount: 100.0,
            date: DateTime.now(),
            type: 'expense',
            importance: false,
            categoryId: categoryId,
            accountId: hardcodedAccountId,
          );
          await firestoreService.createTransactionV2(user.uid, hardcodedAccountId, transaction, categoryId: categoryId);
          print("Transaction with category ${category.name} created successfully on account $hardcodedAccountId");

          // 3. Create another transaction (without a category)
          testTrans.Transaction transaction2 = testTrans.Transaction(
            userId: user.uid,
            amount: 50.0,
            date: DateTime.now(),
            type: 'income',
            importance: false,
            accountId: hardcodedAccountId,
          );
          await firestoreService.createTransactionV2(user.uid, hardcodedAccountId, transaction2);
          print("Another transaction created successfully on account $hardcodedAccountId");
        } else {
          print("No bank accounts found for this user.");
        }
      } else {
        print("No user logged in. Please log in.");
      }
    });

    // Start the app
    runApp(const MyApp());
  } catch (e) {
    debugPrint("Firebase initialization failed: $e");
  }
}



/*
// Perform Combined Test: Register a user, create a category, transaction, and display them
 Future<void> performCombinedTest() async {
  try {
    // Step 1: Listen for auth state changes and create user document
    Auth().authStateChanges.listen((user) async {
      if (user != null) {
        print('User registered: ${user.email}');

        // Create the User document in Firestore
        await FirestoreService().createUser(testUser.User(
          userId: user.uid,
          email: user.email!,
          createdDate: DateTime.now(),
        ));

        // Step 2: Create a category for the user
        testCat.Category newCategory = testCat.Category(
          userId: user.uid,
          name: "Groceries",
          budgetLimit: 500.0,
        );
        String categoryId = await FirestoreService().createCategory(user.uid, newCategory);
        newCategory.id = categoryId; // Assign the ID to the category object

        print('Category created: ${newCategory.name} (ID: ${newCategory.id})');

        // Step 3: Create a transaction under the created category
        testTrans.Transaction newTransaction = testTrans.Transaction(
          userId: user.uid,
          amount: 100.0,
          date: DateTime.now(),
          categoryId: newCategory.id,
          type: 'Expense',
          importance: false,
        );
        await FirestoreService().createTransactionUnderCategory(
          user.uid,
          newTransaction,
          newCategory.id!,
        );

        print('Transaction created under category ${newCategory.name}');

        // Step 4: Retrieve and print the created category
        List<testCat.Category> categories = await FirestoreService().getUserCategories(user.uid);
        print('Categories for user ${user.email}:');
        for (var category in categories) {
          print(category.toMap());
        }

        // Step 5: Retrieve and print transactions under the created category
        List<testTrans.Transaction> transactions = await FirestoreService().getCategoryTransactions(user.uid, newCategory.id!);
        print('Transactions for category ${newCategory.name}:');
        for (var transaction in transactions) {
          print(transaction.toMap());
        }
      }
    });
  } catch (e) {
    print("Error performing combined test: $e");
  }
}*/

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
