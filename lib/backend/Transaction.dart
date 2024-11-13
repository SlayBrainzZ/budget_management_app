/**
 * This class represents a financial transaction. It stores information
 * such as ID, user ID, bank account ID, amount, date, time, category ID, transaction type,
 * importance flag, and optional note.
 *
 * @author Ahmad
 */

class Transaction {
  final String id;
  final String userId;
  final String bankAccountId;
  final double amount;
  final DateTime date;
  final String time;
  final String categoryId;
  final String type;
  final String? note;
  final bool importance;

  Transaction({
    required this.id,
    required this.userId,
    required this.bankAccountId,
    required this.amount,
    required this.date,
    required this.time,
    required this.categoryId,
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
      id: documentId,
      userId: data['userId'],
      bankAccountId: data['bankAccountId'],
      amount: double.parse(data['amount']),
      date: DateTime.parse(data['date']),
      time: data['time'],
      categoryId: data['categoryId'],
      type: data['type'],
      importance: data['importance'],
      note: data['note'],
    );
  }
}
