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
      'budgetLimit': budgetLimit,
    };
  }

  static Category fromMap(Map<String, dynamic> data, String documentId) {
    return Category(
      id: documentId,
      name: data['name'],
      budgetLimit: data['budgetLimit'],
    );
  }
}
