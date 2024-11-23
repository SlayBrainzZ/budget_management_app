import 'package:firebase_core/firebase_core.dart';
import 'package:budget_management_app/backend/firestore_service.dart';
import 'package:budget_management_app/backend/User.dart' as testUser;
import 'package:budget_management_app/backend/Category.dart' as testCat;
import 'package:budget_management_app/auth.dart';
import 'package:budget_management_app/widget_tree.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

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

    // Perform CRUD operations
    await performCrudOperations();

  } catch (e) {
    print("Firebase initialization failed: $e");
  }
}

// Perform CRUD operations on Firestore
Future<void> performCrudOperations() async {
  try {
    String testUserId = 'EpM9fLEBKLQqNkPQ4A3Hw1PjMnD2';

    // Retrieve categories for the test user
    List<testCat.Category> categories = await FirestoreService().getUserCategories(testUserId);

    if (categories.isNotEmpty) {
      print('Retrieved categories:');
      for (var category in categories) {
        print(category.toMap());
      }

      // Update the first category as an example
      testCat.Category categoryToUpdate = categories[1];
      categoryToUpdate.name = 'Updated Nike'; // Update name
      categoryToUpdate.budgetLimit = 2000000; // Update budget limit

      // Call the Firestore update function
      await FirestoreService().updateCategory(testUserId, categoryToUpdate);

      // Re-fetch categories to verify the update
      List<testCat.Category> updatedCategories =
      await FirestoreService().getUserCategories(testUserId);

      print('Updated categories:');
      for (var updatedCategory in updatedCategories) {
        print(updatedCategory.toMap());
      }
    } else {
      print('No categories found for this user.');
    }
  } catch (e) {
    print("Error performing CRUD operations: $e");
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
