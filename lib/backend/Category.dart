/**
 * This class represents a spending category. It stores information
 * such as ID, name, and budget limit.
 *
 * @author Ahmad
 */

class Category {
  final String id;
  final String name;
  final double budgetLimit;

  Category({
    required this.id,
    required this.name,
    required this.budgetLimit,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'budgetLimit': budgetLimit.toString(),
    };
  }

  static Category fromMap(Map<String, dynamic> data, String documentId) {
    return Category(
      id: documentId,
      name: data['name'],
      budgetLimit: double.parse(data['budgetLimit']),
    );
  }
}
