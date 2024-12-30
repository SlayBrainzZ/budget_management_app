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
  //String? importFilePath;

  BankAccount({
    this.id,
    required this.userId,
    this.accountName,
    this.balance,
    this.lastUpdated,
    required this.accountType,
    this.exclude = false,
    //this.importFilePath,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id, // Die ID hinzufügen
      'userId': userId,
      'accountName': accountName,
      'balance': balance?.toString(),
      'lastUpdated': lastUpdated?.toIso8601String(),
      'accountType': accountType,
      'exclude': exclude,
      //'importFilePath': importFilePath,
    };
  }

  static BankAccount fromMap(Map<String, dynamic> data, String id) {
    return BankAccount(
      id: id, // Use the provided Firestore document ID
      userId: data['userId'] ?? '', // Ensure a default empty string if missing
      accountName: data['accountName'], // Nullable, no change needed
      lastUpdated: data['lastUpdated'] != null
          ? DateTime.tryParse(data['lastUpdated']) // Safely parse the date
          : null, // Keep it null if missing
      balance: data['balance'] != null
          ? double.tryParse(data['balance']) ?? 0.0 // Parse or fallback to 0.0
          : 0.0,
      accountType: data['accountType'] ?? 'unknown', // Default account type
      exclude: data['exclude'] ?? false, // Default to `false` if missing
    );
  }
}
