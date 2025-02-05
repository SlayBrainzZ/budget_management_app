import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  String? id;
  final String userId;
  final String message;
  final bool isRead;
  final DateTime timestamp;
  String? categoryId;
  String? accountId;
  final String type; // NEU: Typ der Benachrichtigung (z.B. "budget_overflow", "low_balance")

  NotificationModel({
    this.id,
    required this.userId,
    required this.message,
    this.isRead = false,
    required this.timestamp,
    this.categoryId,
    this.accountId,
    required this.type, // NEU
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'message': message,
      'isRead': isRead,
      'timestamp': timestamp.toIso8601String(),
      'categoryId': categoryId,
      'accountId': accountId,
      'type': type, // NEU
    };
  }

  static NotificationModel fromMap(Map<String, dynamic> data, String id) {
    return NotificationModel(
      id: id,
      userId: data['userId'],
      message: data['message'],
      isRead: data['isRead'] ?? false,
      timestamp: DateTime.parse(data['timestamp']),
      categoryId: data['categoryId'],
      accountId: data['accountId'],
      type: data['type'] ?? "unknown", // NEU
    );
  }
}
