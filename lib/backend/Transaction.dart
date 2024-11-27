import 'Category.dart';
/**
 * This class represents a financial transaction. It stores information
 * such as ID, user ID, bank account ID, amount, date, time, category ID, transaction type,
 * importance flag, and optional note.
 *
 * @author Ahmad
 */
class Transaction {
  String? id;
  final String userId;
  double amount;
  final DateTime date;
  String? categoryId;
  final String type;
  String? note;
  final bool importance;

  Category? categoryData; // Neu: Verknüpfte Kategorie-Daten

  Transaction({
    required this.userId,
    required this.amount,
    required this.date,
    this.categoryId,
    required this.type,
    required this.importance,
    this.note,
    this.categoryData, // Neu
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'amount': amount.toString(),
      'date': date.toIso8601String(),
      'categoryId': categoryId,
      'type': type,
      'importance': importance,
      'note': note ?? '',
    };
  }

  static Transaction fromMap(Map<String, dynamic> data, String documentId) {
    return Transaction(
      userId: data['userId'],
      amount: double.parse(data['amount']),
      date: DateTime.parse(data['date']),
      categoryId: data['categoryId'],
      type: data['type'],
      importance: data['importance'],
      note: data['note'],
    )..id = documentId;
  }
}

/*
class Transaction {
  String? id; // Make id nullable to handle creation scenario
  final String userId;
  double amount;
  final DateTime date;
  String? categoryId;
  final String type;
  String? note;
  final bool importance;

  Transaction({
    required this.userId,
    required this.amount,
    required this.date,
    this.categoryId, // Make categoryId optional
    required this.type,
    required this.importance,
    this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'amount': amount.toString(),
      'date': date.toIso8601String(),
      'categoryId': categoryId,
      'type': type,
      'importance' : importance,
      'note': note ?? '',
    };
  }

  static Transaction fromMap(Map<String, dynamic> data, String documentId) {
    return Transaction(
      userId: data['userId'],
      amount: double.parse(data['amount']),
      date: DateTime.parse(data['date']),
      categoryId: data['categoryId'],
      type: data['type'],
      importance: data['importance'],
      note: data['note'],
    )..id = documentId; // Assign the document ID after creation
  }
}*/
