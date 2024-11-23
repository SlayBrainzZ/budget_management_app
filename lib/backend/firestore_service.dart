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

  /// Retrieves a user from Firestore by their user ID.
  ///
  /// This function takes a `userId` as input and retrieves the corresponding user document from the
  /// `users` collection.

  Future<User?> getUser(String userId) async {
    firestore.QuerySnapshot snapshot = await usersRef.where('userId', isEqualTo: userId).get();
    if (snapshot.docs.isNotEmpty) {
      return User.fromMap(snapshot.docs.first.data() as Map<String, dynamic>, snapshot.docs.first.id);
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

  Future<void> createBankAccount(User user, BankAccount account) async {
    try {
      final userBankAccountsRef = usersRef.doc(user.id).collection('bankAccounts');
      firestore.DocumentReference docRef = await userBankAccountsRef.add(account.toMap());
      account.id = docRef.id;
      await docRef.set(account.toMap());
    } catch (e) {
      print("Error creating bank account: $e");
    }
  }

  /// Retrieves a bank account from Firestore by its account ID.
  ///
  /// This function takes an `accountId` as input and retrieves the corresponding bank account document from the
  /// `bankAccounts` collection.

  Future<BankAccount?> getBankAccount(User user, String accountId) async {
    try {
      final userBankAccountsRef = usersRef.doc(user.id).collection('bankAccounts');
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

  /// Retrieves all bank accounts for a specific user.
  ///
  /// This function takes a `userId` as input and retrieves all bank account documents from the `bankAccounts`
  /// collection that belong to that user.

  Future<List<BankAccount>> getUserBankAccounts(String userId) async {
    try {
      final userBankAccountsRef = usersRef.doc(userId).collection('bankAccounts');
      firestore.QuerySnapshot snapshot = await userBankAccountsRef.get();
      return snapshot.docs.map((doc) => BankAccount.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
    } catch (e) {
      print("Error getting user bank accounts: $e");
      return [];
    }
  }

  /// Updates an existing bank account in Firestore.
  ///
  /// This function takes a `BankAccount` object as input and updates the corresponding bank account document in the
  /// `bankAccounts` collection.

  Future<void> updateBankAccount(User user, BankAccount account) async {
    try {
      final userBankAccountsRef = usersRef.doc(user.id).collection('bankAccounts');
      await userBankAccountsRef.doc(account.id).update(account.toMap());
    } catch (e) {
      print("Error updating bank account: $e");
    }
  }

  /// Deletes a bank account from Firestore.
  ///
  /// This function takes an `accountId` as input and deletes the corresponding bank account document from the
  /// `bankAccounts` collection.

  Future<void> deleteBankAccount(User user, String accountId) async {
    try {
      final userBankAccountsRef = usersRef.doc(user.id).collection('bankAccounts');
      await userBankAccountsRef.doc(accountId).delete();
    } catch (e) {
      print("Error deleting bank account: $e");
    }
  }

  // =======================
  //  Category Functions
  // =======================

  /// Creates a new category in Firestore.
  ///
  /// This function takes a `Category` object as input and adds it to the `categories` collection.

  Future<void> createCategory(User user, Category category) async {
    try {
      final userCategoriesRef = usersRef.doc(user.id).collection('Categories');
      firestore.DocumentReference docRef = await userCategoriesRef.add(category.toMap());
      category.id = docRef.id;
      await docRef.set(category.toMap());
    } catch (e) {
      print("Error creating category: $e");
    }
  }

  /// Retrieves a list of default categories from Firestore.
  ///
  /// This function retrieves all category documents from the `categories` collection that are marked as default.

  Future<List<Category>> getDefaultCategories() async {
    firestore.QuerySnapshot snapshot = await _db.collectionGroup('Categories').where('isDefault', isEqualTo: true).get();
    return snapshot.docs.map((doc) => Category.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
  }

  /// Retrieves a category from Firestore by its category ID.
  ///
  /// This function takes a `categoryId` as input and retrieves the corresponding category document from the
  /// `categories` collection.

  Future<Category?> getCategory(User user, String categoryId) async {
    try {
      final userCategoriesRef = usersRef.doc(user.id).collection('Categories');
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


  /// Retrieves all categories for a specific user.
  ///
  /// This function takes a `userId` as input and retrieves all category documents from the `categories`
  /// collection that belong to that user.

  Future<List<Category>> getUserCategories(String userId) async {
    try {
      final userCategoriesRef = usersRef.doc(userId).collection('Categories');
      final querySnapshot = await userCategoriesRef.get();
      return querySnapshot.docs.map((doc) => Category.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
    } catch (e) {
      print("Error getting user categories: $e");
      return [];
    }
  }

  /// Updates an existing category in Firestore.
  ///
  /// This function takes a `Category` object as input and updates the corresponding category document in the
  /// `categories` collection.

  Future<void> updateCategory(User user, Category category) async {
    try {
      final userCategoriesRef = usersRef.doc(user.id).collection('Categories');
      await userCategoriesRef.doc(category.id).update(category.toMap());
    } catch (e) {
      print("Error updating category: $e");
    }
  }

  /// Deletes a category from Firestore.
  ///
  /// This function takes a `categoryId` as input and deletes the corresponding category document from the
  /// `categories` collection. It also deletes all transactions associated with the category.

  Future<void> deleteCategory(User user, String categoryId) async {
    try {
      // 1. Delete transactions belonging to the category (within the user's scope)
      final userTransactionsRef = usersRef.doc(user.id).collection('Transactions');
      final transactionsQuery = await userTransactionsRef.where('categoryId', isEqualTo: categoryId).get();
      for (var doc in transactionsQuery.docs) {
        await doc.reference.delete();
      }

      // 2. Delete the category
      final userCategoriesRef = usersRef.doc(user.id).collection('Categories');
      await userCategoriesRef.doc(categoryId).delete();
    } catch (e) {
      print("Error deleting category: $e");
    }
  }

  // =======================
  //  Transaction Functions
  // =======================

  /// Creates a new transaction in Firestore.
  ///
  /// This function takes a `Transaction` object as input and adds it to the `transactions` collection.

  Future<void> createTransaction(User user, Transaction transaction) async {
    try {
      final userTransactionsRef = usersRef.doc(user.id).collection('Transactions');

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
  /// This function takes a `userId` as input and retrieves all transaction documents from the `transactions` collection
  /// that belong to that user. The results are ordered by date with the latest transaction appearing first.

  Future<List<Transaction>> getUserTransactions(String userId) async {
    try {
      final userTransactionsRef = usersRef.doc(userId).collection('Transactions');
      firestore.QuerySnapshot snapshot = await userTransactionsRef
          .orderBy('date', descending: true)
          .get();
      return snapshot.docs.map((doc) => Transaction.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
    } catch (e) {
      print("Error getting user transactions: $e");
      return [];
    }
  }

  /// Retrieves a transaction from Firestore by its transaction ID.
  ///
  /// This function takes a `transactionId` as input and retrieves the corresponding transaction document from the
  /// `transactions` collection.

  Future<Transaction?> getTransaction(User user, String transactionId) async {
    try {
      final userTransactionsRef = usersRef.doc(user.id).collection('Transactions');
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
  /// This function takes a `userId` and a `categoryId` as input and retrieves all transaction documents from the
  /// `transactions` collection that belong to that user and belong to the specified category.
  /// The results are ordered by date with the latest transaction appearing first.

  Future<List<Transaction>> getTransactionsByCategory(String userId, String categoryId) async {
    try {
      final userTransactionsRef = usersRef.doc(userId).collection('Transactions');
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

  /// Updates an existing transaction in Firestore.
  ///
  /// This function takes a `Transaction` object as input and updates the corresponding transaction document
  /// in the `transactions` collection.

  Future<void> updateTransaction(User user, Transaction transaction) async {
    try {
      final userTransactionsRef = usersRef.doc(user.id).collection('Transactions');
      await userTransactionsRef.doc(transaction.id).update(transaction.toMap());
    } catch (e) {
      print("Error updating transaction: $e");
    }
  }

  /// Deletes a transaction from Firestore.
  ///
  /// This function takes a `transactionId` as input and deletes the corresponding transaction document from the `transactions` collection.

  Future<void> deleteTransaction(User user, String transactionId) async {
    try {
      final userTransactionsRef = usersRef.doc(user.id).collection('Transactions');
      await userTransactionsRef.doc(transactionId).delete();
    } catch (e) {
      print("Error deleting transaction: $e");
    }
  }

  // =======================
  //  Subscription Functions
  // =======================

  /// Creates a new subscription in Firestore.
  ///
  /// This function takes a `Subscription` object as input and adds it to the `subscriptions` collection.

  Future<void> createSubscription(User user, Subscription subscription) async {
    try {
      final userSubscriptionsRef = usersRef.doc(user.id).collection('Subscriptions');
      firestore.DocumentReference docRef = await userSubscriptionsRef.add(subscription.toMap());
      subscription.id = docRef.id;
      await docRef.set(subscription.toMap());
    } catch (e) {
      print("Error creating subscription: $e");
    }
  }

  /// Retrieves all subscriptions for a specific user.
  ///
  /// This function takes a `userId` as input and retrieves all subscription documents from the
  /// `subscriptions` collection that belong to that user.

  Future<List<Subscription>> getUserSubscriptions(String userId) async {
    try {
      final userSubscriptionsRef = usersRef.doc(userId).collection('Subscriptions');
      firestore.QuerySnapshot snapshot = await userSubscriptionsRef.get();
      return snapshot.docs.map((doc) => Subscription.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
    } catch (e) {
      print("Error getting user subscriptions: $e");
      return [];
    }
  }

  /// Updates an existing subscription in Firestore.
  ///
  /// This function takes a `Subscription` object as input and updates the corresponding subscription
  /// document in the `subscriptions` collection.

  Future<void> updateSubscription(User user, Subscription subscription) async {
    try {
      final userSubscriptionsRef = usersRef.doc(user.id).collection('Subscriptions');
      await userSubscriptionsRef.doc(subscription.id).update(subscription.toMap());
    } catch (e) {
      print("Error updating subscription: $e");
    }
  }

  /// Deletes a subscription from Firestore.
  ///
  /// This function takes a `subscriptionId` as input and deletes the corresponding subscription
  /// document from the `subscriptions` collection.

  Future<void> deleteSubscription(User user, String subscriptionId) async {
    try {
      final userSubscriptionsRef = usersRef.doc(user.id).collection('Subscriptions');
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
  /// This function takes a `userId` as input and calculates the sum of all transaction amounts for that user.

  Future<double> calculateTotalBalance(User user) async {
    List<Transaction> transactions = await getUserTransactions(user.id!);
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

  Future<double> calculateCategorySpending(User user, String categoryId) async {
    List<Transaction> categoryTransactions = await getTransactionsByCategory(user.id!, categoryId);
    double totalSpending = 0.0;
    for (var transaction in categoryTransactions) {
      if (transaction.amount < 0) {
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

  Future<List<Transaction>> getTransactionsByDateRange(User user, DateTime startDate, DateTime endDate) async {
    try {
      final userTransactionsRef = usersRef.doc(user.id).collection('Transactions');
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
  /// This function takes a `userId` and a `year` as input and calculates the total spending
  /// for each month of the given year.

  Future<List<double>> calculateMonthlySpending(User user, int year) async {
    List<double> monthlySpending = List.filled(12, 0.0);
    for (int month = 1; month <= 12; month++) {
      DateTime startDate = DateTime(year, month, 1);
      DateTime endDate = DateTime(year, month, DateTime(year, month + 1, 0).day);
      List<Transaction> monthTransactions = await getTransactionsByDateRange(user, startDate, endDate);
      for (var transaction in monthTransactions) {
        if (transaction.amount < 0) {
          monthlySpending[month - 1] += transaction.amount;
        }
      }
    }
    return monthlySpending;
  }


}
