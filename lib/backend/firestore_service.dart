import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:budget_management_app/backend/User.dart';
import 'package:budget_management_app/backend/Transaction.dart';
import 'package:budget_management_app/backend/Category.dart';
import 'package:budget_management_app/backend/BankAccount.dart';
import 'package:budget_management_app/backend/Subscriptions.dart';

class FirestoreService {
  final firestore.FirebaseFirestore _db = firestore.FirebaseFirestore.instance;

  // Collection references
  final firestore.CollectionReference usersRef = firestore.FirebaseFirestore.instance.collection('Users');
  final firestore.CollectionReference bankAccountsRef = firestore.FirebaseFirestore.instance.collection('bankAccounts');
  final firestore.CollectionReference categoriesRef = firestore.FirebaseFirestore.instance.collection('Categories');
  final firestore.CollectionReference transactionsRef = firestore.FirebaseFirestore.instance.collection('Transactions');
  final firestore.CollectionReference subscriptionsRef = firestore.FirebaseFirestore.instance.collection("Subscriptions");

  // =======================
  //  User Functions
  // =======================

  Future<void> createUser(User user) async {
    await usersRef.doc(user.id).set(user.toMap());
  }

  Future<User?> getUser(String userId) async {
    firestore.DocumentSnapshot snapshot = await usersRef.doc(userId).get();
    if (snapshot.exists) {
      return User.fromMap(snapshot.data() as Map<String, dynamic>, snapshot.id);
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

  Future<void> createBankAccount(BankAccount account) async {
    await bankAccountsRef.doc(account.id).set(account.toMap());
  }

  Future<BankAccount?> getBankAccount(String accountId) async {
    firestore.DocumentSnapshot snapshot = await bankAccountsRef.doc(accountId).get();
    if (snapshot.exists) {
      return BankAccount.fromMap(snapshot.data() as Map<String, dynamic>, snapshot.id);
    }
    return null;
  }

  Future<List<BankAccount>> getUserBankAccounts(String userId) async {
    firestore.QuerySnapshot snapshot = await bankAccountsRef.where('userId', isEqualTo: userId).get();
    return snapshot.docs.map((doc) => BankAccount.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
  }

  Future<void> updateBankAccount(BankAccount account) async {
    await bankAccountsRef.doc(account.id).update(account.toMap());
  }

  Future<void> deleteBankAccount(String accountId) async {
    await bankAccountsRef.doc(accountId).delete();
  }

  // =======================
  //  Category Functions
  // =======================

  Future<void> createCategory(Category category) async {
    await categoriesRef.doc(category.id).set(category.toMap());
  }

  Future<List<Category>> getDefaultCategories() async {
    firestore.QuerySnapshot snapshot = await categoriesRef.where('isDefault', isEqualTo: true).get();
    return snapshot.docs.map((doc) => Category.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
  }

  Future<List<Category>> getUserCategories(String userId) async {
    firestore.QuerySnapshot snapshot = await categoriesRef.where('userId', isEqualTo: userId).get();
    return snapshot.docs.map((doc) => Category.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
  }

  Future<void> updateCategory(Category category) async {
    await categoriesRef.doc(category.id).update(category.toMap());
  }

  Future<void> deleteCategory(String categoryId) async {
    await categoriesRef.doc(categoryId).delete();
  }

  // =======================
  //  Transaction Functions
  // =======================

  Future<void> createTransaction(Transaction transaction) async {
    await transactionsRef.doc(transaction.id).set(transaction.toMap());
  }

  Future<List<Transaction>> getUserTransactions(String userId) async {
    firestore.QuerySnapshot snapshot = await transactionsRef
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true) // Latest on top
        .get();
    return snapshot.docs.map((doc) => Transaction.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
  }

  Future<List<Transaction>> getTransactionsByCategory(String userId, String categoryId) async {
    firestore.QuerySnapshot snapshot = await transactionsRef
        .where('userId', isEqualTo: userId)
        .where('categoryId', isEqualTo: categoryId)
        .orderBy('date', descending: true)
        .get();
    return snapshot.docs.map((doc) => Transaction.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
  }

  Future<void> updateTransaction(Transaction transaction) async {
    await transactionsRef.doc(transaction.id).update(transaction.toMap());
  }

  Future<void> deleteTransaction(String transactionId) async {
    await transactionsRef.doc(transactionId).delete();
  }

  // =======================
  //  Subscription Functions
  // =======================

  Future<void> createSubscription(Subscription subscription) async {
    await subscriptionsRef.doc(subscription.id).set(subscription.toMap());
  }

  Future<List<Subscription>> getUserSubscriptions(String userId) async {
    firestore.QuerySnapshot snapshot = await subscriptionsRef
        .where('userId', isEqualTo: userId)
        .get();
    return snapshot.docs.map((doc) => Subscription.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
  }

  Future<void> updateSubscription(Subscription subscription) async {
    await subscriptionsRef.doc(subscription.id).update(subscription.toMap());
  }

  Future<void> deleteSubscription(String subscriptionId) async {
    await subscriptionsRef.doc(subscriptionId).delete();
  }

  // =======================
  //  Summary and Utility Functions
  // =======================

  Future<double> calculateTotalBalance(String userId) async {
    List<Transaction> transactions = await getUserTransactions(userId);
    double totalBalance = 0.0;
    for (var transaction in transactions) {
      totalBalance += transaction.amount;
    }
    return totalBalance;
  }

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
}
