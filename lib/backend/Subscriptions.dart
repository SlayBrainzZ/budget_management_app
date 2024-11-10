class Subscription {
  final String id;
  final String userId;
  final String name;
  final double amount;
  final DateTime renewalDate;
  final bool isRecurring;
  final bool isReminderSent;

  Subscription({
    required this.id,
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
      id: documentId,
      userId: data['userId'],
      name: data['name'],
      amount: double.parse(data['amount']),
      renewalDate: DateTime.parse(data['renewalDate']),
      isRecurring: data['isRecurring'],
      isReminderSent: data['isReminderSent'],
    );
  }
}