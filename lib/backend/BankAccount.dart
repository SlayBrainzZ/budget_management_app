class BankAccount {
  final String id;
  final String userId;
  final String bankName;
  final String? accountNumber;
  final double balance;
  final DateTime lastUpdated;
  final String accountType;

  BankAccount({
    required this.id,
    required this.userId,
    required this.bankName,
    this.accountNumber,
    required this.balance,
    required this.lastUpdated,
    required this.accountType,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'bankName': bankName,
      'accountNumber': accountNumber ?? '',
      'balance': balance,
      'lastUpdated': lastUpdated.toIso8601String(),
      'accountType': accountType,
    };
  }

  static BankAccount fromMap(Map<String, dynamic> data, String documentId) {
    return BankAccount(
      id: documentId,
      userId: data['userId'],
      bankName: data['bankName'],
      accountNumber: data['accountNumber'],
      balance: data['balance'],
      lastUpdated: DateTime.parse(data['lastUpdated']),
      accountType: data['accountType'],
    );
  }
}
