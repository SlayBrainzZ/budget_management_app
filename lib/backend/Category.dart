import 'package:flutter/material.dart';

/**
 * This class represents a spending category. It stores information
 * such as name, and budget limit. The ID is now retrieved from Firestore
 * after creation.
 *
 * @author Ahmad
 */
class Category {
  String? id;
  String userId;
  String name;
  double? budgetLimit;
  IconData? icon;
  Color? color;
  bool isDefault;  // New field for default category identification
  String? accountId;
  int streakCounter; //New field to track the streak of adherence to budget

  Category({
    required this.userId,
    required this.name,
    this.budgetLimit,
    this.icon,
    this.color,
    this.isDefault = false,  // Default is false for user-defined categories
    this.accountId, // Optional account link
    this.id,
    this.streakCounter = 0, // Initialize streak counter with 0
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'budgetLimit': budgetLimit.toString(),
      'icon': icon?.codePoint,
      'color': color?.value,
      'isDefault': isDefault, // Save isDefault field
      'accountId': accountId,
      'streakCounter': streakCounter,
      'id' : id,
    };
  }

  static Category fromMap(Map<String, dynamic> data, String documentId) {
    return Category(
      userId: data['userId'],
      name: data['name'],
      budgetLimit: double.tryParse(data['budgetLimit']) ?? 0.0,
      icon: data['icon'] != null ? IconData(data['icon'], fontFamily: 'MaterialIcons') : null,
      color: data['color'] != null ? Color(data['color']) : null,
      isDefault: data['isDefault'] ?? false,  // Parse isDefault from Firestore
      accountId: data['accountId'],
      streakCounter: data['streakCounter'] ?? 0, // Load streak counter from Firestore
    )..id = documentId;
  }
}