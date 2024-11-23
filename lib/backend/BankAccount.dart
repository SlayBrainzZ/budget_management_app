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
  String? accountName;
  double? balance;
  DateTime? lastUpdated;
  final String accountType;
  bool exclude;
  String? importFilePath;

  BankAccount({
    required this.userId,
    this.accountName,
    this.balance,
    this.lastUpdated,
    required this.accountType,
    this.exclude = false,
    this.importFilePath,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'accountName': accountName,
      'balance': balance?.toString(),
      'lastUpdated': lastUpdated?.toIso8601String(),
      'accountType': accountType,
      'exclude' : exclude,
      'importFilePath': importFilePath,
    };
  }

  static BankAccount fromMap(Map<String, dynamic> data, String documentId) {
    return BankAccount(
      userId: data['userId'],
      accountName: data['accountName'],
      lastUpdated: data['lastUpdated'] != null ? DateTime.parse(data['lastUpdated']) : null,
      balance: data['balance'] != null ? double.parse(data['balance']) : null,
      accountType: data['accountType'],
      exclude: data['exclude'] ?? false,
      importFilePath: data['importFilePath'],
    )..id = documentId; // Assign the document ID after creation
  }
}
