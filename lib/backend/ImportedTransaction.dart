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
      'categoryId': categoryId,
      'description': description,
      'payerOrRecipient': payerOrRecipient,
      'outflow': outflow,
      'inflow': inflow,
    };
  }

  // Factory method to create an ImportedTransaction from a Map
  static ImportedTransaction fromMap(Map<String, dynamic> data, String documentId) {
    return ImportedTransaction(
      userId: data['userId'],
      amount: double.parse(data['amount']),
      date: DateTime.parse(data['date']),
      payerOrRecipient: data['payerOrRecipient'],
      description: data['description'],
      outflow: double.parse(data['outflow']),
      inflow: double.parse(data['inflow']),
    )..id = documentId;
  }
}
