/**
 * This class represents a user in the application. It stores user information
 * such as ID, user ID, email, encrypted password, and creation date.
 *
 * @author Ahmad
 */

class User {

  final String id;
  final String userId;
  final String email;
  final String encryptedPassword;
  final DateTime createdDate;

  User({
    required this.id,
    required this.userId,
    required this.email,
    required this.encryptedPassword,
    required this.createdDate
  });

  Map<String, dynamic> toMap(){
    return{
      'email': email,
      'encryptedPassword': encryptedPassword,
      'createdDate': createdDate.toIso8601String(),
    };
  }

  static User fromMap(Map<String, dynamic> data, String documentId){
    return User(
      id: documentId,
      userId: data['userId'],
      email: data['email'],
      encryptedPassword: data['encryptedPassword'],
      createdDate: DateTime.parse(data['createdDate']),
    );
  }


}