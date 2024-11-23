import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:budget_management_app/backend/User.dart';
import 'package:budget_management_app/backend/Transaction.dart';
import 'package:budget_management_app/backend/Category.dart';
import 'package:budget_management_app/backend/BankAccount.dart';
import 'package:budget_management_app/backend/Subscriptions.dart';


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
  /// and adds the category to the user's `Categories` subcollection.

  Future<void> createCategory(String documentId, Category category) async {
    try {
      final userCategoriesRef = usersRef.doc(documentId).collection('Categories');
      // Create the category and get its reference
      firestore.DocumentReference docRef = await userCategoriesRef.add(category.toMap());
      category.id = docRef.id;
      // Update the document to ensure the `id` field is saved
      await docRef.set(category.toMap());
    } catch (e) {
      print("Error creating category: $e");
    }
  }

  /// Retrieves a list of default categories from Firestore.
  ///
  /// This function retrieves all category documents with the field `isDefault` set to `true`
  /// from all `Categories` subcollections across all users.

  Future<List<Category>> getDefaultCategories() async {
    firestore.QuerySnapshot snapshot = await _db.collectionGroup('Categories').where('isDefault', isEqualTo: true).get();
    return snapshot.docs.map((doc) => Category.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
  }

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
  /// This function takes the user's `documentId` and a `Transaction` object as input,
  /// and adds the transaction to the user's `Transactions` subcollection.
  Future<void> createTransaction(String documentId, Transaction transaction) async {
    try {
      final userTransactionsRef = usersRef.doc(documentId).collection('Transactions');

      // If categoryId is provided, validate category existence (you might want to optimize this)
      if (transaction.categoryId != null) {
        final categorySnapshot = await userTransactionsRef.doc(transaction.categoryId).get();
        if (!categorySnapshot.exists) {
          throw Exception('Category not found!');
        }
      }

      firestore.DocumentReference docRef = await userTransactionsRef.add(transaction.toMap());
      transaction.id = docRef.id;
      await docRef.set(transaction.toMap());
    } catch (e) {
      print("Error creating transaction: $e");
    }
  }

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
