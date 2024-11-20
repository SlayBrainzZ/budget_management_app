/**
 * This class represents a financial transaction. It stores information
 * such as ID, user ID, bank account ID, amount, date, time, category ID, transaction type,
 * importance flag, and optional note.
 *
 * @author Ahmad
 */


class Transaction {
  String? id; // Make id nullable to handle creation scenario
  final String userId;
  String bankAccountId;
  double amount;
  final DateTime date;
  final String time;
  String? categoryId; // Make categoryId nullable
  final String type;
  String? note;
  final bool importance;

  Transaction({
    required this.userId,
    required this.bankAccountId,
    required this.amount,
    required this.date,
    required this.time,
    this.categoryId, // Make categoryId optional
    required this.type,
    required this.importance,
    this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'bankAccountId': bankAccountId,
      'amount': amount.toString(),
      'date': date.toIso8601String(),
      'time': time,
      'categoryId': categoryId,
      'type': type,
      'importance' : importance,
      'note': note ?? '',
    };
  }

  static Transaction fromMap(Map<String, dynamic> data, String documentId) {
    return Transaction(
      userId: data['userId'],
      bankAccountId: data['bankAccountId'],
      amount: double.parse(data['amount']),
      date: DateTime.parse(data['date']),
      time: data['time'],
      categoryId: data['categoryId'],
      type: data['type'],
      importance: data['importance'],
      note: data['note'],
    )..id = documentId; // Assign the document ID after creation
  }
}
