import 'BankAccount.dart';
import 'Category.dart';

class ImportedTransaction {
  
  String? id;
  final String userId;
  String? categoryId;
  double amount;
  final DateTime date;
  final String description;  // Description of the transaction (Buchungstext)
  final String payerOrRecipient;  // The payer or recipient (Auftraggeber/Empfänger)
  final double outflow;  // Amount for outgoing transactions (Ausgang)
  final double inflow;   // Amount for incoming transactions (Eingang)
  String? accountId;
  BankAccount? linkedAccount;
  Category? categoryData;


  ImportedTransaction({
    required this.userId,
    required this.amount,
    required this.date,
    required this.payerOrRecipient,
    required this.description,
    required this.outflow,
    required this.inflow,
    this.accountId, // Optional account link
    this.categoryId, // Optional category link
    this.linkedAccount, //
    this.categoryData,
  });

  // Map to Firestore representation
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'amount': amount.toString(),
      'date': date.toIso8601String(),
      'categoryId': categoryId ?? null, // Pass null if undefined
      'description': description,
      'payerOrRecipient': payerOrRecipient,
      'outflow': outflow,
      'inflow': inflow,
      'accountId': accountId,
    };
  }

  // Factory method to create an ImportedTransaction from a Map
  // Also ensures that any unexpected missing or null data doesn’t break the app.
  static ImportedTransaction fromMap(Map<String, dynamic> data, String documentId) {
    return ImportedTransaction(
      userId: data['userId'] ?? '',
      amount: double.tryParse(data['amount']?.toString() ?? '0.0') ?? 0.0,
      date: DateTime.tryParse(data['date']?.toString() ?? DateTime.now().toIso8601String()) ?? DateTime.now(),
      payerOrRecipient: data['payerOrRecipient']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      outflow: double.tryParse(data['outflow']?.toString() ?? '0.0') ?? 0.0,
      inflow: double.tryParse(data['inflow']?.toString() ?? '0.0') ?? 0.0,
      accountId: data['accountId'],
      categoryId: data['categoryId'],
    )..id = documentId;
  }

}
