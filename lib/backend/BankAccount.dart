class BankAccount {
  final String id;
  final String userId;
  final String accountName;
  final double balance;
  final DateTime lastUpdated;
  final String accountType;
  final bool exclude;

  BankAccount({
    required this.id,
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
      id: documentId,
      userId: data['userId'],
      accountName: data['accountName'],
      lastUpdated: DateTime.parse(data['lastUpdated']),
      balance: double.parse(data['balance']),
      accountType: data['accountType'],
      exclude: data['exclude']
    );
  }
}
