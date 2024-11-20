import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:budget_management_app/backend/User.dart';
import 'package:budget_management_app/backend/Transaction.dart';
import 'package:budget_management_app/backend/Category.dart';
import 'package:budget_management_app/backend/BankAccount.dart';
import 'package:budget_management_app/backend/Subscriptions.dart';

/**
 *
 * This class provides a set of functions for interacting with the Firebase Firestore database.
 * It handles CRUD operations for users, bank accounts, categories, transactions, and subscriptions.
 * Additionally, it provides utility functions for data analysis and calculations.
 *
 * @author Ahmad
 */

class FirestoreService {
  final firestore.FirebaseFirestore _db = firestore.FirebaseFirestore.instance;

  /// Collection references
  final firestore.CollectionReference usersRef = firestore.FirebaseFirestore.instance.collection('Users');
  final firestore.CollectionReference bankAccountsRef = firestore.FirebaseFirestore.instance.collection('bankAccounts');
  final firestore.CollectionReference categoriesRef = firestore.FirebaseFirestore.instance.collection('Categories');
  final firestore.CollectionReference transactionsRef = firestore.FirebaseFirestore.instance.collection('Transactions');
  final firestore.CollectionReference subscriptionsRef = firestore.FirebaseFirestore.instance.collection("Subscriptions");
  final firestore.CollectionReference _categories = firestore.FirebaseFirestore.instance.collection('Categories');

  // =======================
  //  User Functions
  // =======================

  /// Creates a new user in Firestore.
  ///
  /// This function takes a `User` object as input and adds it to the `users` collection.

  Future<void> createUser(User user) async {
    firestore.DocumentReference docRef = await usersRef.add(user.toMap());
    user.id = docRef.id; // Assign generated ID to the user object
    await docRef.set(user.toMap()); // Update with complete data including ID
  }

  /// Retrieves a user from Firestore by their user ID.
  ///
  /// This function takes a `userId` as input and retrieves the corresponding user document from the
  /// `users` collection.

  Future<User?> getUser(String userId) async {
    firestore.DocumentSnapshot snapshot = await usersRef.doc(userId).get();
    if (snapshot.exists) {
      return User.fromMap(snapshot.data() as Map<String, dynamic>, snapshot.id);
    }
    return null;
  }

  /// Updates an existing user in Firestore.
  ///
  /// This function takes a `User` object as input and updates the corresponding user document in the
  /// `users` collection.

  Future<void> updateUser(User user) async {
    await usersRef.doc(user.id).update(user.toMap());
  }

  /// Deletes a user from Firestore.
  ///
  /// This function takes a `userId` as input and deletes the corresponding user document from the
  /// `users` collection.

  Future<void> deleteUser(String userId) async {
    await usersRef.doc(userId).delete();
  }

  // =======================
  //  Bank Account Functions
  // =======================

  /// Creates a new bank account in Firestore.
  ///
  /// This function takes a `BankAccount` object as input and adds it to the `bankAccounts` collection.

  Future<void> createBankAccount(BankAccount account) async {
    firestore.DocumentReference docRef = await bankAccountsRef.add(account.toMap());
    account.id = docRef.id; // Assign generated ID to the account object
    await docRef.set(account.toMap()); // Update with complete data including ID
  }

  /// Retrieves a bank account from Firestore by its account ID.
  ///
  /// This function takes an `accountId` as input and retrieves the corresponding bank account document from the
  /// `bankAccounts` collection.

  Future<BankAccount?> getBankAccount(String accountId) async {
    firestore.DocumentSnapshot snapshot = await bankAccountsRef.doc(accountId).get();
    if (snapshot.exists) {
      return BankAccount.fromMap(snapshot.data() as Map<String, dynamic>, snapshot.id);
    }
    return null;
  }

  /// Retrieves all bank accounts for a specific user.
  ///
  /// This function takes a `userId` as input and retrieves all bank account documents from the `bankAccounts`
  /// collection that belong to that user.

