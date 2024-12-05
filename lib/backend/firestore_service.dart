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
      List<Map<String, dynamic>> csvData, String userId) {
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
        payerOrRecipient: row['Auftraggeber/Empfänger']?.toString() ?? '',
        description: row['Buchungstext']?.toString() ?? '',
        outflow: outflow,
        inflow: inflow,
      );
    }).toList();
  }

// Function to import CSV transactions into Firestore
  Future<void> importCsvTransactions(String userId) async {
    try {
      print("Select a CSV file for import...");
      List<Map<String, dynamic>> csvData = await pickAndReadCsvWeb();

      if (csvData.isEmpty) {
        print("No data found in the CSV file.");
        return;
      }

      List<ImportedTransaction> transactions =
      convertCsvDataToImportedTransactions(csvData, userId);

      print("Saving transactions to Firestore...");
      FirestoreService firestoreService = FirestoreService();

      for (var transaction in transactions) {
        await firestoreService.createImportedTransaction(userId, transaction);
        print("Saved transaction: ${transaction.toMap()}");
      }

      print("All transactions imported successfully!");
    } catch (e) {
      print("Error importing transactions: $e");
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
      return snapshot.docs.map((doc) => BankAccount.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
    } catch (e) {
      print("Error getting user bank accounts: $e");
      return [];
    }
  }

  /// Updates an existing bank account in Firestore for a specific user.
  ///
  /// This function takes the user's `documentId` and a `BankAccount` object as input,
  /// and updates the corresponding bank account document in the user's `bankAccounts` subcollection.
  Future<void> updateBankAccount(String documentId, BankAccount account) async {
    try {
      final userBankAccountsRef = usersRef.doc(documentId).collection('bankAccounts');
      await userBankAccountsRef.doc(account.id).update(account.toMap());
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
  ///TEST


  /// Retrieves all transactions for a specific user, ordered by date (latest first).
  ///
  /// This function takes the user's `documentId` as input and retrieves all transaction documents
  /// from the user's `Transactions` subcollection. The results are ordered by date with the latest
  /// transaction appearing first.
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
  Future<Transaction?> getTransaction(String documentId, String transactionId) async {
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
  Future<void> updateTransaction(String documentId, Transaction transaction) async {
    try {
      final userTransactionsRef = usersRef.doc(documentId).collection('Transactions');
      await userTransactionsRef.doc(transaction.id).update(transaction.toMap());
    } catch (e) {
      print("Error updating transaction: $e");
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

  // =======================
  //  Subscription Functions
  // =======================

  /// Creates a new subscription in Firestore for a specific user.
  ///
  /// This function takes the user's `documentId` and a `Subscription` object as input,
  /// and adds the subscription to the user's `Subscriptions` subcollection.
  Future<void> createSubscription(String documentId, Subscription subscription) async {
    try {
      final userSubscriptionsRef = usersRef.doc(documentId).collection('Subscriptions');
      firestore.DocumentReference docRef = await userSubscriptionsRef.add(subscription.toMap());
      subscription.id = docRef.id;
      await docRef.set(subscription.toMap());
    } catch (e) {
      print("Error creating subscription: $e");
    }
  }

  /// Retrieves all subscriptions for a specific user from Firestore.
  ///
  /// This function takes the user's `documentId` as input and retrieves all subscription documents
  /// from the user's `Subscriptions` subcollection.
  Future<List<Subscription>> getUserSubscriptions(String documentId) async {
    try {
      final userSubscriptionsRef = usersRef.doc(documentId).collection('Subscriptions');
      firestore.QuerySnapshot snapshot = await userSubscriptionsRef.get();
      return snapshot.docs.map((doc) => Subscription.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
    } catch (e) {
      print("Error getting user subscriptions: $e");
      return [];
    }
  }

  /// Updates an existing subscription in Firestore for a specific user.
  ///
  /// This function takes the user's `documentId` and a `Subscription` object as input,
  /// and updates the corresponding subscription document in the user's `Subscriptions` subcollection.
  Future<void> updateSubscription(String documentId, Subscription subscription) async {
    try {
      final userSubscriptionsRef = usersRef.doc(documentId).collection('Subscriptions');
      await userSubscriptionsRef.doc(subscription.id).update(subscription.toMap());
    } catch (e) {
      print("Error updating subscription: $e");
    }
  }

  /// Deletes a subscription from Firestore for a specific user.
  ///
  /// This function takes the user's `documentId` and the `subscriptionId` as input,
  /// and deletes the corresponding subscription document from the user's `Subscriptions` subcollection.
  Future<void> deleteSubscription(String documentId, String subscriptionId) async {
    try {
      final userSubscriptionsRef = usersRef.doc(documentId).collection('Subscriptions');
      await userSubscriptionsRef.doc(subscriptionId).delete();
    } catch (e) {
      print("Error deleting subscription: $e");
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
  Future<List<Transaction>> getTransactionsByDateRange(String documentId, DateTime startDate, DateTime endDate) async {
    try {
      final userTransactionsRef = usersRef.doc(documentId).collection('Transactions');
      firestore.QuerySnapshot snapshot = await userTransactionsRef
          .where('date', isGreaterThanOrEqualTo: startDate)
          .where('date', isLessThanOrEqualTo: endDate)
          .orderBy('date', descending: true)
          .get();
      return snapshot.docs.map((doc) => Transaction.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
    } catch (e) {
      print("Error getting transactions by date range: $e");
      return [];
    }
  }

  /// Calculates monthly spending for a given user.
  ///
  /// This function takes the user's `documentId` and a `year` as input,
  /// and calculates the total spending for each month of the given year.
  Future<List<double>> calculateMonthlySpending(String documentId, int year) async {
    List<double> monthlySpending = List.filled(12, 0.0);
    for (int month = 1; month <= 12; month++) {
      DateTime startDate = DateTime(year, month, 1);
      DateTime endDate = DateTime(year, month, DateTime(year, month + 1, 0).day);
      List<Transaction> monthTransactions = await getTransactionsByDateRange(documentId, startDate, endDate);
      for (var transaction in monthTransactions) {
        if (transaction.amount < 0) {
          monthlySpending[month - 1] += transaction.amount;
        }
      }
    }
    return monthlySpending;
  }


}