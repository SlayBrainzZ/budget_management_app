/**
 * This class represents a recurring expense. It stores information
 * such as ID, user ID, subscription name, amount, renewal date, flags for recurring status
 * and reminder sent status.
 *
 * @author Ahmad
 */

class Subscription {
  String? id; // Make id nullable to handle creation scenario
  final String userId;
  final String name;
  final double amount;
  final DateTime renewalDate;
  final bool isRecurring;
  final bool isReminderSent;

  Subscription({
    required this.userId,
    required this.name,
    required this.amount,
    required this.renewalDate,
    required this.isRecurring,
    required this.isReminderSent,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'amount': amount.toString(),
      'renewalDate': renewalDate.toIso8601String(),
      'isRecurring': isRecurring,
      'isReminderSent': isReminderSent,
    };
  }

  static Subscription fromMap(Map<String, dynamic> data, String documentId) {
    return Subscription(
      userId: data['userId'],
      name: data['name'],
      amount: double.parse(data['amount']),
      renewalDate: DateTime.parse(data['renewalDate']),
      isRecurring: data['isRecurring'],
      isReminderSent: data['isReminderSent'],
    )..id = documentId; // Assign the document ID after creation

  }
}