  Future<List<BankAccount>> getUserBankAccounts(String userId) async {
    firestore.QuerySnapshot snapshot = await bankAccountsRef.where('userId', isEqualTo: userId).get();
    return snapshot.docs.map((doc) => BankAccount.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
  }

  /// Updates an existing bank account in Firestore.
  ///
  /// This function takes a `BankAccount` object as input and updates the corresponding bank account document in the
  /// `bankAccounts` collection.

  Future<void> updateBankAccount(BankAccount account) async {
    await bankAccountsRef.doc(account.id).update(account.toMap());
  }

  /// Deletes a bank account from Firestore.
  ///
  /// This function takes an `accountId` as input and deletes the corresponding bank account document from the
  /// `bankAccounts` collection.

  Future<void> deleteBankAccount(String accountId) async {
    await bankAccountsRef.doc(accountId).delete();
  }

  // =======================
  //  Category Functions
  // =======================

  /// Creates a new category in Firestore.
  ///
  /// This function takes a `Category` object as input and adds it to the `categories` collection.

  Future<void> createCategory(Category category) async {
    firestore.DocumentReference docRef = await categoriesRef.add(category.toMap());
    category.id = docRef.id; // Assign generated ID to the category object
    await docRef.set(category.toMap()); // Update with complete data including ID
  }

  /// Retrieves a list of default categories from Firestore.
  ///
  /// This function retrieves all category documents from the `categories` collection that are marked as default.

  Future<List<Category>> getDefaultCategories() async {
    firestore.QuerySnapshot snapshot = await categoriesRef.where('isDefault', isEqualTo: true).get();
    return snapshot.docs.map((doc) => Category.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
  }

  /// Retrieves a category from Firestore by its category ID.
  ///
  /// This function takes a `categoryId` as input and retrieves the corresponding category document from the
  /// `categories` collection.

  Future<Category?> getCategory(String categoryId) async {
    try {
      final docRef = _categories.doc(categoryId);
      print("Getting category from document reference: $docRef");

      final docSnapshot = await docRef.get();
      print("Document snapshot exists: ${docSnapshot.exists}");

      if (docSnapshot.exists) {
        print("Document snapshot data: ${docSnapshot.data()}");
        return Category.fromMap(docSnapshot.data() as Map<String, dynamic>, docSnapshot.id);
      } else {
        print("Category document does not exist.");

        // Add this additional check
        final querySnapshot = await _categories.where('id', isEqualTo: categoryId).get();
        if (querySnapshot.docs.isNotEmpty) {
          print("Found category using where query: ${querySnapshot.docs.first.data()}");
          return Category.fromMap(querySnapshot.docs.first.data() as Map<String, dynamic>, querySnapshot.docs.first.id);
        } else {
          print("Category not found in where query either.");
          return null;
        }
      }
    } catch (e) {
      print("Error getting category: $e");
      return null;
    }
  }


  /// Retrieves all categories for a specific user.
  ///
  /// This function takes a `userId` as input and retrieves all category documents from the `categories`
  /// collection that belong to that user.

  Future<List<Category>> getUserCategories(String userId) async {
    firestore.QuerySnapshot snapshot = await categoriesRef.where('userId', isEqualTo: userId).get();
    return snapshot.docs.map((doc) => Category.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
  }

  /// Updates an existing category in Firestore.
  ///
  /// This function takes a `Category` object as input and updates the corresponding category document in the
  /// `categories` collection.

  Future<void> updateCategory(Category category) async {
    await categoriesRef.doc(category.id).update(category.toMap());
  }

  /// Deletes a category from Firestore.
  ///
  /// This function takes a `categoryId` as input and deletes the corresponding category document from the
  /// `categories` collection. It also deletes all transactions associated with the category.

  Future<void> deleteCategory(String categoryId) async {
    // 1. Fetch ALL transactions
    List<Transaction> allTransactions = await transactionsRef.get().then((snapshot) =>
        snapshot.docs.map((doc) => Transaction.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList()
    );

    // 2. Filter and delete transactions belonging to the category
    for (var transaction in allTransactions) {
      if (transaction.categoryId == categoryId) {
        await deleteTransaction(transaction.id!);
      }
    }

    // 3. Delete the category
    await categoriesRef.doc(categoryId).delete();
  }

  // =======================
  //  Transaction Functions
  // =======================

  /// Creates a new transaction in Firestore.
  ///
  /// This function takes a `Transaction` object as input and adds it to the `transactions` collection.

  Future<void> createTransaction(Transaction transaction) async {
    // If categoryId is provided, validate category existence
    if (transaction.categoryId != null) {
      Category? category = await getCategory(transaction.categoryId!);
      if (category == null) {
        throw Exception('Category not found!');
      }
    }
    // Create transaction
    firestore.DocumentReference docRef = await transactionsRef.add(transaction.toMap());
    transaction.id = docRef.id;
    await docRef.set(transaction.toMap());
  }

  /// Retrieves all transactions for a specific user, ordered by date (latest first).
  ///
  /// This function takes a `userId` as input and retrieves all transaction documents from the `transactions` collection
  /// that belong to that user. The results are ordered by date with the latest transaction appearing first.

  Future<List<Transaction>> getUserTransactions(String userId) async {
    firestore.QuerySnapshot snapshot = await transactionsRef
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true) // Latest on top
        .get();
    return snapshot.docs.map((doc) => Transaction.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
  }

  /// Retrieves a transaction from Firestore by its transaction ID.
  ///
  /// This function takes a `transactionId` as input and retrieves the corresponding transaction document from the
  /// `transactions` collection.

  Future<Transaction?> getTransaction(String transactionId) async {
    try {
      final docRef = transactionsRef.doc(transactionId);
      final docSnapshot = await docRef.get();

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
  /// This function takes a `userId` and a `categoryId` as input and retrieves all transaction documents from the
  /// `transactions` collection that belong to that user and belong to the specified category.
  /// The results are ordered by date with the latest transaction appearing first.

  Future<List<Transaction>> getTransactionsByCategory(String userId, String categoryId) async {
    firestore.QuerySnapshot snapshot = await transactionsRef
        .where('userId', isEqualTo: userId)
        .where('categoryId', isEqualTo: categoryId)
        .orderBy('date', descending: true)
        .get();
    return snapshot.docs.map((doc) => Transaction.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
  }

  /// Updates an existing transaction in Firestore.
  ///
  /// This function takes a `Transaction` object as input and updates the corresponding transaction document
  /// in the `transactions` collection.

  Future<void> updateTransaction(Transaction transaction) async {
    await transactionsRef.doc(transaction.id).update(transaction.toMap());
  }

  /// Deletes a transaction from Firestore.
  ///
  /// This function takes a `transactionId` as input and deletes the corresponding transaction document from the `transactions` collection.

  Future<void> deleteTransaction(String transactionId) async {
    await transactionsRef.doc(transactionId).delete();
  }

  // =======================
  //  Subscription Functions
  // =======================

  /// Creates a new subscription in Firestore.
  ///
  /// This function takes a `Subscription` object as input and adds it to the `subscriptions` collection.

  Future<void> createSubscription(Subscription subscription) async {
    firestore.DocumentReference docRef = await subscriptionsRef.add(subscription.toMap());
    subscription.id = docRef.id;
    await docRef.set(subscription.toMap());
  }

  /// Retrieves all subscriptions for a specific user.
  ///
  /// This function takes a `userId` as input and retrieves all subscription documents from the
  /// `subscriptions` collection that belong to that user.

  Future<List<Subscription>> getUserSubscriptions(String userId) async {
    firestore.QuerySnapshot snapshot = await subscriptionsRef
        .where('userId', isEqualTo: userId)
        .get();
    return snapshot.docs.map((doc) => Subscription.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
  }

  /// Updates an existing subscription in Firestore.
  ///
  /// This function takes a `Subscription` object as input and updates the corresponding subscription
  /// document in the `subscriptions` collection.

  Future<void> updateSubscription(Subscription subscription) async {
    await subscriptionsRef.doc(subscription.id).update(subscription.toMap());
  }

  /// Deletes a subscription from Firestore.
  ///
  /// This function takes a `subscriptionId` as input and deletes the corresponding subscription
  /// document from the `subscriptions` collection.

  Future<void> deleteSubscription(String subscriptionId) async {
    await subscriptionsRef.doc(subscriptionId).delete();
  }

  // =======================
  //  Summary and Utility Functions
  // =======================

  /// Calculates the total balance for a specific user based on their transactions.
  ///
  /// This function takes a `userId` as input and calculates the sum of all transaction amounts for that user.

  Future<double> calculateTotalBalance(String userId) async {
    List<Transaction> transactions = await getUserTransactions(userId);
    double totalBalance = 0.0;
    for (var transaction in transactions) {
      totalBalance += transaction.amount;
    }
    return totalBalance;
  }

  /// Calculates the total spending for a specific user and category.
  ///
  /// This function takes a `userId` and a `categoryId` as input and calculates the sum of all expense amounts
  /// for that user within the specified category.

  Future<double> calculateCategorySpending(String userId, String categoryId) async {
    List<Transaction> categoryTransactions = await getTransactionsByCategory(userId, categoryId);
    double totalSpending = 0.0;
    for (var transaction in categoryTransactions) {
      if (transaction.amount < 0) { // assuming negative amount for expenses
        totalSpending += transaction.amount;
      }
    }
    return totalSpending;
  }

  /// Gets transactions within a specific date range.
  ///
  /// This function takes a `userId`, a `startDate`, and an `endDate` as input and retrieves all
  /// transaction documents from the `transactions` collection that belong to the specified user
  /// and fall within the given date range.

  Future<List<Transaction>> getTransactionsByDateRange(String userId, DateTime startDate, DateTime endDate) async {
    firestore.QuerySnapshot snapshot = await transactionsRef
        .where('userId', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: startDate)
        .where('date', isLessThanOrEqualTo: endDate)
        .orderBy('date', descending: true)
        .get();
    return snapshot.docs.map((doc) => Transaction.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
  }

  /// Calculates monthly spending for a given user.
  ///
  /// This function takes a `userId` and a `year` as input and calculates the total spending
  /// for each month of the given year.

  Future<List<double>> calculateMonthlySpending(String userId, int year) async {
    List<double> monthlySpending = List.filled(12, 0.0);
    for (int month = 1; month <= 12; month++) {
      DateTime startDate = DateTime(year, month, 1);
      DateTime endDate = DateTime(year, month, DateTime(year, month + 1, 0).day);
      List<Transaction> monthTransactions = await getTransactionsByDateRange(userId, startDate, endDate);
      for (var transaction in monthTransactions) {
        if (transaction.amount < 0) {
          monthlySpending[month - 1] += transaction.amount;
        }
      }
    }
    return monthlySpending;
  }

}
