/**
 * This class represents a user's bank account. It stores information
 * such as ID, user ID, account name, balance, last updated date, account type,
 * and an "exclude" flag to indicate if the account should be excluded from calculations.
 *
 * @author Ahmad
 */

class BankAccount {
  String? id; // Make id nullable to handle creation scenario
  final String userId;
  final String accountName;
  final double balance;
  final DateTime lastUpdated;
  final String accountType;
  final bool exclude;

  BankAccount({
    required this.userId,
    required this.accountName,
    required this.balance,
    required this.lastUpdated,
    required this.accountType,
    required this.exclude
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'accountName': accountName,
      'balance': balance.toString(),
      'lastUpdated': lastUpdated.toIso8601String(),
      'accountType': accountType,
      'exclude' : exclude
    };
  }

  static BankAccount fromMap(Map<String, dynamic> data, String documentId) {
    return BankAccount(
      userId: data['userId'],
      accountName: data['accountName'],
      lastUpdated: DateTime.parse(data['lastUpdated']),
      balance: double.parse(data['balance']),
      accountType: data['accountType'],
      exclude: data['exclude']
    )..id = documentId; // Assign the document ID after creation
  }
}
