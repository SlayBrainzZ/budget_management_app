import 'dart:async';
import 'dart:math';
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
      final userRef = usersRef.doc(user.userId); // Use userId as the document ID

      // Check if the user document already exists
      final docSnapshot = await userRef.get();
      if (docSnapshot.exists) {
        print("User with userId ${user.userId} already exists.");
      } else {
        // Create a new user document
        await userRef.set(user.toMap());

        // Create subcollections for the user
        await userRef.collection('Categories').add({});
        await userRef.collection('Transactions').add({});
        await userRef.collection('Subscriptions').add({});
        await userRef.collection('bankAccounts').add({});

        print("User with userId ${user.userId} created successfully.");
      }
    } catch (e) {
      print("Error creating user: $e");
    }
  }

  Future<User?> getUser(String userId) async {
    firestore.QuerySnapshot snapshot = await usersRef.where('userId', isEqualTo: userId).get();
    if (snapshot.docs.isNotEmpty) {
      return User.fromMap(snapshot.docs.first.data() as Map<String, dynamic>, snapshot.docs.first.id);
    }
    return null;
  }

  Future<void> updateUser(User user) async {
    await usersRef.doc(user.id).update(user.toMap());
  }

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

  // Function to create an imported transaction
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

  // Function to fetch all imported transactions
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

  Future<List<BankAccount>> getUserBankAccounts(String documentId) async {
    try {
      final userBankAccountsRef = usersRef.doc(documentId).collection('bankAccounts');
      firestore.QuerySnapshot snapshot = await userBankAccountsRef.get();
      print("Abgerufene Konten: ${snapshot.docs.length}");
      //return snapshot.docs.map((doc) => BankAccount.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
      // Filtere nur Konten mit gültigem Namen und gültigem Typ
      return snapshot.docs
          .map((doc) => BankAccount.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .where((account) => account.accountName != null && account.accountName!.isNotEmpty && account.accountType != 'unknown')
          .toList();
    } catch (e) {
      print("Error getting user bank accounts: $e");
      return [];
    }
  }

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

  Future<void> updateBankAccount(String userId, BankAccount account) async {
    try {
      final userBankAccountsRef = usersRef.doc(userId).collection('bankAccounts');
      if (account.id != null) {
        await userBankAccountsRef.doc(account.id).update(account.toMap());
      } else {
        throw Exception("Account ID ist null. Kann nicht aktualisieren.");
      }
    } catch (e) {
      print("Fehler beim Aktualisieren des Bankkontos: $e");
    }
  }


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

  Future<List<Category>> getUserCategories(String documentId) async {
    //print("entered getUserCategories" );
    try {
      final userCategoriesRef = usersRef.doc(documentId).collection('Categories');
      firestore.QuerySnapshot snapshot = await userCategoriesRef.get();
      return snapshot.docs.map((doc) {
        try {
          return Category.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        } catch (e) {
          print("Error parsing category: $e");
          //print("left getUserCategories" );
          return null; // Handle gracefully
        }
      }).whereType<Category>().toList(); // Remove nulls from the list
    } catch (e) {
      print("Error getting user categories: $e");
      return [];
    }
  }

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

  Future<void> updateCategoryBudgetLimit(String userId, String categoryId, double budgetLimit) async {
    try {
      final userCategoriesRef = usersRef.doc(userId).collection('Categories');
      await userCategoriesRef.doc(categoryId).update({'budgetLimit': budgetLimit.toString()});
    } catch (e) {
      print("Fehler beim Aktualisieren des Budgetlimits: $e");
    }
  }

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

  Future<void> handleTransactionAdditionAndBudgetCheck(
      String userId, Transaction transaction,
      {String? categoryId, String? accountId}) async {
    try {
      if (categoryId != null) transaction.categoryId = categoryId;
      if (accountId != null) transaction.accountId = accountId;


      double totalSpentBefore = await getCurrentMonthTotalSpent(userId, transaction.categoryId!);

      // 2. Berechne den Kontostand vor der Transaktion
      BankAccount? bankA = await getBankAccount(userId, transaction.accountId!);
      if (bankA == null) {
        print("Fehler: Konto nicht gefunden.");
        return;
      }
      double totalBalanceBefore = await calculateBankAccountBalance(userId, bankA);
      print("totalBalanceBefore ist $totalBalanceBefore");


      await createTransaction2(userId, transaction, categoryId: categoryId, accountId: accountId);


      //await Future.delayed(Duration(milliseconds: 500));

      double totalSpentAfter = await getCurrentMonthTotalSpent(userId, transaction.categoryId!);

      // 6. Berechne den Kontostand nach der Transaktion
      double totalBalanceAfter = await calculateBankAccountBalance(userId, bankA);
      print("totalBalanceAfter ist $totalBalanceAfter");

      // 7. Budgetprüfung und Benachrichtigung
      await _checkAndHandleBudgetNotifications(userId, transaction.categoryId!, totalSpentBefore, totalSpentAfter);

      // 8. Überprüfung, ob der Kontostand negativ wurde
      await _checkAndHandleBalanceNotifications(userId, totalBalanceBefore, totalBalanceAfter, transaction.accountId!, bankA);


    } catch (e) {
      print("Fehler bei der Budgetlimit-Prüfung: $e");
    }
  }



  Future<double> getCurrentMonthTotalSpent(String userId, String categoryId) async {
    return await getCurrentMonthCombinedTransactions(userId, categoryId, "null");
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

  Future<void> handleTransactionUpdateAndBudgetCheck(
      String userId, String transactionId, Transaction transaction, String categoryId, double budget, double balance) async {
    try {
      double totalSpentBefore = budget;
      double totalBalanceBefore = balance;

      // 1. Transaktion aktualisieren
      await updateTransaction(userId, transactionId, transaction);

      // 2. Neue Ausgaben abrufen
      double totalSpentAfter = await getCurrentMonthTotalSpent(userId, categoryId);

      // 3. Kontostand nach Transaktion abrufen
      BankAccount? bankA = await getBankAccount(userId, transaction.accountId!);
      if (bankA == null) {
        print("Fehler: Konto nicht gefunden.");
        return;
      }

      double totalBalanceAfter = await calculateBankAccountBalance(userId, bankA);

      // 4. Benachrichtigungen prüfen und ggf. senden
      await _checkAndHandleBalanceNotifications(userId, totalBalanceBefore, totalBalanceAfter, transaction.accountId!, bankA);

      await _checkAndHandleBudgetNotifications(userId, categoryId, totalSpentBefore, totalSpentAfter);

    } catch (e) {
      print("Fehler bei der Aktualisierung der Transaction: $e");
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


  Future<void> handleImportedTransactionUpdateAndBudgetCheck(
      String userId, String transactionId, ImportedTransaction transaction,
      String categoryId, double budget, double balance) async {
    try {
      double totalSpentBefore = budget;
      double totalBalanceBefore = balance;

      await updateImportedTransaction(userId, transactionId, transaction);

      double totalSpentAfter = await getCurrentMonthTotalSpent(userId, categoryId);
      BankAccount? bankA = await getBankAccount(userId, transaction.accountId!);
      if (bankA == null) {
        print("Fehler: Konto nicht gefunden.");
        return;
      }
      double totalBalanceAfter = await calculateImportBankAccountBalance(userId, bankA);


      await _checkAndHandleBalanceNotifications(userId, totalBalanceBefore, totalBalanceAfter, transaction.accountId!, bankA);
      await _checkAndHandleBudgetNotifications(userId, categoryId, totalSpentBefore, totalSpentAfter);

    } catch (e) {
      print("Fehler bei der Aktualisierung der Imported Transaction: $e");
    }
  }



  Future<void> deleteTransaction(String documentId, String transactionId) async {
    try {
      final userTransactionsRef = usersRef.doc(documentId).collection('Transactions');
      await userTransactionsRef.doc(transactionId).delete();
    } catch (e) {
      print("Error deleting transaction: $e");
    }
  }

  Future<void> handleTransactionDeletionAndBudgetCheck(
      String userId, String transactionId, String accountId, String categoryId, double budget, double balance) async {
      try {
        double totalSpentBefore = budget;
        double totalBalanceBefore = balance;
        print("totalBalancebefore ist $totalBalanceBefore");

        await deleteTransaction(userId, transactionId);



        double totalSpentAfter = await getCurrentMonthTotalSpent(userId, categoryId);
        BankAccount? bankA = await getBankAccount(userId, accountId);
        if (bankA == null) {
          print("Fehler: Konto nicht gefunden.");
          return;
        }
        double totalBalanceAfter = await calculateBankAccountBalance(userId, bankA);

        print("totalBalanceAfter ist $totalBalanceAfter");
        await _checkAndHandleBalanceNotifications(userId, totalBalanceBefore, totalBalanceAfter, accountId, bankA);
        await _checkAndHandleBudgetNotifications(userId, categoryId, totalSpentBefore, totalSpentAfter);

      } catch (e) {
        print("Fehler bei der Bearbeitung der Transaktionslöschung: $e");
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
      // Start mit dem aktuellen Kontostand im Bankkonto
      //double totalBalance = bankAccount.balance ?? 0.0;
      double totalBalance = 0.0;
      // Letzter Aktualisierungszeitpunkt des Kontos
      //DateTime? lastUpdated = bankAccount.lastUpdated;

      // Abrufen aller relevanten Transaktionen
      List<Transaction> transactions = await FirestoreService()
          .getTransactionsByAccountIds(documentId, [bankAccount.id!]);



      transactions.forEach((transaction) {
        totalBalance += transaction.amount;
        //print("Transaction Amount: ${transaction.amount}");
      });
      /*
      for (var transaction in transactions) {
        // Überprüfen, ob die Transaktion nach der letzten Aktualisierung liegt
        if (lastUpdated == null || transaction.date.isAfter(lastUpdated)) {
          if (transaction.type == 'Einnahme') {
            totalBalance += transaction.amount;
          } else if (transaction.type == 'Ausgabe') {
            totalBalance += transaction.amount;
          }
        }
      }*/

      // Kontostand und Aktualisierungszeitpunkt speichern
      bankAccount.balance = totalBalance;
      bankAccount.lastUpdated = DateTime.now();

      //await updateBankAccount(documentId, bankAccount);

      return totalBalance;
    } catch (e) {
      print("Error calculating balance for bank account: $e");
      return bankAccount.balance ?? 0.0;
    }
  }

  Future<double> calculateImportBankAccountBalance(String documentId, BankAccount bankAccount) async {
    try {
      // Start mit dem aktuellen Kontostand im Bankkonto
      double totalBalance = 0.0;

      // Letzter Aktualisierungszeitpunkt des Kontos
      //DateTime? lastUpdated = bankAccount.lastUpdated;

      List<ImportedTransaction> transactions = await FirestoreService()
          .getImportedTransactionsByAccountIds(documentId, [bankAccount.id!]);
      transactions.forEach((transaction) {
        totalBalance += transaction.amount;
        //print("Transaction Amount: ${transaction.amount}");
      });

/*
      // Berechnung des Gesamtguthabens basierend auf den Transaktionen
      for (var transaction in transactions) {
        if (lastUpdated == null || transaction.date.isAfter(lastUpdated)) {
          totalBalance += transaction.amount;
          // Einnahmen addieren (inflow)
          if (transaction.inflow > 0) {
            totalBalance += transaction.amount;
            print("balanceinflow: $totalBalance");
          }
          // Ausgaben subtrahieren (outflow)
          if (transaction.outflow > 0) {
            totalBalance += transaction.amount;
            print("balanceinflow: $totalBalance");
          }}
      print("balance: $totalBalance");
      }*/

      // Kontostand und Aktualisierungszeitpunkt speichern
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

  Future<double> calculateTotalBalance(String documentId) async {
    List<Transaction> transactions = await getUserTransactions(documentId);
    double totalBalance = 0.0;
    for (var transaction in transactions) {
      totalBalance += transaction.amount;
    }
    return totalBalance;
  }


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

  Future<List<ImportedTransaction>> getImportedTransactionsByDateRange(String documentId, String type, DateTime startDate, DateTime endDate, String accountid, bool forBalance) async {
    firestore.Query query;
    try {
      // Setze startDate auf Mitternacht und endDate auf den letzten Moment des Tages
      startDate = DateTime.utc(startDate.year, startDate.month, startDate.day, 0, 0, 0).subtract(Duration(microseconds: 1));
      endDate = DateTime.utc(endDate.year, endDate.month, endDate.day, 23, 59, 59);

      // Zugriff auf die 'ImportedTransactions'-Unterkollektion des Nutzers
      final userImportedTransactionsRef = usersRef.doc(documentId).collection('ImportedTransactions');


      if (forBalance == false) {
        // Basiskonfiguration der Abfrage
        query = userImportedTransactionsRef
            .where('date', isGreaterThanOrEqualTo: startDate.toIso8601String())
            .where('date', isLessThanOrEqualTo: endDate.toIso8601String())
            .orderBy('date', descending: true);
      } else {
        query = userImportedTransactionsRef
            .where('date', isLessThan: startDate.toIso8601String())
            .orderBy('date', descending: true);
      }

      // Abfrage ausführen
      firestore.QuerySnapshot querySnapshot = await query.get();

      // Ergebnisse in eine Liste von ImportedTransactions umwandeln
      return querySnapshot.docs.map((doc) {
        return ImportedTransaction.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    } catch (e) {
      print("Error fetching imported transactions by date range: $e");
      return [];
    }
  }


  Future<List<Transaction>> getSpecificTransactionByDateRange(String documentId, String type, DateTime startDate, DateTime endDate, String accountid, bool forBalance) async {


    firestore.Query query;
    try {
      // Setze startDate auf Mitternacht (00:00:00) und endDate auf den letzten Moment des Tages (23:59:59)
      startDate = DateTime.utc(startDate.year, startDate.month, startDate.day, 0, 0, 0).subtract(Duration(microseconds: 1)); // Setze die Zeit auf 00:00
      endDate = DateTime.utc(endDate.year, endDate.month, endDate.day, 23, 59, 59); // Setze die Zeit auf 23:59

      final userTransactionsRef = usersRef.doc(documentId).collection('Transactions');


      if (forBalance == false) {
        query = userTransactionsRef
            .where('date', isGreaterThanOrEqualTo: startDate.toIso8601String())
            .where('date', isLessThanOrEqualTo: endDate.toIso8601String())
            .orderBy('date', descending: true);
      } else {
        query = userTransactionsRef
            .where('date', isLessThan: startDate.toIso8601String())
            .orderBy('date', descending: true);
      }
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


  Future<List<Map<String, double>>> calculateYearlyImportedSpendingByMonth(String documentId, String chosenYear, String accountId) async {


    // Initialisiere Maps für Einnahmen, Ausgaben und Nettoergebnis
    Map<String, double> incomeMap = {};
    Map<String, double> expenseMap = {};
    Map<String, double> netMap = {};

    double cumulativeNetAmount = 0.0; // Startwert für kumulierten Kontostand
    double startBalance = 0.0;

    int currentYear = DateTime.now().year;
    int currentMonth = DateTime.now().month;
    int maxMonth = (int.parse(chosenYear) == currentYear) ? currentMonth : 12;

    // **1. Alle Transaktionen für das Jahr auf einmal abrufen**
    DateTime startDate = DateTime.utc(int.parse(chosenYear), 1, 1);
    DateTime endDate = DateTime.utc(int.parse(chosenYear), 12, 31);

    //alle transactions vor dem gewünschtenZeitraumum den Kontostand zu berechnen
    List<ImportedTransaction> allTransactionsforBalance = await getImportedTransactionsByDateRange(
        documentId, "null", startDate, endDate, accountId, true); //ganz normal aufrufen
    startBalance = allTransactionsforBalance.fold(0.0, (sum, transaction) => sum + transaction.amount);
    cumulativeNetAmount = startBalance;


    //alle transaftions im gewünschten Zeitraum
    List<ImportedTransaction> yearTransactions = await getImportedTransactionsByDateRange(
        documentId, "null", startDate, endDate, accountId, false);

    // **2. Transaktionen in einer Map nach Monat gruppieren**
    Map<int, List<ImportedTransaction>> transactionsByMonth = {};

    for (var transaction in yearTransactions) {
      int month = transaction.date.month;
      transactionsByMonth.putIfAbsent(month, () => []).add(transaction);
    }

    // **3. Iteration über Monate (1–12), falls keine Daten für einen Monat existieren, bleibt er leer**
    for (int month = 1; month <= maxMonth; month++) {
      String monthKey = "$chosenYear-${month.toString().padLeft(2, '0')}";

      // Standardwerte für Monate ohne Transaktionen
      double monthIncome = 0.0;
      double monthExpense = 0.0;

      if (transactionsByMonth.containsKey(month)) {
        for (var transaction in transactionsByMonth[month]!) {
          monthIncome += transaction.inflow > 0 ? transaction.inflow : 0;
          monthExpense += transaction.outflow != 0 ? -transaction.outflow.abs() : 0;
        }
      }

      // Netto für den aktuellen Monat berechnen & kumulativen Betrag aktualisieren
      double netAmount = monthIncome + monthExpense;
      cumulativeNetAmount += netAmount;

      // **4. Ergebnisse in Maps speichern**
      incomeMap[monthKey] = monthIncome;
      expenseMap[monthKey] = monthExpense;
      netMap[monthKey] = cumulativeNetAmount;

    }


    return [incomeMap, expenseMap, netMap];
  }

  Future<List<Map<String, double>>> calculateYearlySpendingByMonth2(String documentId, String chosenYear, String accountid) async {

    // Initialisiere Maps für Einnahmen, Ausgaben und Nettoergebnis
    Map<String, double> incomeMap = {};
    Map<String, double> expenseMap = {};
    Map<String, double> netMap = {};

    double cumulativeNetAmount = 0.0; // Startwert für kumulierten Kontostand
    double startBalance = 0.0;

    // **Bestimme das maximale Monat basierend auf dem Jahr**
    int currentYear = DateTime.now().year;
    int currentMonth = DateTime.now().month;
    int maxMonth = (int.parse(chosenYear) == currentYear) ? currentMonth : 12;

    // **1. Alle Transaktionen für das Jahr auf einmal abrufen**
    DateTime startDate = DateTime.utc(int.parse(chosenYear), 1, 1);
    DateTime endDate = DateTime.utc(int.parse(chosenYear), 12, 31);

    List<Transaction> allTransactionsforBalance = await getSpecificTransactionByDateRange(
        documentId, "null", startDate, endDate, accountid, true); //ganz normal aufrufen
    print("allTransactionsforBalance ist $allTransactionsforBalance");
    startBalance = allTransactionsforBalance.fold(0.0, (sum, transaction) => sum + transaction.amount);
    print("StartBalance für calculateYearlySpendingByMonth2ist $startBalance");
    cumulativeNetAmount = startBalance;

    List<Transaction> yearTransactions = await getSpecificTransactionByDateRange(
        documentId, "null", startDate, endDate, accountid,false);

    // **2. Transaktionen nach Monaten gruppieren**
    Map<int, List<Transaction>> transactionsByMonth = {};

    for (var transaction in yearTransactions) {
      int month = transaction.date.month;
      transactionsByMonth.putIfAbsent(month, () => []).add(transaction);
    }

    // **3. Iteriere über alle Monate und berechne Einnahmen & Ausgaben**
    for (int month = 1; month <= maxMonth; month++) {
      String monthKey = "$chosenYear-${month.toString().padLeft(2, '0')}";

      // Standardwerte für Monate ohne Transaktionen
      double monthIncome = 0.0;
      double monthExpense = 0.0;

      if (transactionsByMonth.containsKey(month)) {
        for (var transaction in transactionsByMonth[month]!) {
          switch (transaction.type) {
            case "Einnahme":
              monthIncome += transaction.amount;
              break;
            case "Ausgabe":
              monthExpense += transaction.amount;
              break;
          }
        }
      }

      // Netto für den aktuellen Monat berechnen & kumulativen Betrag aktualisieren
      double netAmount = monthIncome + monthExpense; // Netto = Einnahmen - Ausgaben
      cumulativeNetAmount += netAmount;

      // **4. Ergebnisse in Maps speichern**
      incomeMap[monthKey] = monthIncome;
      expenseMap[monthKey] = monthExpense;
      netMap[monthKey] = cumulativeNetAmount;

      print("Monat: $monthKey, Einnahmen: $monthIncome, Ausgaben: $monthExpense, Kumuliertes Netto: $cumulativeNetAmount");
    }

    print("Finished calculateYearlySpendingByMonth2");

    return [incomeMap, expenseMap, netMap];
  }


  Future<List<Map<String, double>>> combineYearlyCombinedSpendingByMonth(String documentId, String chosenYear, String accountId) async {
    //print("entered combineYearlyCombinedSpendingByMonth");

    // Initialisiere Maps für Einnahmen, Ausgaben und Netto
    Map<String, double> incomeMap = {};
    Map<String, double> expenseMap = {};
    Map<String, double> netMap = {};

    double cumulativeNetAmount = 0.0; // Startwert für kumulierten Kontostand

    double importedStartBalance = 0.0;
    double manuallyStartBalance = 0.0;

    // **Bestimme das maximale Monat basierend auf dem Jahr**
    int currentYear = DateTime.now().year;
    int currentMonth = DateTime.now().month;
    int maxMonth = (int.parse(chosenYear) == currentYear) ? currentMonth : 12;

    // **1. Alle Transaktionen für das Jahr auf einmal abrufen**
    DateTime startDate = DateTime.utc(int.parse(chosenYear), 1, 1);
    DateTime endDate = DateTime.utc(int.parse(chosenYear), 12, 31);


    //alle importedtransactions vor dem gewünschtenZeitraumum den Kontostand zu berechnen
    List<ImportedTransaction> allImportedTransactionsforBalance = await getImportedTransactionsByDateRange(
        documentId, "null", startDate, endDate, accountId, true); //ganz normal aufrufen
    importedStartBalance = allImportedTransactionsforBalance.fold(0.0, (sum, transaction) => sum + transaction.amount);
    print("StartBalance für importedStartBalance  $importedStartBalance");

    //alle manuallytransactions vor dem gewünschtenZeitraumum den Kontostand zu berechnen
    List<Transaction> allManuallyTransactionsforBalance = await getSpecificTransactionByDateRange(
        documentId, "null", startDate, endDate, accountId, true); //ganz normal aufrufen
    manuallyStartBalance = allManuallyTransactionsforBalance.fold(0.0, (sum, transaction) => sum + transaction.amount);
    print("StartBalance für manuallyStartBalance $manuallyStartBalance");

    cumulativeNetAmount = importedStartBalance + manuallyStartBalance;
    print("StartBalance insgesamt für große statistik $cumulativeNetAmount");


    // Hole ALLE Transaktionen des Jahres auf einmal
    List<Transaction> yearTransactions = await getSpecificTransactionByDateRange(documentId, "null", startDate, endDate, accountId, false);
    List<ImportedTransaction> importedYearTransactions = await getImportedTransactionsByDateRange(documentId, "null", startDate, endDate, accountId, false);

    // **2. Transaktionen nach Monaten gruppieren**
    Map<int, List<Transaction>> transactionsByMonth = {};
    Map<int, List<ImportedTransaction>> importedTransactionsByMonth = {};



    for (var transaction in yearTransactions) {
      int month = transaction.date.month;
      transactionsByMonth.putIfAbsent(month, () => []).add(transaction);
    }

    for (var importedTransaction in importedYearTransactions) {
      int month = importedTransaction.date.month;
      importedTransactionsByMonth.putIfAbsent(month, () => []).add(importedTransaction);
    }

    // **3. Iteration über Monate und Berechnung der Werte**
    for (int month = 1; month <= maxMonth; month++) {
      String monthKey = "$chosenYear-${month.toString().padLeft(2, '0')}";

      double monthIncome = 0.0;
      double monthExpense = 0.0;

      // **Verarbeite reguläre Transaktionen**
      if (transactionsByMonth.containsKey(month)) {
        for (var transaction in transactionsByMonth[month]!) {
          if (transaction.type == "Einnahme") {
            monthIncome += transaction.amount;
          } else if (transaction.type == "Ausgabe") {
            monthExpense += transaction.amount;
          }
        }
      }

      // **Verarbeite importierte Transaktionen**
      if (importedTransactionsByMonth.containsKey(month)) {
        for (var importedTransaction in importedTransactionsByMonth[month]!) {
          monthIncome += importedTransaction.inflow;
          monthExpense += -importedTransaction.outflow.abs();
        }
      }

      // Netto für den aktuellen Monat berechnen & kumulatives Netto aktualisieren
      double netAmount = monthIncome + monthExpense;
      cumulativeNetAmount += netAmount;

      // **4. Ergebnisse in Maps speichern**
      incomeMap[monthKey] = monthIncome;
      expenseMap[monthKey] = monthExpense;
      netMap[monthKey] = cumulativeNetAmount;

      print("Monat: $monthKey, Einnahmen: $monthIncome, Ausgaben: $monthExpense, Kontostand: $cumulativeNetAmount");
    }
    return [incomeMap, expenseMap, netMap];
  }

  Future<List<double>> calculateMonthlyImportedSpendingByDay(String documentId, String type, String chosenYear, String chosenMonth, String accountId) async {

    // Aktuelles Datum abrufen
    DateTime now = DateTime.now();
    int currentYear = now.year;
    int currentMonth = now.month;
    int currentDay = now.day;

    // Start- und Enddatum des Monats berechnen
    DateTime startDate = DateTime.utc(int.parse(chosenYear), int.parse(chosenMonth), 1);
    DateTime endDate = (int.parse(chosenYear) == currentYear && int.parse(chosenMonth) == currentMonth)
        ? DateTime.utc(currentYear, currentMonth, currentDay) // Bis zum heutigen Tag begrenzen
        : DateTime.utc(int.parse(chosenYear), int.parse(chosenMonth) + 1, 1).subtract(Duration(days: 1));

    double cumulativeNetAmount = 0.0;
    double startBalance = 0.0;

    //alle vorherigen transaction
    List<ImportedTransaction> allMonthTransactionsforBalance = await getImportedTransactionsByDateRange(
        documentId, "null", startDate, endDate, accountId, true);
    startBalance = allMonthTransactionsforBalance.fold(0.0, (sum, transaction) => sum + transaction.amount);
    print("StartBalance für calculateMonthlyImportedSpendingByDay $startBalance");
    cumulativeNetAmount = startBalance;



    // Initialisiere die Liste für tägliche Werte
    List<double> monthlySpending = List.filled(endDate.day, 0.0);

    // Hole alle Transaktionen für den Monat **auf einmal**
    List<ImportedTransaction> monthTransactions = await getImportedTransactionsByDateRange(
        documentId, "null", startDate, endDate, accountId, false);

    // **1. Gruppiere Transaktionen nach Tagen**
    Map<int, List<ImportedTransaction>> transactionsByDay = {};

    for (var transaction in monthTransactions) {
      int day = transaction.date.day;
      transactionsByDay.putIfAbsent(day, () => []).add(transaction);
    }

    // **2. Berechnung der täglichen Werte**
    //double cumulativeNetAmount = lastMonthBalance;

    for (int day = 1; day <= endDate.day; day++) {
      double dayInflow = 0.0;
      double dayOutflow = 0.0;

      if (transactionsByDay.containsKey(day)) {
        for (var transaction in transactionsByDay[day]!) {
          dayInflow += transaction.inflow > 0 ? transaction.inflow : 0;
          dayOutflow += transaction.outflow.abs();
        }
      }

      if (type == "null") {
        cumulativeNetAmount += (dayInflow - dayOutflow);
        monthlySpending[day - 1] = cumulativeNetAmount; // Liste ist 0-basiert
      } else if (type == "Einnahme") {
        monthlySpending[day - 1] = dayInflow;
      } else if (type == "Ausgabe") {
        monthlySpending[day - 1] = -dayOutflow;
      }
    }

    return monthlySpending;
  }

  Future<List<double>> calculateMonthlySpendingByDay(String documentId, String type, String chosenYear, String chosenMonth, String accountid) async {

    // Aktuelles Datum abrufen
    DateTime now = DateTime.now();
    int currentYear = now.year;
    int currentMonth = now.month;
    int currentDay = now.day;

    // Start- und Enddatum des Monats berechnen
    DateTime startDate = DateTime.utc(int.parse(chosenYear), int.parse(chosenMonth), 1);
    DateTime endDate = (int.parse(chosenYear) == currentYear && int.parse(chosenMonth) == currentMonth)
        ? DateTime.utc(currentYear, currentMonth, currentDay) // Begrenzung auf aktuellen Tag
        : DateTime.utc(int.parse(chosenYear), int.parse(chosenMonth) + 1, 1).subtract(Duration(days: 1));


    double cumulativeNetAmount = 0.0;
    double startBalance = 0.0;

    //alle vorherigen transaction
    List<Transaction> allMonthTransactionsforBalance = await getSpecificTransactionByDateRange(
        documentId, "null", startDate, endDate, accountid, true);
    startBalance = allMonthTransactionsforBalance.fold(0.0, (sum, transaction) => sum + transaction.amount);
    print("StartBalance für calculateMonthlyImportedSpendingByDay $startBalance");
    cumulativeNetAmount = startBalance;

    // Initialisiere die Liste für tägliche Werte
    List<double> monthlySpending = List.filled(endDate.day, 0.0);

    // Hole alle Transaktionen für den Monat **auf einmal**
    List<Transaction> monthTransactions = await getSpecificTransactionByDateRange(
        documentId, "null", startDate, endDate, accountid, false);


    Map<int, List<Transaction>> transactionsByDay = {};

    for (var transaction in monthTransactions) {
      int day = transaction.date.day;
      transactionsByDay.putIfAbsent(day, () => []).add(transaction);
    }


    for (int day = 1; day <= endDate.day; day++) {
      double dayIncome = 0.0;
      double dayExpense = 0.0;

      if (transactionsByDay.containsKey(day)) {
        for (var transaction in transactionsByDay[day]!) {
          if (transaction.type == "Einnahme") {
            dayIncome += transaction.amount;
          } else if (transaction.type == "Ausgabe") {
            dayExpense += -transaction.amount;
          }
        }
      }

      if (type == "null") {
        cumulativeNetAmount += (dayIncome - dayExpense);
        monthlySpending[day - 1] = cumulativeNetAmount; // Liste ist 0-basiert
      } else if (type == "Einnahme") {
        monthlySpending[day - 1] = dayIncome;
      } else if (type == "Ausgabe") {
        monthlySpending[day - 1] = -dayExpense;
      }
    }

    return monthlySpending;
  }

  Future<List<double>> calculateMonthlyCombinedSpendingByDay(String documentId, String type, String chosenYear, String chosenMonth, String accountId) async {


    // Aktuelles Datum abrufen
    DateTime now = DateTime.now();
    int currentYear = now.year;
    int currentMonth = now.month;
    int currentDay = now.day;

    // Start- und Enddatum des Monats berechnen
    DateTime startDate = DateTime.utc(int.parse(chosenYear), int.parse(chosenMonth), 1);
    DateTime endDate = (int.parse(chosenYear) == currentYear && int.parse(chosenMonth) == currentMonth)
        ? DateTime.utc(currentYear, currentMonth, currentDay) // Begrenzung auf aktuellen Tag
        : DateTime.utc(int.parse(chosenYear), int.parse(chosenMonth) + 1, 1).subtract(Duration(days: 1));

    double cumulativeNetAmount = 0.0;
    double manuallytartBalance = 0.0;
    double importedStartBalance = 0.0;


    //alle vorherigen transaction
    List<ImportedTransaction> allMonthImportedTransactionsforBalance = await getImportedTransactionsByDateRange(
        documentId, "null", startDate, endDate, accountId, true);
    importedStartBalance = allMonthImportedTransactionsforBalance.fold(0.0, (sum, transaction) => sum + transaction.amount);
    print("StartBalance für calculateMonthlyImportedSpendingByDay $importedStartBalance");


    //alle vorherigen transaction
    List<Transaction> allMonthManuallyTransactionsforBalance = await getSpecificTransactionByDateRange(
        documentId, "null", startDate, endDate, accountId, true);
    manuallytartBalance = allMonthManuallyTransactionsforBalance.fold(0.0, (sum, transaction) => sum + transaction.amount);
    print("StartBalance für calculateMonthlyImportedSpendingByDay $manuallytartBalance");
    cumulativeNetAmount = manuallytartBalance + importedStartBalance;



    // Initialisiere die Liste für tägliche Werte
    List<double> monthlySpending = List.filled(endDate.day, 0.0);

    // Hole alle Transaktionen für den Monat **auf einmal**
    List<Transaction> normalTransactions = await getSpecificTransactionByDateRange(
        documentId, "null", startDate, endDate, accountId, false);

    List<ImportedTransaction> importedTransactions = await getImportedTransactionsByDateRange(
        documentId, "null", startDate, endDate, accountId, false);

    // **1. Gruppiere normale Transaktionen nach Tagen**
    Map<int, List<Transaction>> normalTransactionsByDay = {};
    for (var transaction in normalTransactions) {
      int day = transaction.date.day;
      normalTransactionsByDay.putIfAbsent(day, () => []).add(transaction);
    }

    // **2. Gruppiere importierte Transaktionen nach Tagen**
    Map<int, List<ImportedTransaction>> importedTransactionsByDay = {};
    for (var transaction in importedTransactions) {
      int day = transaction.date.day;
      importedTransactionsByDay.putIfAbsent(day, () => []).add(transaction);
    }

    // **3. Berechnung der täglichen Werte**
    //double cumulativeNetAmount = lastMonthBalance;

    for (int day = 1; day <= endDate.day; day++) {
      double dayIncome = 0.0;
      double dayExpense = 0.0;

      // Normale Transaktionen verarbeiten
      if (normalTransactionsByDay.containsKey(day)) {
        for (var transaction in normalTransactionsByDay[day]!) {
          if (transaction.type == "Einnahme") {
            dayIncome += transaction.amount.abs();
          } else if (transaction.type == "Ausgabe") {
            dayExpense += transaction.amount.abs();
          }
        }
      }

      // Importierte Transaktionen verarbeiten
      if (importedTransactionsByDay.containsKey(day)) {
        for (var transaction in importedTransactionsByDay[day]!) {
          dayIncome += transaction.inflow > 0 ? transaction.inflow : 0;
          dayExpense += transaction.outflow.abs();
        }
      }

      if (type == "null") {
        cumulativeNetAmount += (dayIncome - dayExpense);
        monthlySpending[day - 1] = cumulativeNetAmount; // Liste ist 0-basiert
      } else if (type == "Einnahme") {
        monthlySpending[day - 1] = dayIncome;
      } else if (type == "Ausgabe") {
        monthlySpending[day - 1] = -dayExpense;
      }
    }


    return monthlySpending;
  }

  Future<List<ImportedTransaction>> getImportedTransactionsByDateRangeAndCategory(String documentId, String categoryId, DateTime startDate, DateTime endDate, String accountId) async {

    try {
      final userTransactionsRef =
      usersRef.doc(documentId).collection('ImportedTransactions');


      firestore.Query query = userTransactionsRef
          .where('date', isGreaterThanOrEqualTo: startDate.toIso8601String())
          .where('date', isLessThanOrEqualTo: endDate.toIso8601String());

      // Query ausführen
      firestore.QuerySnapshot snapshot = await query.get();

      List<ImportedTransaction> transactions = snapshot.docs
          .map((doc) =>
          ImportedTransaction.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();


      return transactions.where((transaction) {
        final matchesCategory = categoryId == "null" || transaction.categoryId == categoryId;
        final matchesAccount = accountId == "null" || transaction.accountId == accountId;
        return matchesCategory && matchesAccount;
      }).toList();
    } catch (e) {
      print("Error getting transactions by date range: $e");
      return [];
    }
  }

  Future<List<Transaction>> getTransactionsByDateRangeAndCategory(String documentId, String categoryId, DateTime startDate, DateTime endDate, String accountId) async {

    try {
      startDate = DateTime.utc(startDate.year, startDate.month, startDate.day, 0, 0, 0)
          .subtract(Duration(microseconds: 1)); // Startzeit auf 00:00 setzen
      endDate = DateTime(endDate.year, endDate.month, endDate.day + 1)
          .subtract(Duration(microseconds: 1)); // Endzeit auf den letzten Moment des Tages setzen


      final userTransactionsRef = usersRef.doc(documentId).collection('Transactions');


      firestore.Query query = userTransactionsRef
          .where('categoryId', isEqualTo: categoryId)
          .where('date', isGreaterThanOrEqualTo: startDate.toIso8601String())
          .where('date', isLessThanOrEqualTo: endDate.toIso8601String());


      if (accountId != "null" && accountId.isNotEmpty) {
        query = query.where('accountId', isEqualTo: accountId);
      }


      // Query ausführen
      firestore.QuerySnapshot snapshot = await query
          .orderBy('date', descending: true)
          .get();


      return snapshot.docs
          .map((doc) => Transaction.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      print("Error getting transactions by date range: $e");
      return [];
    }
  }

  Future<Map<int, double>> getCurrentMonthImportedTransactionsByDateRangeAndCategory(String documentId, String categoryId, String accountId) async {

    Map<int, double> monthlyCategoryValues = {};
    try{

      DateTime today = DateTime.now();
      DateTime usableToday = DateTime(today.year, today.month, today.day);
      DateTime startDate = DateTime(today.year, today.month, 1);


      List<ImportedTransaction> transactions = await getImportedTransactionsByDateRangeAndCategory(documentId, categoryId, startDate, usableToday, accountId);


      for (int day = 1; day <= usableToday.day; day++) {
        DateTime currentDay = DateTime(usableToday.year, usableToday.month, day).subtract(Duration(microseconds: 1));


        List<ImportedTransaction> dayTransactions = transactions.where((transaction) {
          return transaction.date.toUtc().year == currentDay.year &&
              transaction.date.toUtc().month == currentDay.month &&
              transaction.date.toUtc().day == currentDay.day;
        }).toList();



        double dayExpense = dayTransactions
            .where((transaction) => transaction.outflow != 0)
            .fold(0.0, (sum, transaction) => sum + sqrt(transaction.outflow * transaction.outflow));


        monthlyCategoryValues[day] = -dayExpense;
      }
    }  catch (e) {
    print("Fehler beim Abrufen der Monatsausgaben: $e");
    }
    return monthlyCategoryValues;
  }
  Future<Map<int, double>> getCurrentMonthTransactionsByDateRangeAndCategory(String documentId, String categoryId, String accountId) async {

    Map<int, double> monthlyCategoryValues = {};
    DateTime today = DateTime.now();
    DateTime usableToday = DateTime(today.year, today.month, today.day);
    DateTime startDate = DateTime(today.year, today.month, 1);


    List<Transaction> transactions = await getTransactionsByDateRangeAndCategory(documentId, categoryId, startDate, usableToday, accountId);

    for (int day = 1; day <= usableToday.day; day++) {
      DateTime currentDay = DateTime(usableToday.year, usableToday.month, day).subtract(Duration(microseconds: 1));


      List<Transaction> dayTransactions = transactions.where((transaction) {
        return transaction.date.toUtc().year == currentDay.year &&
            transaction.date.toUtc().month == currentDay.month &&
            transaction.date.toUtc().day == currentDay.day;
      }).toList();


      double dayExpense = 0.0;
      for (var transaction in dayTransactions) {
        if (transaction.type == "Ausgabe") {
          dayExpense += transaction.amount;
        }
      }


      monthlyCategoryValues[day] = dayExpense;
    }

    return monthlyCategoryValues;
  }

  Future<Map<int, double>> getCurrentMonthCombinedTransactionsByDateRangeAndCategory(
      String documentId, String categoryId, String accountId) async {

    Map<int, double> monthlyCategoryValues = {};

    DateTime today = DateTime.now();
    DateTime startDate = DateTime(today.year, today.month, 1);

    try {

      List<Transaction> transactions = await getTransactionsByDateRangeAndCategory(documentId, categoryId, startDate, today, accountId);
      List<ImportedTransaction> importedTransactions = await getImportedTransactionsByDateRangeAndCategory(documentId, categoryId, startDate, today, accountId);


      Map<int, double> dailyExpenses = {};


      for (var transaction in transactions) {
        if (transaction.type == "Ausgabe") {
          int day = transaction.date.day;
          dailyExpenses.update(day, (value) => value + transaction.amount, ifAbsent: () => transaction.amount);
        }
      }

      for (var transaction in importedTransactions) {
        int day = transaction.date.day;
        double amount = transaction.outflow.abs();
        dailyExpenses.update(day, (value) => value - amount, ifAbsent: () => -amount);
      }


      for (int day = 1; day <= today.day; day++) {
        monthlyCategoryValues[day] = dailyExpenses[day] ?? 0.0;
      }

    } catch (e) {
      print("Fehler beim Abrufen der Monatsausgaben: $e");
    }


    return monthlyCategoryValues;
  }

  Future<Map<int, double>> calculateYearlyCategoryImportedExpenses(String documentId, String categoryId, String chosenYear, String accountId) async {

    Map<int, double> monthlyCategoryExpenses = {};
    try {
      for (int month = 1; month <= 12; month++) {

        DateTime startDate = DateTime.utc(int.parse(chosenYear), month, 1);
        DateTime endDate = DateTime.utc(int.parse(chosenYear), month + 1, 1)
            .subtract(Duration(days: 1));


        List<ImportedTransaction> monthTransactions = await getImportedTransactionsByDateRangeAndCategory(documentId, categoryId, startDate, endDate, accountId);


        double monthExpense = monthTransactions
            .where((transaction) => transaction.outflow.abs() != 0)
            .fold(0.0, (sum, transaction) => sum + transaction.outflow.abs());

        monthlyCategoryExpenses[month] = -monthExpense;
      }
    } catch (e) {
      print("Fehler beim Berechnen der monatlichen Ausgaben: $e");
    }
    return monthlyCategoryExpenses;
  }

  Future<Map<int, double>> calculateYearlyCategoryExpenses(String documentId, String categoryId, String chosenYear, String accountId) async {

    Map<int, double> monthlyCategoryExpenses = {};

    for (int month = 1; month <= 12; month++) {
      DateTime startDate = DateTime.utc(int.parse(chosenYear), month, 1);
      DateTime endDate = DateTime.utc(int.parse(chosenYear), month + 1, 1)
          .subtract(Duration(days: 1));


      List<Transaction> monthTransactions = await getTransactionsByDateRangeAndCategory(documentId, categoryId, startDate, endDate, accountId);


      double monthExpense = 0.0;
      for (var transaction in monthTransactions) {
        if (transaction.type == "Ausgabe") {
          monthExpense += transaction.amount;
        }
      }

      monthlyCategoryExpenses[month] = monthExpense;
    }

    return monthlyCategoryExpenses;
  }

  Future<Map<int, double>> calculateYearlyCombinedCategoryExpenses(String documentId, String categoryId, String chosenYear, String accountId) async {

    Map<int, double> monthlyCategoryExpenses = {};

    try {
      DateTime startDate = DateTime.utc(int.parse(chosenYear), 1, 1);
      DateTime endDate = DateTime.utc(int.parse(chosenYear), 12, 31);

      List<Transaction> regularTransactions = await getTransactionsByDateRangeAndCategory(documentId, categoryId, startDate, endDate, accountId);
      List<ImportedTransaction> importedTransactions = await getImportedTransactionsByDateRangeAndCategory(documentId, categoryId, startDate, endDate, accountId);


      Map<int, double> monthlyExpenses = {};


      for (var transaction in regularTransactions) {
        if (transaction.type == "Ausgabe") {
          int month = transaction.date.month;
          monthlyExpenses.update(month, (value) => value + transaction.amount, ifAbsent: () => transaction.amount);
        }
      }

      for (var transaction in importedTransactions) {
        int month = transaction.date.month;
        double amount = transaction.outflow.abs();
        monthlyExpenses.update(month, (value) => value - amount, ifAbsent: () => -amount);
      }

      for (int month = 1; month <= 12; month++) {
        monthlyCategoryExpenses[month] = monthlyExpenses[month] ?? 0.0;
      }

    } catch (e) {
      print("Fehler beim Berechnen der jährlichen kombinierten Ausgaben: $e");
    }
    return monthlyCategoryExpenses;
  }




  Future<List<Category>> getUserCategoriesWithBudget(String documentId) async {

    try {
      final userCategoriesRef = usersRef.doc(documentId).collection('Categories');
      firestore.QuerySnapshot snapshot = await userCategoriesRef.get();

      return snapshot.docs.map((doc) {
        try {
          Category category = Category.fromMap(doc.data() as Map<String, dynamic>, doc.id);

          if (category.budgetLimit != null && category.budgetLimit! > 0) {
            return category;
          } else {
            return null;
          }
        } catch (e) {
          print("Error parsing category: $e");

          return null;
        }
      }).whereType<Category>().toList();
    } catch (e) {
      print("Error getting user categories: $e");
      return [];
    }
  }
  Future<double> getCurrentMonthCombinedTransactions(String documentId, String categoryId, String accountId) async {

    double totalExpense = 0.0;
    DateTime now = DateTime.now();
    DateTime startOfMonth = DateTime.utc(now.year, now.month, 1);
    DateTime endOfMonth = DateTime.utc(now.year, now.month + 1, 0);

    try {
      List<Transaction> transactions = await getTransactionsByDateRangeAndCategory(
          documentId, categoryId, startOfMonth, endOfMonth, accountId);


      List<ImportedTransaction> importedTransactions = await getImportedTransactionsByDateRangeAndCategory(
          documentId, categoryId, startOfMonth, endOfMonth, accountId);

      totalExpense -= transactions.fold(0.0, (sum, transaction) {
        return sum + (transaction.type == "Ausgabe" ? transaction.amount : 0.0);
      });
      totalExpense += importedTransactions.fold(0.0, (sum, transaction) {
        return sum + transaction.outflow.abs();
      });
    } catch (e) {
      print("Fehler beim Abrufen der kombinierten Transaktionen: $e");
    }
    print(totalExpense);
    return totalExpense;
  }


  Future<void> createNotification(String userId, String message, String type, {String? categoryId, String? accountId}) async {
    try {
      final userNotificationsRef = usersRef.doc(userId).collection('notifications');

      // Notification-Dokument erstellen
      firestore.DocumentReference docRef = await userNotificationsRef.add({
        'message': message,
        'isRead': false,
        'timestamp': firestore.FieldValue.serverTimestamp(),
        'categoryId': categoryId,
        'accountId': accountId,
        'type': type, // NEU: Typ der Benachrichtigung speichern
      });

      print("Notification erstellt: $message (Type: $type) - ID: ${docRef.id}");
    } catch (e) {
      print("Fehler beim Erstellen der Notification: $e");
    }
  }


  /*Future<List<Map<String, dynamic>>> getUserNotifications(String userId) async {
    try {
      final userNotificationsRef = usersRef.doc(userId).collection('notifications');
      firestore.QuerySnapshot snapshot = await userNotificationsRef
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        };
      }).toList();
    } catch (e) {
      print("Fehler beim Abrufen der Notifications: $e");
      return [];
    }
  }*/

  Future<void> markNotificationAsRead(String userId, String notificationId) async {
    try {
      final notificationRef = usersRef.doc(userId).collection('notifications').doc(notificationId);
      await notificationRef.update({'isRead': true});
      print("Notification $notificationId als gelesen markiert.");
    } catch (e) {
      print("Fehler beim Aktualisieren der Notification: $e");
    }
  }


  Future<void> deleteNotification(String userId, String categoryId, String type) async {
    try {
      final notificationsRef = usersRef.doc(userId).collection('notifications');
      final querySnapshot = await notificationsRef
          .where("categoryId", isEqualTo: categoryId)
          .where("type", isEqualTo: type)
          .get();

      if (querySnapshot.docs.isEmpty) {
        print("Keine passende Benachrichtigung gefunden zum Löschen.");
        return;
      }
      for (var doc in querySnapshot.docs) {
        await doc.reference.delete();
        print("Benachrichtigung gelöscht: ${doc.id}");
      }

      print("Alle relevanten Benachrichtigungen erfolgreich gelöscht.");
    } catch (e) {
      print("Fehler beim Löschen der Benachrichtigung: $e");
    }
  }



  Future<bool> doesNotificationExist(String userId, String categoryId, String type) async {

    try {
      final notificationsRef = usersRef.doc(userId).collection('notifications');
      DateTime now = DateTime.now();
      DateTime firstDayOfMonth = DateTime(now.year, now.month, 1);

      final querySnapshot = await notificationsRef
          .where('categoryId', isEqualTo: categoryId)
          .where('type', isEqualTo: type)
          .limit(1)
          .get();


      final existingNotifications = querySnapshot.docs.where((doc) {
        DateTime timestamp = (doc['timestamp'] as firestore.Timestamp).toDate();
        return timestamp.isAfter(firstDayOfMonth);
      }).toList();


      return existingNotifications.isNotEmpty;
    } catch (e) {
      print("Fehler beim Überprüfen der Benachrichtigung ($type): $e");
      return false;
    }
  }

  Stream<int> getUnreadNotificationsCount(String userId) {

    return usersRef
        .doc(userId)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Stream<List<Map<String, dynamic>>> getUserNotificationsStream(String userId) {
    return usersRef
        .doc(userId)
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      DateTime now = DateTime.now();
      DateTime firstDayOfMonth = DateTime(now.year, now.month, 1);

      return snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
          .where((notification) {
        DateTime timestamp = (notification['timestamp'] as firestore.Timestamp).toDate();
        return timestamp.isAfter(firstDayOfMonth);
      })
          .toList();
    });
  }

  Future<void> _checkAndHandleBudgetNotifications(
      String userId, String categoryId, double totalSpentBefore, double totalSpentAfter) async {

    Category? category = await getCategory(userId, categoryId);
    double? budgetLimit = category?.budgetLimit;

    if (budgetLimit == null || budgetLimit == 0) return;

    if (totalSpentBefore > budgetLimit && totalSpentAfter <= budgetLimit) {
      /*bool alreadyExists = await doesNotificationExist(userId, categoryId, "budget_overflow");

      if (alreadyExists) {
        await deleteNotification(userId, categoryId, "budget_overflow");
      }*/

      await createNotification(
        userId,
        "Budgetlimit für ${category!.name} wieder eingehalten um ${(totalSpentAfter - budgetLimit).abs().toStringAsFixed(2)}€!",
        "budget_nomore_overflow",
        categoryId: categoryId,
      );
    }

    else if (totalSpentBefore <= budgetLimit && totalSpentAfter > budgetLimit) {
      bool alreadyExists = await doesNotificationExist(userId, categoryId, "budget_overflow");

      //if (!alreadyExists) {
        await createNotification(
          userId,
          "Budgetlimit für ${category!.name} überschritten um ${(totalSpentAfter - budgetLimit).toStringAsFixed(2)}€!",
          "budget_overflow",
          categoryId: categoryId,
        );
      //}
    }

    else if (totalSpentBefore > budgetLimit && totalSpentAfter > budgetLimit) {
      await createNotification(
        userId,
        "Budgetlimit für ${category!.name} weiterhin überschritten um ${(totalSpentAfter - budgetLimit).toStringAsFixed(2)}€!",
        "budget_still_overflow",
        categoryId: categoryId,
      );
    }
  }

  Future<void> _checkAndHandleBalanceNotifications(
      String userId, double totalBalanceBefore, double totalBalanceAfter, String accountId, BankAccount bankA) async {

    if (totalBalanceBefore >= 0 && totalBalanceAfter < 0) {
        await createNotification(
          userId,
          "Achtung! Kontostand für '${bankA.accountName}' bei ${totalBalanceAfter.toStringAsFixed(2)}€!",
          "balance_low",
          accountId: accountId,
        );
    }

    else if (totalBalanceBefore < 0 && totalBalanceAfter < 0) {


        await createNotification(
          userId,
          "Warnung! Kontostand für '${bankA.accountName}' weiterhin negativ: ${totalBalanceAfter.toStringAsFixed(2)}€!",
          "balance_still_low",
          accountId: accountId,
        );

    }

    /*else if (totalBalanceBefore < 0 && totalBalanceAfter >= 0) {
      await createNotification(
        userId,
        "Gute Nachrichten! Kontostand wieder positiv: ${totalBalanceAfter.toStringAsFixed(2)}€.",
        "balance_recovered",
        accountId: accountId,
      );
    }*/
  }





  Future<Map<String, dynamic>> fetchCategoriesAndTransactions(String userId) async {
    List<Category> userCategories = await getUserCategoriesWithBudget(userId);

    if (userCategories.isEmpty) {
      return {"categories": [], "spentAmounts": []};
    }

    List<Future<double>> transactionFutures = userCategories.map((category) {
      return getCurrentMonthCombinedTransactions(
        userId,
        category.id!,
        "null",
      );
    }).toList();

    List<double> spentAmounts = await Future.wait(transactionFutures);

    return {
      "categories": userCategories,
      "spentAmounts": spentAmounts,
    };
  }
}

