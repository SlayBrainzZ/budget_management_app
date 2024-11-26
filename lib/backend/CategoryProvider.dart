import 'package:budget_management_app/backend/User.dart';
import 'package:flutter/material.dart';
import 'package:budget_management_app/backend/firestore_service.dart';
import 'package:budget_management_app/backend/Category.dart';

class CategoryProvider extends ChangeNotifier {
  List<Category> _categories = [];
  bool _isLoading = false;

  List<Category> get categories => _categories;
  bool get isLoading => _isLoading;


  Future<void> fetchCategories(String userId) async {
    _isLoading = true;
    notifyListeners();

    _categories = await FirestoreService().getUserCategories(userId);

    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateCategory(String userId, Category category) async {
    await FirestoreService().updateCategory(userId, category);
    await fetchCategories(userId); // Refresh categories
  }

  Future<void> deleteCategory(String userId, String categoryId) async {
    await FirestoreService().deleteCategory(userId as String, categoryId);
    await fetchCategories(userId); // Refresh categories
  }
}
