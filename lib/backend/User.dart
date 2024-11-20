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
      'userId': userId, // Include userId in the map
      'email': email,
      'createdDate': createdDate, // Store DateTime object directly
      'name': name, // Include name in the map
    };
  }

  static User fromMap(Map<String, dynamic> data, String documentId) {
    return User(
      userId: data['userId'],
      email: data['email'],
      createdDate: DateTime.parse(data['createdDate']),
      name: data['name'],
    )..id = documentId;
  }
}

