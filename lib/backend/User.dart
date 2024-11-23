import 'package:cloud_firestore/cloud_firestore.dart';

/**
 * This class represents a user in the application. It stores user information
 * such as ID, user ID, email, encrypted password, and creation date.
 *
 * @author Ahmad
 */

class User {

  String? id; // Make id nullable to handle creation scenario
  final String userId;
  final String email;
  final DateTime createdDate;
  String? name; // Optional name field

  User({
    required this.userId,
    required this.email,
    required this.createdDate,
    this.name,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'email': email,
      'createdDate': createdDate,
      'name': name,
    };
  }

  static User fromMap(Map<String, dynamic> data, String documentId) {
    return User(
      userId: data['userId'],
      email: data['email'],
      createdDate: (data['createdDate'] as Timestamp).toDate(), // Convert Timestamp to DateTime
      name: data['name'],
    )..id = documentId;
  }
}

