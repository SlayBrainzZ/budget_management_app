import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:budget_management_app/backend/User.dart';
import 'package:budget_management_app/backend/Transaction.dart';
import 'package:budget_management_app/backend/Category.dart';
import 'package:budget_management_app/backend/BankAccount.dart';
import 'package:budget_management_app/backend/Subscriptions.dart';
import 'package:flutter/foundation.dart' as csv;
import 'package:flutter/material.dart';
import '../MoneyGuard/category.dart';
import 'dart:io';
import 'dart:convert';
import 'package:csv/csv.dart';
import 'dart:html' as html;
import 'ImportedTransaction.dart';
import 'web_file_reader.dart' if (dart.library.html) 'stub_file_reader.dart';



class FirestoreService {
  final firestore.FirebaseFirestore _db = firestore.FirebaseFirestore.instance;

  /// Collection references
  final firestore.CollectionReference usersRef = firestore.FirebaseFirestore.instance.collection('Users');

  // =======================
  //  User Functions
  // =======================

  /// Creates a new user in Firestore.
  ///
  /// This function takes a `User` object as input and adds it to the `users` collection.
  /// It also creates the necessary subcollections for the user. This function should
  /// be called only during the user registration process.
  Future<void> createUser(User user) async {
    try {
      firestore.DocumentReference docRef = await usersRef.add(user.toMap());
      user.id = docRef.id;
      await docRef.set(user.toMap());

      // Create subcollections for the user
      await docRef.collection('Categories').add({});
      await docRef.collection('Transactions').add({});
      await docRef.collection('Subscriptions').add({});
      await docRef.collection('bankAccounts').add({});

    } catch (e) {
      print("Error creating user: $e");
    }
  }
  /// Retrieves a user from Firestore by their `userId`.
  ///
  /// This function takes a `userId` as input and retrieves the corresponding user document
  /// from the `users` collection.
  Future<User?> getUser(String userId) async {
    firestore.QuerySnapshot snapshot = await usersRef.where('userId', isEqualTo: userId).get();
    if (snapshot.docs.isNotEmpty) {
      return User.fromMap(snapshot.docs.first.data() as Map<String, dynamic>, snapshot.docs.first.id);
    }
    return null;
  }
  /// Updates an existing user in Firestore.
  ///
  /// This function takes a `User` object as input and updates the corresponding user document
  /// in the `users` collection.
  Future<void> updateUser(User user) async {
    await usersRef.doc(user.id).update(user.toMap());
  }
  /// Deletes a user from Firestore.
  ///
  /// This function takes a `userId` as input and deletes the corresponding user document
  /// from the `users` collection.
  Future<void> deleteUser(String userId) async {
    await usersRef.doc(userId).delete();
  }

  // =======================
  //  Bank Account Functions
  // =======================

  /// ==============
  /// CSV OPERATIONS
  /// ==============

