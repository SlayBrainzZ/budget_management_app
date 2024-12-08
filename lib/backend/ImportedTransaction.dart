class ImportedTransaction {
  
  String? id;
  final String userId;
  double amount;
  final DateTime date;
  String? categoryId;
  final String description;  // Description of the transaction (Buchungstext)
  final String payerOrRecipient;  // The payer or recipient (Auftraggeber/Empfänger)
  final double outflow;  // Amount for outgoing transactions (Ausgang)
  final double inflow;   // Amount for incoming transactions (Eingang)

  ImportedTransaction({
    required this.userId,
    required this.amount,
    required this.date,
    required this.payerOrRecipient,
    required this.description,
    required this.outflow,
    required this.inflow,
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
    )..id = documentId;
  }

}
