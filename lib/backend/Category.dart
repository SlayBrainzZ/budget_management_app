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

  Category({
    required this.userId, // Make userId required in the constructor
    required this.name,
    required this.budgetLimit,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId, // Include userId in the map
      'name': name,
      'budgetLimit': budgetLimit.toString(),
    };
  }

  static Category fromMap(Map<String, dynamic> data, String documentId) {
    return Category(
      userId: data['userId'],
      name: data['name'],
      budgetLimit: double.parse(data['budgetLimit']),
    )..id = documentId; // Assign the document ID after creation
  }
}
