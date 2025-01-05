import 'Category.dart';
import 'BankAccount.dart';
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
  String? accountId;

  Category? categoryData; // Neu: Verknüpfte Kategorie-Daten
  BankAccount? bankAccount;

  Transaction({
    required this.userId,
    required this.amount,
    required this.date,
    this.categoryId,
    required this.type,
    required this.importance,
    this.note,
    this.categoryData,
    this.bankAccount,// Neu
    this.accountId, // Optional account link
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
      'accountId': accountId,
    };
  }

  Transaction copyWith({
    String? userId,
    double? amount,
    DateTime? date,
    String? categoryId,
    String? type,
    String? note,
    bool? importance,
    Category? categoryData,
    BankAccount? bankAccount,
    String? id, // Füge `id` als optionales Argument hinzu
    String? accountId,
  }) {
    return Transaction(
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      categoryId: categoryId ?? this.categoryId,
      type: type ?? this.type,
      note: note ?? this.note,
      importance: importance ?? this.importance,
      categoryData: categoryData ?? this.categoryData,
      bankAccount: bankAccount?? this.bankAccount,
      accountId: accountId ?? this.accountId,
    )..id = id ?? this.id; // Setze die ID hier korrekt
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
      accountId: data['accountId'],
    )..id = documentId;
  }

  String toPrettyString() {
    return '''
Transaction Details:
ID: ${id ?? "N/A"}
User ID: $userId
Amount: $amount
Date: ${date.toIso8601String()}
Category ID: ${categoryId ?? "N/A"}
Type: $type
Importance: $importance
Note: ${note ?? "N/A"}
Account ID: ${accountId ?? "N/A"}
Category Data: ${categoryData?.toString() ?? "N/A"}
Bank Account: ${bankAccount?.toString() ?? "N/A"}
''';
  }
}