  Future<List<Map<String, dynamic>>> pickAndReadCsvWeb() async {
    final html.FileUploadInputElement uploadInput = html.FileUploadInputElement();
    uploadInput.accept = '.csv';  // Ensure only CSV files can be selected
    uploadInput.click();

    final completer = Completer<List<Map<String, dynamic>>>();

    uploadInput.onChange.listen((e) {
      final files = uploadInput.files;
      if (files == null || files.isEmpty) {
        completer.complete([]);  // No file selected
        return;
      }

      final file = files[0];
      final reader = html.FileReader();

      reader.onLoadEnd.listen((e) {
        final fileContent = reader.result as String;

        // Parse the CSV content
        final rows = const CsvToListConverter().convert(fileContent);

        if (rows.isEmpty || rows.length <= 1) {
          completer.complete([]);  // No valid data in the file
          return;
        }

        // Remove the first row (headers) and process the rest of the data
        final headers = (rows.removeAt(0) as List<dynamic>).cast<String>();

        if (headers.isEmpty) {
          completer.complete([]);  // No headers found
          return;
        }

        // Map the rows into a list of transactions
        final transactions = rows.map((row) {
          final transaction = <String, dynamic>{};

          // Ensure each row matches the header length
          if (row.length == headers.length) {
            for (int i = 0; i < headers.length; i++) {
              transaction[headers[i]] = row[i];
            }
          }
          return transaction;
        }).toList();

        // Complete the process with the transactions
        completer.complete(transactions);
      });

      reader.readAsText(file);
    });

    return completer.future;
  }

// Function to convert CSV data into ImportedTransactions
  List<ImportedTransaction> convertCsvDataToImportedTransactions(
      List<Map<String, dynamic>> csvData, String userId, String accountId) {
    return csvData.map((row) {
      double outflow = 0.0;
      double inflow = 0.0;
      double amount = 0.0;

      // Safely convert outflow and inflow, ensuring they are parsed as doubles
      if (row['Ausgang'] != null) {
        outflow = double.tryParse(row['Ausgang'].toString()) ?? 0.0;
      }
      if (row['Eingang'] != null) {
        inflow = double.tryParse(row['Eingang'].toString()) ?? 0.0;
      }

      // Calculate total amount
      amount = outflow + inflow;

      // Safely parse the date (ensure it's a string and convert it)
      DateTime date = DateTime.tryParse(row['Buchungstag']?.toString() ?? '') ?? DateTime.now();

      return ImportedTransaction(
        userId: userId,
        amount: amount,
        date: date,
        payerOrRecipient: row['Auftraggeber/Empfaenger']?.toString() ?? '',
        description: row['Buchungstext']?.toString() ?? '',
        outflow: outflow,
        inflow: inflow,
        accountId: accountId, // Add selected accountId
      );
    }).toList();
  }

// Function to import CSV transactions into Firestore
  Future<int> importCsvTransactions(BuildContext context,String userId, String accountId) async {
    int importedCount = 0;
    bool dialogShown = false;

    try {
      print("Select a CSV file for import...");
      List<Map<String, dynamic>> csvData = await pickAndReadCsvWeb();

      if (csvData.isEmpty) {
        print("No data found in the CSV file.");
        return 0;
      }

      List<ImportedTransaction> transactions =
      convertCsvDataToImportedTransactions(csvData, userId, accountId);

      print("Saving transactions to Firestore...");
      FirestoreService firestoreService = FirestoreService();

      for (var transaction in transactions) {

        if (!dialogShown) {
          dialogShown = true;
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 10),
                  Text('Importiere Transaktionen...'),
                ],
              ),
            ),
          );
        }

        importedCount++;
        await firestoreService.createImportedTransaction(userId, transaction);
        print("Saved transaction: ${transaction.toMap()}");

      }

      print("All transactions imported successfully!");
    } catch (e) {
      print("Error importing transactions: $e");
    }
    return importedCount;
  }

  /// Function to create an imported transaction
  Future<void> createImportedTransaction(String userId, ImportedTransaction transaction) async {
    try {
      final userImportedTransactionsRef = usersRef.doc(userId).collection('ImportedTransactions');

      // Create imported transaction as a normal transaction for the user
      firestore.DocumentReference docRef = await userImportedTransactionsRef.add(transaction.toMap());
      transaction.id = docRef.id; // Assign the generated ID to the transaction object
      await docRef.set(transaction.toMap()); // Set the document's data

    } catch (e) {
      print("Error creating imported transaction: $e");
    }
  }

  /// Function to fetch all imported transactions
  Future<List<ImportedTransaction>> getImportedTransactions(String userId) async {
    try {
      // Access the user's ImportedTransactions sub-collection
      final userImportedTransactionsRef = usersRef.doc(userId).collection('ImportedTransactions');
      final querySnapshot = await userImportedTransactionsRef.get();

      // Parse each document into an ImportedTransaction object
      return querySnapshot.docs.map((doc) {
        return ImportedTransaction.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    } catch (e) {
      print("Error fetching imported transactions: $e");
      return [];
    }
  }





  /// ==============
  /// CSV OPERATIONS (END)
  /// ==============

  /// Creates a new bank account in Firestore for a specific user.
  ///
  /// This function takes the user's `documentId` and a `BankAccount` object as input,
  /// and adds the bank account to the user's `bankAccounts` subcollection.
  Future<void> createBankAccount(String documentId, BankAccount account) async {
    try {
      final userBankAccountsRef = usersRef.doc(documentId).collection('bankAccounts');
      firestore.DocumentReference docRef = await userBankAccountsRef.add(account.toMap());
      account.id = docRef.id;
      await docRef.set(account.toMap());
    } catch (e) {
      print("Error creating bank account: $e");
    }
  }

  /// Retrieves a bank account from Firestore by its account ID and the user's `documentId`.
  ///
  /// This function takes the user's `documentId` and the `accountId` as input,
  /// and retrieves the corresponding bank account document from the user's `bankAccounts` subcollection.
  Future<BankAccount?> getBankAccount(String documentId, String accountId) async {
    try {
      final userBankAccountsRef = usersRef.doc(documentId).collection('bankAccounts');
      firestore.DocumentSnapshot snapshot = await userBankAccountsRef.doc(accountId).get();
      if (snapshot.exists) {
        return BankAccount.fromMap(snapshot.data() as Map<String, dynamic>, snapshot.id);
      }
      return null;
    } catch (e) {
      print("Error getting bank account: $e");
      return null;
    }
  }

  /// Retrieves all bank accounts for a specific user from Firestore.
  ///
  /// This function takes the user's `documentId` as input and retrieves all bank account documents
  /// from the user's `bankAccounts` subcollection.
  Future<List<BankAccount>> getUserBankAccounts(String documentId) async {
    try {
      final userBankAccountsRef = usersRef.doc(documentId).collection('bankAccounts');
      firestore.QuerySnapshot snapshot = await userBankAccountsRef.get();
      print("Abgerufene Konten: ${snapshot.docs.length}");
      return snapshot.docs.map((doc) => BankAccount.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
    } catch (e) {
      print("Error getting user bank accounts: $e");
      return [];
    }
  }

  /// TEST PHASE! More error handling!
  Future<List<BankAccount>> getUserBankAccounts2(String documentId) async {
    try {
      final userBankAccountsRef = usersRef.doc(documentId).collection('bankAccounts');
      firestore.QuerySnapshot snapshot = await userBankAccountsRef.get();

      return snapshot.docs.map((doc) {
        try {
          // Attempt to map the document to a BankAccount object
          return BankAccount.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        } catch (e) {
          print("Error mapping document ${doc.id}: $e");
          return null; // Skip invalid documents
        }
      }).whereType<BankAccount>().toList(); // Filter out null entries
    } catch (e) {
      print("Error getting user bank accounts: $e");
      return [];
    }
  }

  /// Updates an existing bank account in Firestore for a specific user.
  ///
  /// This function takes the user's `documentId` and a `BankAccount` object as input,
  /// and updates the corresponding bank account document in the user's `bankAccounts` subcollection.
  /*
  Future<void> updateBankAccount(String documentId, BankAccount account) async {
    try {
      final userBankAccountsRef = usersRef.doc(documentId).collection('bankAccounts');
      await userBankAccountsRef.doc(account.id).update(account.toMap());
    } catch (e) {
      print("Error updating bank account: $e");
    }
  }*/

  Future<void> updateBankAccount(String userId, BankAccount account) async {
    try {
      final userBankAccountsRef = usersRef.doc(userId).collection('bankAccounts');
      if (account.id != null) {
        await userBankAccountsRef.doc(account.id).update(account.toMap());
      } else {
        throw Exception("Account ID is null. Cannot update.");
      }
    } catch (e) {
      print("Error updating bank account: $e");
    }
  }


  /// Deletes a bank account from Firestore for a specific user.
  ///
  /// This function takes the user's `documentId` and the `accountId` as input,
  /// and deletes the corresponding bank account document from the user's `bankAccounts` subcollection.
  Future<void> deleteBankAccount(String documentId, String accountId) async {
    try {
      final userBankAccountsRef = usersRef.doc(documentId).collection('bankAccounts');
      await userBankAccountsRef.doc(accountId).delete();
    } catch (e) {
      print("Error deleting bank account: $e");
    }
  }

  // =======================
  //  Category Functions
  // =======================



  /// Creates a new category in Firestore for a specific user.
  ///
  /// This function takes the user's `documentId` and a `Category` object as input,
  /// adds the category to the user's `Categories` subcollection, and returns the
  /// document ID of the newly created category.

  Future<String> createCategory(String documentId, Category category) async {
    try {
      final userCategoriesRef = usersRef.doc(documentId).collection('Categories');

      // Überprüfen, ob eine Kategorie mit demselben Namen existiert
      final querySnapshot = await userCategoriesRef
          .where('name', isEqualTo: category.name)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // Wenn eine Kategorie mit demselben Namen gefunden wird, abbrechen
        throw Exception("Eine Kategorie mit diesem Namen existiert bereits.");
      }
      // Create the category and get its reference
      firestore.DocumentReference docRef = await userCategoriesRef.add(category.toMap());
      category.id = docRef.id;
      category.isDefault = false;

      // Update the document to ensure the `id` field is saved
      await docRef.set(category.toMap());
      return docRef.id; // Return the document ID
    } catch (e) {
      print("Error creating category: $e");
      rethrow; // Rethrow to propagate the error
    }
  }




  /// Retrieves a list of default categories from Firestore.
  ///
  /// This function retrieves all category documents with the field `isDefault` set to `true`
  /// from all `Categories` subcollections across all users.
/*
  Future<List<Category>> getDefaultCategories() async {
    firestore.QuerySnapshot snapshot = await _db.collectionGroup('Categories').where('isDefault', isEqualTo: true).get();
    return snapshot.docs.map((doc) => Category.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
  }*/




  /// Retrieves a specific category for a user from Firestore.
  ///
  /// This function takes the user's `documentId` and the `categoryId` as input,
  /// and retrieves the corresponding category document from the user's `Categories` subcollection.

  Future<Category?> getCategory(String documentId, String categoryId) async {
    try {
      final userCategoriesRef = usersRef.doc(documentId).collection('Categories');
      final docSnapshot = await userCategoriesRef.doc(categoryId).get();

      if (docSnapshot.exists) {
        return Category.fromMap(docSnapshot.data() as Map<String, dynamic>, docSnapshot.id);
      } else {
        return null;
      }
    } catch (e) {
      print("Error getting category: $e");
      return null;
    }
  }

  /// Retrieves all categories for a specific user from Firestore.
  ///
  /// This function takes the user's `documentId` as input and retrieves all category documents
  /// from the user's `Categories` subcollection.

  Future<List<Category>> getUserCategories(String documentId) async {
    try {
      final userCategoriesRef = usersRef.doc(documentId).collection('Categories');
      firestore.QuerySnapshot snapshot = await userCategoriesRef.get();
      return snapshot.docs.map((doc) {
        try {
          return Category.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        } catch (e) {
          print("Error parsing category: $e");
          return null; // Handle gracefully
        }
      }).whereType<Category>().toList(); // Remove nulls from the list
    } catch (e) {
      print("Error getting user categories: $e");
      return [];
    }
  }

  /// Updates an existing category in Firestore for a specific user.
  ///
  /// This function takes the user's `documentId` and a `Category` object as input,
  /// and updates the corresponding category document in the user's `Categories` subcollection.

  Future<void> updateCategory(String documentId, Category category) async {
    try {
      final userCategoriesRef = usersRef.doc(documentId).collection('Categories');
      await userCategoriesRef.doc(category.id).update(category.toMap());
    } catch (e) {
      print("Error updating category: $e");
    }
  }


  Future<void> createDefaultCategories(String userId) async {
    final List<Map<String, dynamic>> defaultCategories = [
      {'name': 'Einnahmen', 'icon': Icons.attach_money, 'color': Colors.green, 'budgetLimit': 0.0},
      {'name': 'Unterhaltung', 'icon': Icons.movie, 'color': Colors.blue, 'budgetLimit': 0.0},
      {'name': 'Lebensmittel', 'icon': Icons.restaurant, 'color': Colors.orange, 'budgetLimit': 0.0},
      {'name': 'Haushalt', 'icon': Icons.home, 'color': Colors.teal, 'budgetLimit': 0.0},
      {'name': 'Wohnen', 'icon': Icons.apartment, 'color': Colors.indigo, 'budgetLimit': 0.0},
      {'name': 'Transport', 'icon': Icons.directions_car, 'color': Colors.purple, 'budgetLimit': 0.0},
      {'name': 'Kleidung', 'icon': Icons.shopping_bag, 'color': Colors.pink, 'budgetLimit': 0.0},
      {'name': 'Bildung', 'icon': Icons.school, 'color': Colors.amber, 'budgetLimit': 0.0},
      {'name': 'Finanzen', 'icon': Icons.account_balance, 'color': Colors.lightGreen, 'budgetLimit': 0.0},
      {'name': 'Gesundheit', 'icon': Icons.health_and_safety, 'color': Colors.red, 'budgetLimit': 0.0},
    ];
    try {
      final userCategoriesRef = usersRef.doc(userId).collection('Categories');

      for (final categoryData in defaultCategories) {
        Category category = Category(
          userId: userId,
          name: categoryData['name'],
          budgetLimit: categoryData['budgetLimit'],
          icon: categoryData['icon'],
          color: categoryData['color'],
          isDefault: true, // Kennzeichnet, dass es sich um eine Default-Kategorie handelt
        );

        // Überprüfen, ob die Kategorie schon existiert
        final query = await userCategoriesRef
            .where('name', isEqualTo: category.name)
            .where('isDefault', isEqualTo: true)
            .get();

        if (query.docs.isEmpty) {
          await userCategoriesRef.add(category.toMap());
        }
      }
    } catch (e) {
      print("Fehler beim Erstellen der Standardkategorien: $e");
    }
  }
/*
  Future<void> createDefaultCategoriesForAllAccounts(String userId) async {
    final List<Map<String, dynamic>> defaultCategories = [
      {'name': 'Einnahmen', 'icon': Icons.attach_money, 'color': Colors.green, 'budgetLimit': 0.0},
      {'name': 'Unterhaltung', 'icon': Icons.movie, 'color': Colors.blue, 'budgetLimit': 0.0},
      {'name': 'Lebensmittel', 'icon': Icons.restaurant, 'color': Colors.orange, 'budgetLimit': 0.0},
      {'name': 'Haushalt', 'icon': Icons.home, 'color': Colors.teal, 'budgetLimit': 0.0},
      {'name': 'Wohnen', 'icon': Icons.apartment, 'color': Colors.indigo, 'budgetLimit': 0.0},
      {'name': 'Transport', 'icon': Icons.directions_car, 'color': Colors.purple, 'budgetLimit': 0.0},
      {'name': 'Kleidung', 'icon': Icons.shopping_bag, 'color': Colors.pink, 'budgetLimit': 0.0},
      {'name': 'Bildung', 'icon': Icons.school, 'color': Colors.amber, 'budgetLimit': 0.0},
      {'name': 'Finanzen', 'icon': Icons.account_balance, 'color': Colors.lightGreen, 'budgetLimit': 0.0},
      {'name': 'Gesundheit', 'icon': Icons.health_and_safety, 'color': Colors.red, 'budgetLimit': 0.0},
    ];

    try {
      // Alle Bankkonten des Benutzers abrufen
      final userBankAccountsRef = usersRef
          .doc(userId)
          .collection('bankAccounts');
      final bankAccountsSnapshot = await userBankAccountsRef.get();

      // Durch jedes Bankkonto des Benutzers iterieren
      for (var accountDoc in bankAccountsSnapshot.docs) {
        String accountId = accountDoc.id;  // Konto-ID des aktuellen Bankkontos

        // Alle Standardkategorien für das Bankkonto erstellen
        for (final categoryData in defaultCategories) {
          Category category = Category(
            userId: userId,
            name: categoryData['name'],
            budgetLimit: categoryData['budgetLimit'],
            icon: categoryData['icon'],
            color: categoryData['color'],
            isDefault: true, // Kennzeichnet, dass es sich um eine Default-Kategorie handelt
          );

          // Überprüfen und Erstellen der Kategorie für jedes Konto
          await createCategoryForAccount(userId, accountId, category);
        }
      }
    } catch (e) {
      print("Fehler beim Erstellen der Standardkategorien für alle Bankkonten: $e");
    }
  }

// Methode zum Erstellen einer einzelnen Kategorie für alle Bankkonten eines Benutzers
  Future<void> createCategoryForAllAccounts(String userId, Category category) async {
    try {
      // Alle Bankkonten des Benutzers abrufen
      final userBankAccountsRef = usersRef
          .doc(userId)
          .collection('bankAccounts');
      final bankAccountsSnapshot = await userBankAccountsRef.get();

      // Durch jedes Bankkonto des Benutzers iterieren und die Kategorie für jedes Konto hinzufügen
      for (var accountDoc in bankAccountsSnapshot.docs) {
        String accountId = accountDoc.id;  // Konto-ID des aktuellen Bankkontos

        // Überprüfen, ob die Kategorie schon existiert
        final userCategoriesRef = usersRef
            .doc(userId)
            .collection('bankAccounts')
            .doc(accountId)
            .collection('Categories');

        final query = await userCategoriesRef
            .where('name', isEqualTo: category.name)
            .where('isDefault', isEqualTo: true)
            .get();

        // Wenn die Kategorie nicht existiert, wird sie hinzugefügt
        if (query.docs.isEmpty) {
          final docRef = await userCategoriesRef.add(category.toMap());
          await docRef.update({'id': docRef.id});
          print("Kategorie '${category.name}' für Konto $accountId wurde erstellt.");
        }
      }
    } catch (e) {
      print("Fehler beim Erstellen der Kategorie '${category.name}' für alle Bankkonten: $e");
    }
  }

  Future<void> createCategoryForAccount(String userId, String accountId, Category category) async {
    try {
      final userCategoriesRef = usersRef
          .doc(userId)
          .collection('bankAccounts')
          .doc(accountId)
          .collection('Categories');

      // Überprüfen, ob die Kategorie schon existiert
      final query = await userCategoriesRef
          .where('name', isEqualTo: category.name)
          .where('isDefault', isEqualTo: true)
          .get();

      // Wenn die Kategorie nicht existiert, wird sie hinzugefügt
      if (query.docs.isEmpty) {
        final docRef = await userCategoriesRef.add(category.toMap());
        await docRef.update({'id': docRef.id});
        print("Kategorie '${category.name}' für Konto $accountId wurde erstellt.");
      }
    } catch (e) {
      print("Fehler beim Erstellen der Kategorie '${category.name}' für Konto $accountId: $e");
    }
  }*/


  //sortiert default nach oben und userdefined nach unten
  Future<List<Category>> getSortedUserCategories(String documentId) async {
    try {
      final userCategoriesRef = usersRef.doc(documentId).collection('Categories');
      firestore.QuerySnapshot snapshot = await userCategoriesRef.get();

      // Kategorien auslesen und sortieren
      final categories = snapshot.docs.map((doc) {
        try {
          return Category.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        } catch (e) {
          print("Error parsing category: $e");
          return null; // Handle gracefully
        }
      }).whereType<Category>().toList();

      // Default-Kategorien zuerst sortieren
      categories.sort((a, b) {
        if (a.isDefault && !b.isDefault) return -1; // Default vor benutzerdefiniert
        if (!a.isDefault && b.isDefault) return 1;
        return 0; // Wenn beide gleich sind, Reihenfolge beibehalten
      });

      return categories;
    } catch (e) {
      print("Error getting user categories: $e");
      return [];
    }
  }

  /*
  Future<List<Category>> getSortedUserCategoriesV2(String documentId, String accountId) async {
    try {
      final userCategoriesRef = usersRef
          .doc(documentId)
          .collection('bankAccounts')
          .doc(accountId)
          .collection('Categories');

      firestore.QuerySnapshot snapshot = await userCategoriesRef.get();

      // Kategorien auslesen und sortieren
      final categories = snapshot.docs.map((doc) {
        try {
          return Category.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        } catch (e) {
          print("Error parsing category: $e");
          return null; // Handle gracefully
        }
      }).whereType<Category>().toList();

      // Default-Kategorien zuerst sortieren
      categories.sort((a, b) {
        if (a.isDefault && !b.isDefault) return -1; // Default vor benutzerdefiniert
        if (!a.isDefault && b.isDefault) return 1;
        return 0; // Wenn beide gleich sind, Reihenfolge beibehalten
      });

      return categories;
    } catch (e) {
      print("Error getting user categories for account $accountId: $e");
      return [];
    }
  }*/

  Future<List<Category>> getSortedUserCategoriesV3(String userId) async {
    try {
      // Referenz auf die bankAccounts Collection des Nutzers
      final bankAccountsRef = usersRef.doc(userId).collection('bankAccounts');

      // Abrufen des ersten Bankkontos des Nutzers
      final bankAccountsSnapshot = await bankAccountsRef.limit(1).get();

      // Wenn kein Bankkonto vorhanden ist
      if (bankAccountsSnapshot.docs.isEmpty) {
        print("Kein Bankkonto gefunden.");
        return [];
      }

      // Holen der accountId des ersten Bankkontos
      String accountId = bankAccountsSnapshot.docs.first.id;

      // Referenz auf die Kategorien dieses Bankkontos
      final userCategoriesRef = bankAccountsRef
          .doc(accountId)
          .collection('Categories');

      // Abrufen der Kategorien des ersten Bankkontos
      firestore.QuerySnapshot snapshot = await userCategoriesRef.get();

      // Kategorien auslesen und sortieren
      final categories = snapshot.docs.map((doc) {
        try {
          return Category.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        } catch (e) {
          print("Error parsing category: $e");
          return null; // Handle gracefully
        }
      }).whereType<Category>().toList();

      // Default-Kategorien zuerst sortieren
      categories.sort((a, b) {
        if (a.isDefault && !b.isDefault) return -1; // Default vor benutzerdefiniert
        if (!a.isDefault && b.isDefault) return 1;
        return 0; // Wenn beide gleich sind, Reihenfolge beibehalten
      });

      return categories;
    } catch (e) {
      print("Error getting user categories: $e");
      return [];
    }
  }


  Future<List<Category>> getDefaultCategories(String userId) async {
    try {
      final userCategoriesRef = usersRef.doc(userId).collection('Categories');
      final querySnapshot = await userCategoriesRef.where('isDefault', isEqualTo: true).get();

      return querySnapshot.docs.map((doc) {
        return Category.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    } catch (e) {
      print("Error getting default categories: $e");
      return [];
    }
  }



/*
  Future<void> updateCategoryBudgetLimit(String userId, String categoryId, double newLimit) async {
    // Hole die Kategorie
    Category? category = await getCategory(userId, categoryId);

    if (category != null) {
      // Aktualisiere das Budgetlimit
      category.budgetLimit = newLimit;
      await updateCategory(userId, category);
    } else {
      print("Kategorie nicht gefunden.");
    }
  }*/
  Future<void> updateCategoryBudgetLimit(String userId, String categoryId, double budgetLimit) async {
    try {
      final userCategoriesRef = usersRef.doc(userId).collection('Categories');
      await userCategoriesRef.doc(categoryId).update({'budgetLimit': budgetLimit.toString()});
    } catch (e) {
      print("Fehler beim Aktualisieren des Budgetlimits: $e");
    }
  }
  /// Deletes a category from Firestore for a specific user.
  ///
  /// This function takes the user's `documentId` and the `categoryId` as input,
  /// and deletes the corresponding category document from the user's `Categories` subcollection.
  /// It also deletes all transactions associated with the category.
  Future<void> deleteCategory(String documentId, String categoryId) async {
    try {
      // 1. Delete transactions belonging to the category (within the user's scope)
      final userTransactionsRef = usersRef.doc(documentId).collection('Transactions');
      final transactionsQuery = await userTransactionsRef.where('categoryId', isEqualTo: categoryId).get();
      for (var doc in transactionsQuery.docs) {
        await doc.reference.delete();
      }

      // 2. Delete the category
      final userCategoriesRef = usersRef.doc(documentId).collection('Categories');
      await userCategoriesRef.doc(categoryId).delete();
    } catch (e) {
      print("Error deleting category: $e");
    }
  }



  // =======================
  //  Transaction Functions
  // =======================



  /* meins
  Future<void> createTransactionV23(String documentId, String accountId, Transaction transaction, {String? categoryId}) async {
    try {
      final accountRef = usersRef
          .doc(documentId)
          .collection('bankAccounts')
          .doc(accountId);

      // Kategorie-Daten laden und verknüpfen

      if (categoryId != null) {
        final category = await getCategory(documentId, categoryId);
        if (category == null) {
          print("Kategorie konnte mit ID $categoryId nicht geladen werden.");
        } else {
          print("Geladene Kategorie: ${category.name}");
          transaction.categoryData = category;
        }
      }

      // Print detailed information about the transaction before adding it
      print('Transaktionsdetails:');
      print('UserID: ${transaction.userId}');
      print('Betrag: ${transaction.amount}');
      print('Datum: ${transaction.date.toIso8601String()}');
      print('KategorieID: ${transaction.categoryId}');
      if (transaction.categoryData != null) {
        print('Kategoriename: ${transaction.categoryData!.name}');
      } else {
        print('Kategoriename: Keine Kategorie verknüpft.');
      }
      print('Typ: ${transaction.type}');
      print('Wichtigkeit: ${transaction.importance}');
      print('Notiz: ${transaction.note}');
      print('KontoID: ${transaction.accountId}');
      print('Map-Daten: ${transaction.toMap()}');

      if (categoryId != null) {
        final categoryTransactionsRef = accountRef
            .collection('Categories')
            .doc(categoryId)
            .collection('Transactions');
        firestore.DocumentReference docRef = await categoryTransactionsRef.add(transaction.toMap());
        transaction.id = docRef.id;
        await docRef.set(transaction.toMap());
      } else {
        final transactionsRef = accountRef.collection('Transactions');
        firestore.DocumentReference docRef = await transactionsRef.add(transaction.toMap());
        transaction.id = docRef.id;
        await docRef.set(transaction.toMap());
      }
      print("Transaktion erfolgreich erstellt.");
    } catch (e) {
      print("Fehler beim Erstellen der Transaktion: $e");
    }
  }*/


  /// Creates a new transaction in Firestore for a specific user.
  ///
  /// This function takes the user's `documentId`, a `Transaction` object, and an optional `categoryId` as input.
  /// If `categoryId` is provided, the transaction is added as a subcollection of the specified category.
  /// Otherwise, the transaction is added as a normal transaction to the user's `Transactions` subcollection.
  Future<void> createTransaction(String documentId, Transaction transaction, {String? categoryId}) async {
    try {
      final userTransactionsRef = usersRef.doc(documentId).collection('Transactions');

      if (categoryId != null) {
        // Ensure categoryId is valid and exists (optional, based on your needs)
        final categoryRef = userTransactionsRef.doc(categoryId);
        final categorySnapshot = await categoryRef.get();
        if (!categorySnapshot.exists) {
          throw Exception('Category not found!');
        }

        // Create transaction as a subcollection under the category
        final categoryTransactionsRef = categoryRef.collection('Transactions');
        firestore.DocumentReference docRef = await categoryTransactionsRef.add(transaction.toMap());
        transaction.id = docRef.id;
        await docRef.set(transaction.toMap());
      } else {
        // Create transaction as a normal transaction for the user
        firestore.DocumentReference docRef = await userTransactionsRef.add(transaction.toMap());
        transaction.id = docRef.id;
        await docRef.set(transaction.toMap());
      }
    } catch (e) {
      print("Error creating transaction: $e");
    }
  }

  Future<void> createTransaction2( String documentId, Transaction transaction,
      {String? categoryId, String? accountId}) async {
    try {
      final userTransactionsRef = usersRef.doc(documentId).collection('Transactions');

      if (categoryId != null) {
        final categoryRef = usersRef
            .doc(documentId)
            .collection('Categories')
            .doc(categoryId);
        final categorySnapshot = await categoryRef.get();
        if (!categorySnapshot.exists) {
          throw Exception('Category not found!');
        }
        transaction.categoryId = categoryId;
      }

      // Validate accountId if provided
      if (accountId != null) {
        final accountRef = usersRef
            .doc(documentId)
            .collection('bankAccounts')
            .doc(accountId);
        final accountSnapshot = await accountRef.get();
        if (!accountSnapshot.exists) {
          throw Exception('Account not found!');
        }
        transaction.accountId = accountId;
      }

      // Create the transaction
      firestore.DocumentReference docRef = await userTransactionsRef.add(transaction.toMap());
      transaction.id = docRef.id;
      await docRef.set(transaction.toMap());
    } catch (e) {
      print("Error creating transaction: $e");
    }
  }


  ///TEST
  ///update: Test successfully done. This function does exactly what it's named.
  Future<void> createTransactionUnderCategory(String userId, Transaction transaction, String categoryId) async {
    try {
      final categoryTransactionsRef = usersRef
          .doc(userId)
          .collection('Categories')
          .doc(categoryId)
          .collection('Transactions');

      firestore.DocumentReference docRef = await categoryTransactionsRef.add(transaction.toMap());
      transaction.id = docRef.id;
      await docRef.set(transaction.toMap());
    } catch (e) {
      print("Error creating transaction under category: $e");
    }
  }

  Future<List<Transaction>> getFilteredTransactions(
      String documentId, {
        List<String>? categoryIds,
        List<String>? accountIds,
        int? month,
        int? year,
      }) async {
    try {
      List<Transaction> filteredTransactions = [];
      final transactionsRef = usersRef.doc(documentId).collection('Transactions');

      // Fetch all transactions first
      final snapshot = await transactionsRef.get();
      List<Transaction> allTransactions = snapshot.docs.map((doc) => Transaction.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();

      // Apply filters
      if (categoryIds != null) {
        allTransactions = allTransactions.where((transaction) => categoryIds.contains(transaction.categoryId)).toList();
      }

      if (accountIds != null) {
        allTransactions = allTransactions.where((transaction) => accountIds.contains(transaction.accountId)).toList();
      }

      if (month != null && year != null) {
        allTransactions = allTransactions.where((transaction) {
          final transactionDate = transaction.date;
          return transactionDate.month == month && transactionDate.year == year;
        }).toList();
      }

      filteredTransactions = allTransactions;

      return filteredTransactions;
    } catch (e) {
      print("Error fetching filtered transactions: $e");
      return [];
    }
  }

  Future<List<Transaction>> getUserTransactions(String documentId) async {
    try {
      final userTransactionsRef = usersRef.doc(documentId).collection('Transactions');
      firestore.QuerySnapshot snapshot = await userTransactionsRef
          .orderBy('date', descending: true)
          .get();
      return snapshot.docs.map((doc) => Transaction.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
    } catch (e) {
      print("Error getting user transactions: $e");
      return [];
    }
  }

  Future<List<Transaction>> getTransactionsByAccountIds(String documentId, List<String> accountIds) async {
    try {
      final userTransactionsRef = usersRef.doc(documentId).collection('Transactions');
      firestore.QuerySnapshot snapshot = await userTransactionsRef
          .where('accountId', whereIn: accountIds)
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs.map((doc) => Transaction.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
    } catch (e) {
      print("Error getting transactions for accountIds: $e");
      return [];
    }
  }



  Future<List<ImportedTransaction>> getImportedTransactionsByAccountIds(String documentId, List<String> accountIds) async {
    try {
      final userTransactionsRef = usersRef.doc(documentId).collection('ImportedTransactions');
      firestore.QuerySnapshot snapshot = await userTransactionsRef
          .where('accountId', whereIn: accountIds)
          //.orderBy('date', descending: true)
          .get();

      // Hier sollte `ImportedTransaction.fromMap` verwendet werden
      return snapshot.docs.map((doc) => ImportedTransaction.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
    } catch (e) {
      print("Error getting imported transactions for accountIds: $e");
      return [];
    }
  }


  Future<List<Transaction>> getUserTransactionsByMonth(String documentId, int year, int month) async {
    try {
      final userTransactionsRef = usersRef.doc(documentId).collection('Transactions');

      final startOfMonth = DateTime(year, month, 1);
      final endOfMonth = DateTime(year, month + 1, 1).subtract(const Duration(days: 1));

      firestore.QuerySnapshot snapshot = await userTransactionsRef
          .where('date', isGreaterThanOrEqualTo: startOfMonth.toIso8601String()) // Compare as strings
          .where('date', isLessThanOrEqualTo: endOfMonth.toIso8601String()) // Compare as strings
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs.map((doc) => Transaction.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
    } catch (e) {
      print("Error getting user transactions by month: $e");
      return [];
    }
  }


  Future<List<Transaction>> getTransactionsByAccountIdsAndMonth(
      String documentId, List<String> accountIds, int year, int month) async {
    try {
      final userTransactionsRef = usersRef.doc(documentId).collection('Transactions');

      final startOfMonth = DateTime(year, month, 1);
      final endOfMonth = DateTime(year, month + 1, 1).subtract(const Duration(days: 1));

      firestore.QuerySnapshot snapshot = await userTransactionsRef
          .where('accountId', whereIn: accountIds)
          .where('date', isGreaterThanOrEqualTo: startOfMonth.toIso8601String()) // Compare as strings
          .where('date', isLessThanOrEqualTo: endOfMonth.toIso8601String()) // Compare as strings
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs.map((doc) => Transaction.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
    } catch (e) {
      print("Error getting transactions by accountIds and month: $e");
      return [];
    }
  }


  ///TEST
  Future<List<Transaction>> getCategoryTransactions(String userId, String categoryId) async {
    try {
      final categoryTransactionsRef = usersRef.doc(userId).collection('Categories').doc(categoryId).collection('Transactions');
      final snapshot = await categoryTransactionsRef.get();

      // Map each document to a Transaction object, passing the document ID
      return snapshot.docs.map((doc) {
        return Transaction.fromMap(doc.data(), doc.id); // Pass doc.id as documentId
      }).toList();
    } catch (e) {
      print("Error retrieving transactions for category: $e");
      return [];
    }
  }

  ///TEST

  /// Retrieves a transaction from Firestore by its transaction ID and the user's `documentId`.
  ///
  /// This function takes the user's `documentId` and the `transactionId` as input,
  /// and retrieves the corresponding transaction document from the user's `Transactions` subcollection.
  Future<Transaction?> getTransaction(String documentId, String transactionId, String? accountId) async {
    try {
      final userTransactionsRef = usersRef.doc(documentId).collection('Transactions');
      final docSnapshot = await userTransactionsRef.doc(transactionId).get();

      if (docSnapshot.exists) {
        return Transaction.fromMap(docSnapshot.data() as Map<String, dynamic>, docSnapshot.id);
      } else {
        return null;
      }
    } catch (e) {
      print("Error getting transaction: $e");
      return null;
    }
  }



  /// Retrieves all transactions for a specific user and category, ordered by date (latest first).
  ///
  /// This function takes the user's `documentId` and a `categoryId` as input,
  /// and retrieves all transaction documents from the user's `Transactions` subcollection that belong
  /// to the specified category. The results are ordered by date with the latest transaction appearing first.
  Future<List<Transaction>> getTransactionsByCategory(String documentId, String categoryId) async {
    try {
      final userTransactionsRef = usersRef.doc(documentId).collection('Transactions');
      firestore.QuerySnapshot snapshot = await userTransactionsRef
          .where('categoryId', isEqualTo: categoryId)
          .orderBy('date', descending: true)
          .get();
      return snapshot.docs.map((doc) => Transaction.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
    } catch (e) {
      print("Error getting transactions by category: $e");
      return [];
    }
  }

  /// Updates an existing transaction in Firestore for a specific user.
  ///
  /// This function takes the user's `documentId` and a `Transaction` object as input,
  /// and updates the corresponding transaction document in the user's `Transactions` subcollection.
  Future<void> updateTransaction(
      String userId, String transactionId, Transaction transaction) async {
    try {
      final userTransactionsRef = usersRef
          .doc(userId) // Benutzer-ID
          .collection('Transactions')
          .doc(transactionId); // Transaktions-ID
      final docSnapshot = await userTransactionsRef.get();

      // Überprüfen, ob das Dokument existiert
      if (!docSnapshot.exists) {
        print("Transaction not found for userId: $userId, transactionId: $transactionId");
        return;
      }

      await userTransactionsRef.update(transaction.toMap());
      print("Transaction successfully updated!");
    } catch (e) {
      print("Error updating transaction: $e");
    }
  }

  Future<void> updateImportedTransaction(String userId, String transactionId, ImportedTransaction transaction) async {
    try {
      final userImportedTransactionsRef = usersRef
          .doc(userId) // Benutzer-ID
          .collection('ImportedTransactions') // Changed to 'ImportedTransactions'
          .doc(transactionId); // Transaktions-ID
      final docSnapshot = await userImportedTransactionsRef.get();

      // Überprüfen, ob das Dokument existiert
      if (!docSnapshot.exists) {
        print("Imported transaction not found for userId: $userId, transactionId: $transactionId");
        return;
      }

      await userImportedTransactionsRef.update(transaction.toMap());
      print("Imported transaction successfully updated!");
    } catch (e) {
      print("Error updating imported transaction: $e");
    }
  }


  /// Deletes a transaction from Firestore for a specific user.
  ///
  /// This function takes the user's `documentId` and the `transactionId` as input,
  /// and deletes the corresponding transaction document from the user's `Transactions` subcollection.
  Future<void> deleteTransaction(String documentId, String transactionId) async {
    try {
      final userTransactionsRef = usersRef.doc(documentId).collection('Transactions');
      await userTransactionsRef.doc(transactionId).delete();
    } catch (e) {
      print("Error deleting transaction: $e");
    }
  }

  Future<void> deleteImportedTransaction(String documentId, String transactionId) async {
    try {
      final userTransactionsRef = usersRef.doc(documentId).collection('ImportedTransactions');
      await userTransactionsRef.doc(transactionId).delete();
    } catch (e) {
      print("Error deleting transaction: $e");
    }
  }


  Future<double> calculateBankAccountBalance(String documentId, BankAccount bankAccount) async {
    try {
      // Starten mit dem aktuellen Kontostand im Bankkonto
      double totalBalance = bankAccount.balance ?? 0.0;

      // Abrufen aller Transaktionen für das spezifische Konto
      List<Transaction> transactions = await FirestoreService()
          .getTransactionsByAccountIds(documentId, [bankAccount.id!]);

      // Berechnung des Gesamtguthabens basierend auf den Transaktionen
      for (var transaction in transactions) {
        // Einnahmen addieren
        if (transaction.type == 'Einnahme') {
          totalBalance += transaction.amount;
        }
        // Ausgaben subtrahieren
        else if (transaction.type == 'Ausgabe') {
          totalBalance -= transaction.amount;
        }
      }

      print('balance ${bankAccount.balance}');

      // Optional: Aktualisiere den Kontostand im BankAccount-Objekt
      bankAccount.balance = totalBalance;
      bankAccount.lastUpdated = DateTime.now();

      return totalBalance;
    } catch (e) {
      print("Error calculating balance for bank account: $e");
      return bankAccount.balance ?? 0.0;
    }
  }

  Future<double> calculateImportBankAccountBalance(String documentId, BankAccount bankAccount) async {
    try {
      // Starten mit dem aktuellen Kontostand im Bankkonto
      double totalBalance = bankAccount.balance ?? 0.0;

      // Abrufen aller Transaktionen für das spezifische Konto
      List<ImportedTransaction> transactions = await FirestoreService()
          .getImportedTransactionsByAccountIds(documentId, [bankAccount.id!]);

      // Berechnung des Gesamtguthabens basierend auf den Transaktionen
      for (var transaction in transactions) {
        // Einnahmen addieren (inflow)
        if (transaction.inflow > 0) {
          totalBalance += transaction.inflow;
        }
        // Ausgaben subtrahieren (outflow)
        if (transaction.outflow > 0) {
          totalBalance -= transaction.outflow;
        }
      }

      print('balance ${bankAccount.balance}');

      // Optional: Aktualisiere den Kontostand im BankAccount-Objekt
      bankAccount.balance = totalBalance;
      bankAccount.lastUpdated = DateTime.now();

      return totalBalance;
    } catch (e) {
      print("Error calculating balance for bank account: $e");
      return bankAccount.balance ?? 0.0;
    }
  }



  // =======================
  //  Summary and Utility Functions
  // =======================


  /// Calculates the total balance for a specific user based on their transactions.
  ///
  /// This function takes the user's `documentId` as input and calculates the sum of all
  /// transaction amounts for that user.
  Future<double> calculateTotalBalance(String documentId) async {
    List<Transaction> transactions = await getUserTransactions(documentId);
    double totalBalance = 0.0;
    for (var transaction in transactions) {
      totalBalance += transaction.amount;
    }
    return totalBalance;
  }


  /// Calculates the total spending for a specific user and category.
  ///
  /// This function takes the user's `documentId` and a `categoryId` as input,
  /// and calculates the sum of all expense amounts for that user within the specified category.
  Future<double> calculateCategorySpending(String documentId, String categoryId) async {
    List<Transaction> categoryTransactions = await getTransactionsByCategory(documentId, categoryId);
    double totalSpending = 0.0;
    for (var transaction in categoryTransactions) {
      if (transaction.amount < 0) {
        totalSpending += transaction.amount;
      }
    }
    return totalSpending;
  }

  /// Gets transactions within a specific date range for a specific user.
  ///
  /// This function takes the user's `documentId`, a `startDate`, and an `endDate` as input,
  /// and retrieves all transaction documents from the user's `Transactions` subcollection that fall
  /// within the given date range.
  Future<List<Transaction>> getSpecificTransactionByDateRange(String documentId, String type, DateTime startDate, DateTime endDate, String accountid) async {
    try {
      // Setze startDate auf Mitternacht (00:00:00) und endDate auf den letzten Moment des Tages (23:59:59)
      startDate = DateTime.utc(startDate.year, startDate.month, startDate.day, 0, 0, 0).subtract(Duration(microseconds: 1)); // Setze die Zeit auf 00:00
      endDate = DateTime.utc(endDate.year, endDate.month, endDate.day, 23, 59, 59); // Setze die Zeit auf 23:59
      //print("STARTDATE: $startDate UND ENDDATE: $endDate");
      final userTransactionsRef = usersRef.doc(documentId).collection('Transactions');

      // Basiskonfiguration der Abfrage
      firestore.Query query = userTransactionsRef
          .where('date', isGreaterThanOrEqualTo: startDate.toIso8601String())
          .where('date', isLessThanOrEqualTo: endDate.toIso8601String())
          .orderBy('date', descending: true);

      // Abfrage ausführen
      firestore.QuerySnapshot snapshot = await query.get();

      // Ergebnisse in eine Liste von Transaktionen umwandeln
      List<Transaction> transactions = snapshot.docs.map((doc) => Transaction.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();

      // Falls ein Konto spezifiziert wurde, filtere nach diesem
      if (accountid != "null" && accountid.isNotEmpty) {
        transactions = transactions.where((transaction) => transaction.accountId == accountid).toList();
      }
      //print(transactions);
      return transactions;
    } catch (e) {
      print("Error getting transactions by date range: $e");
      return [];
    }
  }





  /// Calculates monthly spending for a given user.
  ///
  /// This function takes the user's `documentId` and a `year` as input,
  /// and calculates the total spending for each month of the given year.



  Future<List<Map<String, double>>> calculateYearlySpendingByMonth2(String documentId, String chosenYear, String accountid) async {
    print("Entered calculateYearlySpendingByMonth2");

    // Erstelle Maps zur Speicherung der Ergebnisse
    Map<String, double> incomeMap = {};
    Map<String, double> expenseMap = {};
    Map<String, double> netMap = {};

    // Kumulatives Netto
    double cumulativeNetAmount = 0.0;

    // Liste für parallele Futures
    List<Future<Map<String, dynamic>>> futures = [];

    // Erstelle Futures für alle Monate
    for (int month = 1; month <= 12; month++) {
      futures.add(Future(() async {
        // Setze Start- und Enddatum für den Monat
        DateTime startDate = DateTime.utc(int.parse(chosenYear), month, 1);
        DateTime endDate = DateTime.utc(int.parse(chosenYear), month + 1, 1).subtract(Duration(days: 1));

        // Hole die Transaktionen für den aktuellen Monat
        List<Transaction> monthTransactions = await getSpecificTransactionByDateRange(documentId, "null", startDate, endDate, accountid);

        double monthIncome = 0.0;
        double monthExpense = 0.0;

        for (var transaction in monthTransactions) {
          if (transaction.type == "Einnahme") {
            monthIncome += transaction.amount;
          } else if (transaction.type == "Ausgabe") {
            monthExpense += transaction.amount;
          }
        }

        // Kumuliertes Netto berechnen
        double netAmount = monthIncome - monthExpense;

        // Monatsschlüssel generieren
        String monthKey = "${startDate.year}-${month.toString().padLeft(2, '0')}";

        return {
          "monthKey": monthKey,
          "monthIncome": monthIncome,
          "monthExpense": monthExpense,
          "netAmount": netAmount
        };
      }));
    }

    // Warte auf alle parallelen Futures
    List<Map<String, dynamic>> results = await Future.wait(futures);

    // Ergebnisse sammeln
    for (var result in results) {
      String monthKey = result["monthKey"];
      double monthIncome = result["monthIncome"];
      double monthExpense = result["monthExpense"];
      double netAmount = result["netAmount"];

      // Aktualisiere Maps und kumulatives Netto
      incomeMap[monthKey] = monthIncome;
      expenseMap[monthKey] = monthExpense;
      cumulativeNetAmount += netAmount;
      netMap[monthKey] = cumulativeNetAmount;

      // Debug-Ausgabe
      //print("Monat: $monthKey, Einnahmen: $monthIncome, Ausgaben: $monthExpense, Kumuliertes Netto: $cumulativeNetAmount");
    }

    print("Left calculateYearlySpendingByMonth2");
    return [incomeMap, expenseMap, netMap];
  }



  Future<Map<String, double>> calculateYearlySpendingByMonth(String documentId, String type, String chosenYear, String accountid) async {
    print("Entered calculateYearlySpendingByMonth");
    Map<String, double> yearlySpending = {}; // Initialisiere das Dictionary
    double cumulativeNetAmount = 0.0;
    for (int month = 1; month <= 12; month++) {

      DateTime startDate = DateTime.utc(int.parse(chosenYear), month, 1);
      DateTime endDate = DateTime.utc(int.parse(chosenYear), month + 1, 1).subtract(Duration(days: 1));



      // Hole die Transaktionen für den aktuellen Monat
      List<Transaction> monthTransactions = await getSpecificTransactionByDateRange(documentId, type, startDate, endDate,  accountid);

      double monthIncome = 0.0;
      double monthExpense = 0.0;

      for (var transaction in monthTransactions) {
        if (transaction.type == "Einnahme") {
          monthIncome += transaction.amount;
        } else if (transaction.type == "Ausgabe") {
          monthExpense += transaction.amount;
        }
      }

      // Berechne den Netto-Wert für diesen Monat und füge ihn zum Dictionary hinzu
      String monthKey = "${startDate.year}-${month.toString().padLeft(2, '0')}";
      if (type == "null") {
        // Netto-Wert ist die Differenz zwischen den Einnahmen und Ausgaben
        cumulativeNetAmount += (monthIncome - monthExpense);
        yearlySpending[monthKey] = cumulativeNetAmount; // Speichere den kumulierten Netto-Wert
      } else if (type == "Einnahme") {
        yearlySpending[monthKey] = monthIncome; // Speichere nur die Einnahmen
      } else if (type == "Ausgabe") {
        yearlySpending[monthKey] = monthExpense; // Speichere nur die Ausgaben
      }

      // Debug-Ausgabe für jeden Monat
      //print("Monat: $monthKey, Einnahmen: $monthIncome, Ausgaben: $monthExpense, Kumuliertes Netto: $cumulativeNetAmount");
    }
    print("Left calculateYearlySpendingByMonth");
    return yearlySpending;
  }



  Future<List<double>> calculateMonthlySpendingByDay(
      String documentId, String type, String chosenYear, String chosenMonth, double lastMonthBalance, String accountid) async {
    print("Entered calculateMonthlySpendingByDay");

    // Erster und letzter Tag des aktuellen Monats
    DateTime startDate = DateTime.utc(int.parse(chosenYear), int.parse(chosenMonth), 1);
    DateTime endDate = DateTime.utc(int.parse(chosenYear), int.parse(chosenMonth) + 1, 1).subtract(Duration(days: 1));

    // Initialisierung der Liste für die Tage des Monats
    List<double> monthlySpending = List.filled(endDate.day, 0.0);

    // Hole alle Transaktionen für den aktuellen Monat
    List<Transaction> monthTransactions = await getSpecificTransactionByDateRange(
        documentId, "null", startDate, endDate, accountid);

    // Liste für parallele Futures
    List<Future<Map<String, dynamic>>> futures = [];

    // Erstelle Futures für jeden Tag des Monats
    for (int day = 1; day <= endDate.day; day++) {
      futures.add(Future(() async {
        DateTime currentDay = DateTime.utc(int.parse(chosenYear), int.parse(chosenMonth), day).subtract(Duration(microseconds: 1));

        // Filtere Transaktionen für den aktuellen Tag
        List<Transaction> dayTransactions = monthTransactions.where((transaction) {
          return transaction.date.toUtc().year == currentDay.year &&
              transaction.date.toUtc().month == currentDay.month &&
              transaction.date.toUtc().day == currentDay.day;
        }).toList();

        double dayIncome = 0.0;
        double dayExpense = 0.0;

        for (var transaction in dayTransactions) {
          if (transaction.type == "Einnahme") {
            dayIncome += transaction.amount;
          } else if (transaction.type == "Ausgabe") {
            dayExpense += transaction.amount;
          }
        }

        // Ergebnis zurückgeben
        return {
          "dayIndex": day - 1, // Liste ist 0-basiert
          "dayIncome": dayIncome,
          "dayExpense": dayExpense
        };
      }));
    }

    // Warte auf alle parallelen Futures
    List<Map<String, dynamic>> results = await Future.wait(futures);

    // Variablen zur Berechnung des kumulierten Netto-Guthabens
    double cumulativeNetAmount = lastMonthBalance;

    // Ergebnisse sammeln
    for (var result in results) {
      int dayIndex = result["dayIndex"];
      double dayIncome = result["dayIncome"];
      double dayExpense = result["dayExpense"];

      if (type == "null") {
        // Aktualisiere das kumulative Netto-Guthaben
        cumulativeNetAmount += (dayIncome - dayExpense);
        monthlySpending[dayIndex] = cumulativeNetAmount;
      } else if (type == "Einnahme") {
        monthlySpending[dayIndex] = dayIncome;
      } else if (type == "Ausgabe") {
        monthlySpending[dayIndex] = dayExpense;
      }
    }

    print("Left calculateMonthlySpendingByDay");
    return monthlySpending;
  }






// Hilfsfunktion zur Berechnung der Kalenderwoche
  int _getWeekNumber(DateTime date) {
    // 4. Januar verwenden, da dies immer in der ersten Kalenderwoche des Jahres liegt
    final firstThursday = DateTime.utc(date.year, 1, 4);
    final daysDifference = date.difference(firstThursday).inDays;
    return (daysDifference / 7).ceil() + 1;
  }



  Future<List<double>> calculateWeeklySpendingByDay(String documentId, String type, String accountid) async {
    List<double> weeklySpending = List.filled(7, 0.0); // Initialisierung der Liste für die Wochentage
    double cumulativeNetAmount = 0.0; // Netto-Wert, der sich über die Woche hinweg summiert

    // Bestimme die aktuelle Woche (Montag bis Sonntag)
    DateTime now = DateTime.now();
    DateTime startOfWeek = now.subtract(Duration(days: now.weekday)); // Montag dieser Woche
    DateTime endOfWeek = startOfWeek.add(Duration(days: 6)); // Sonntag dieser Woche
    print("WEEKLY: Start Date: $startOfWeek, End Date: $endOfWeek");

    // Hole die Transaktionen für die aktuelle Woche
    List<Transaction> weekTransactions = await getSpecificTransactionByDateRange(documentId, "null", startOfWeek, endOfWeek, accountid);
    print("Wöchentliche Transaktionen in Firestore: $weekTransactions");

    // Iteriere über alle Tage der Woche (Montag bis Sonntag)
    for (int i = 0; i < 7; i++) {
      DateTime currentDay = startOfWeek.add(Duration(days: i));

      // Filtere die Transaktionen für den aktuellen Tag
      List<Transaction> dayTransactions = weekTransactions.where((transaction) {
        return transaction.date.toUtc().year == currentDay.year &&
            transaction.date.toUtc().month == currentDay.month &&
            transaction.date.toUtc().day == currentDay.day;
      }).toList();

      // Berechne Einnahmen und Ausgaben für den aktuellen Tag
      double dayIncome = 0.0;
      double dayExpense = 0.0;

      for (var transaction in dayTransactions) {
        if (transaction.type == "Einnahme") {
          dayIncome += transaction.amount;
        } else if (transaction.type == "Ausgabe") {
          dayExpense += transaction.amount;
        }
      }

      // Berechne den Netto-Wert oder summiere nur den spezifischen Typ
      if (type == "null") {
        // Netto-Wert ist die Differenz zwischen den Einnahmen und Ausgaben
        cumulativeNetAmount += (dayIncome - dayExpense);
        weeklySpending[i] = cumulativeNetAmount; // Kumulierten Netto-Wert speichern
      } else if (type == "Einnahme") {
        weeklySpending[i] = dayIncome;
      } else if (type == "Ausgabe") {
        weeklySpending[i] = dayExpense;
      }

      // Debug-Ausgabe für den Tag
      print("Tag: ${currentDay.weekday}, Einnahmen: $dayIncome, Ausgaben: $dayExpense, Kumuliertes Netto: $cumulativeNetAmount");
    }

    return weeklySpending;
  }






  DateTime _getMondayOfWeek(DateTime date) {
    int weekday = date.weekday;
    int daysToSubtract = weekday - DateTime.monday;

    // Subtrahiere die benötigte Anzahl an Tagen und setze die Zeit auf Mitternacht
    DateTime mondayOfWeek = DateTime.utc(
      date.year,
      date.month,
      date.day - daysToSubtract, // Subtrahiere die Tage
    );

    print("IST DER MONTag korrekt? ${mondayOfWeek}");
    return mondayOfWeek; // Montag um 00:00:00 UTC
  }





  Future<List<Transaction>> getTransactionsByDateRangeAndCategory(
      String documentId,
      String categoryId,
      DateTime startDate,
      DateTime endDate,
      String accountid) async {
    try {
      // Start- und Enddatum setzen
      startDate = DateTime.utc(startDate.year, startDate.month, startDate.day, 0, 0, 0)
          .subtract(Duration(microseconds: 1)); // Startzeit auf 00:00 setzen
      endDate = DateTime(endDate.year, endDate.month, endDate.day + 1)
          .subtract(Duration(microseconds: 1)); // Endzeit auf den letzten Moment des Tages setzen

      // Referenz zur Transaktionskollektion
      final userTransactionsRef = usersRef.doc(documentId).collection('Transactions');

      // Basiskonfiguration der Abfrage
      firestore.Query query = userTransactionsRef
          .where('categoryId', isEqualTo: categoryId)
          .where('date', isGreaterThanOrEqualTo: startDate.toIso8601String())
          .where('date', isLessThanOrEqualTo: endDate.toIso8601String());

      // Filterung nach accountId nur, wenn es nicht null oder leer ist
      if (accountid.isNotEmpty) {
        query = query.where('accountId', isEqualTo: accountid);
      }

      // Query ausführen
      firestore.QuerySnapshot snapshot = await query
          .orderBy('date', descending: true)
          .get();

      // Ergebnisse in Transaktionsobjekte umwandeln
      return snapshot.docs
          .map((doc) => Transaction.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      print("Error getting transactions by date range: $e");
      return [];
    }
  }





  Future<Map<int, double>> getCurrentMonthTransactionsByDateRangeAndCategory(String documentId, String categoryId, String accountid) async {
    Map<int, double> monthlyCategoryValues = {};
    DateTime today = DateTime.now();
    DateTime usableToday = DateTime(today.year, today.month, today.day);
    //print("DAYTIME NOW IST: ${today} ODER AUCH $today");
    DateTime startDate = DateTime(today.year, today.month, 1);

    // Retrieve transactions for the entire month
    List<Transaction> transactions = await getTransactionsByDateRangeAndCategory(documentId, categoryId, startDate, usableToday, accountid);

    //print(transactions);

    // Iterate through each day of the current month up to today
    for (int day = 1; day <= usableToday.day; day++) {
      DateTime currentDay = DateTime(usableToday.year, usableToday.month, day).subtract(Duration(microseconds: 1));
      //print("Der Tag innerhalb der iteration lautet: $currentDay");
      //print("Today Monat ist: ${currentDay.month}! Today Tag ist: ${currentDay.day}!");

      // Filter transactions for the current day
      List<Transaction> dayTransactions = transactions.where((transaction) {
        return transaction.date.toUtc().year == currentDay.year &&
            transaction.date.toUtc().month == currentDay.month &&
            transaction.date.toUtc().day == currentDay.day;
      }).toList();

      // Calculate the total expense for the day
      double dayExpense = 0.0;
      for (var transaction in dayTransactions) {
        if (transaction.type == "Ausgabe") {
          dayExpense += transaction.amount;
        }
      }

      // Store the day's expense in the map
      monthlyCategoryValues[day] = dayExpense;
    }

    return monthlyCategoryValues;
  }

  Future<Map<int, double>> calculateMonthlyCategoryExpenses(String documentId, String categoryId, String chosenYear, String bankAccount) async {
    Map<int, double> monthlyCategoryExpenses = {}; // Initialisiere das Dictionary

    for (int month = 1; month <= 12; month++) {
      // Berechne den Start- und Endzeitpunkt für den aktuellen Monat
      DateTime startDate = DateTime.utc(int.parse(chosenYear), month, 1);
      DateTime endDate = DateTime.utc(int.parse(chosenYear), month + 1, 1)
          .subtract(Duration(days: 1));

      // Hole die Transaktionen für den aktuellen Monat und die Kategorie
      List<Transaction> monthTransactions = await getTransactionsByDateRangeAndCategory(
        documentId,
        categoryId,
        startDate,
        endDate,
        bankAccount
      );

      // Berechne die Gesamtausgaben für den aktuellen Monat
      double monthExpense = 0.0;
      for (var transaction in monthTransactions) {
        if (transaction.type == "Ausgabe") {
          monthExpense += transaction.amount;
        }
      }

      // Speichere die Gesamtausgaben des Monats in der Map
      monthlyCategoryExpenses[month] = monthExpense;
    }

    return monthlyCategoryExpenses;
  }


  Future<Map<int, double>> getCurrentWeekTransactionsByDateRangeAndCategory(
      String documentId, String categoryId, String accountid) async {
    Map<int, double> weeklyCategoryValues = {};

    // Berechne den Montag der aktuellen Woche
    DateTime today = DateTime.now();
    DateTime mondayOfWeek = _getMondayOfWeek(today);

    // Enddatum ist "heute", aber ohne Uhrzeit
    DateTime usableToday = DateTime(today.year, today.month, today.day);

    // Hole Transaktionen im wöchentlichen Zeitrahmen
    List<Transaction> transactions = await getTransactionsByDateRangeAndCategory(
      documentId,
      categoryId,
      mondayOfWeek,
      usableToday,
        accountid

    );

    //print("Transaktionen der Woche: $transactions");

    // Iteriere durch die Tage von Montag bis heute
    for (int i = 0; i <= usableToday.difference(mondayOfWeek).inDays+1; i++) {
      DateTime currentDay = mondayOfWeek.add(Duration(days: i));
      //print("Der aktuelle Tag ist: $currentDay");

      // Filtere Transaktionen für den aktuellen Tag
      List<Transaction> dayTransactions = transactions.where((transaction) {
        return transaction.date.toUtc().year == currentDay.year &&
            transaction.date.toUtc().month == currentDay.month &&
            transaction.date.toUtc().day == currentDay.day;
      }).toList();

      // Berechne die Gesamtausgaben für den aktuellen Tag
      double dayExpense = 0.0;
      for (var transaction in dayTransactions) {
        if (transaction.type == "Ausgabe") {
          dayExpense += transaction.amount;
        }
      }

      // Speichere die Ausgaben des Tages in der Map
      int weekDayIndex = currentDay.weekday; // 1 = Montag, 7 = Sonntag
      weeklyCategoryValues[weekDayIndex] = dayExpense;
    }

    return weeklyCategoryValues;
  }


  Future<Map<String, double>> fetchUrgentAndNonUrgentExpenses(
      String documentId, DateTime startDate, DateTime endDate, String accountid) async {
    try {
      // Hole alle Transaktionen im gegebenen Datumsbereich
      List<Transaction> transactions =
      await getSpecificTransactionByDateRange(documentId, "null", startDate, endDate, accountid);

      // Initialisiere Summen
      double urgentTotal = 0.0;
      double nonUrgentTotal = 0.0;

      // Lokales Filtern nach "Ausgabe" und Summieren der Beträge
      List<Transaction> expenseTransactions =
      transactions.where((transaction) => transaction.type == "Ausgabe").toList();

      for (var transaction in expenseTransactions) {
        if (transaction.importance) {
          urgentTotal += transaction.amount; // Dringend
        } else {
          nonUrgentTotal += transaction.amount; // Nicht dringend
        }
      }

      // Ergebnisse zurückgeben
      return {
        "Dringend": urgentTotal,
        "Nicht dringend": nonUrgentTotal,
      };
    } catch (e) {
      print("Fehler beim Abrufen und Filtern der Transaktionen: $e");
      return {
        "Dringend": 0.0,
        "Nicht dringend": 0.0,
      };
    }
  }






  Future<List<Category>> getUserCategoriesWithBudget(String documentId) async {
    try {
      final userCategoriesRef = usersRef.doc(documentId).collection('Categories');
      firestore.QuerySnapshot snapshot = await userCategoriesRef.get();

      // Map und Filter gleichzeitig: Nur Kategorien mit gültigem Budgetlimit
      return snapshot.docs.map((doc) {
        try {
          Category category = Category.fromMap(doc.data() as Map<String, dynamic>, doc.id);

          // Nur Kategorien zurückgeben, bei denen ein Budgetlimit existiert und > 0 ist
          if (category.budgetLimit != null && category.budgetLimit! > 0) {
            return category;
          } else {
            return null; // Ignoriere Kategorien ohne gültiges Budget
          }
        } catch (e) {
          print("Error parsing category: $e");
          return null; // Handle gracefully
        }
      }).whereType<Category>().toList(); // Entferne nulls aus der Liste
    } catch (e) {
      print("Error getting user categories: $e");
      return [];
    }
  }}