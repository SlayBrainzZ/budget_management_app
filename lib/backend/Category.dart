import 'package:flutter/material.dart';

/**
 * This class represents a spending category. It stores information
 * such as name, and budget limit. The ID is now retrieved from Firestore
 * after creation.
 *
 * @author Ahmad
 */


class Category {
  String? id; // Make id nullable to handle creation scenario
  String userId; // Add userId to track who created the category
  String name;
  double budgetLimit;
  IconData? icon;
  Color? color;

  Category({
    required this.userId, // Make userId required in the constructor
    required this.name,
    required this.budgetLimit,
     this.icon,
     this.color,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId, // Include userId in the map
      'name': name,
      'budgetLimit': budgetLimit.toString(),
      'icon': icon?.codePoint,
      'color': color?.value,
    };
  }

  static Category fromMap(Map<String, dynamic> data, String documentId) {
    return Category(
      userId: data['userId'],
      name: data['name'],
      budgetLimit: double.parse(data['budgetLimit']),
      icon: data['icon'] != null ? IconData(data['icon'], fontFamily: 'MaterialIcons') : null, // Handle null icon
      color: data['color'] != null ? Color(data['color']) : null, // Handle null color
    )..id = documentId; // Assign the document ID after creation
  }
}
