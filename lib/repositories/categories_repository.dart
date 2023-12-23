import 'package:dio/dio.dart';
import '../models/category.dart'; // Make sure you have a Category model
import '../services/locator.dart';

class CategoriesRepository {
  final Dio dio;

  CategoriesRepository(this.dio);

  // TODO refactor to use category model

  Future<List<Category>> getCategories() async {
    try {
      final response = await dio.get('/api/categories');
      List<Category> categories = (response.data as List)
          .map((categoryData) => Category.fromJson(categoryData))
          .toList();
      return categories;
    } on DioException catch (e) {
      throw Exception('Failed to load categories: ${e.message}');
    } on FormatException catch (e) {
      throw Exception('Data parsing error: ${e.message}');
    }
  }

  Future<Category> createCategory(Map<String, dynamic> categoryData) async {
    try {
      final response = await dio.post('/api/categories', data: categoryData);
      return Category.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Failed to create category: ${e.message}');
    }
  }

  Future<Category> updateCategory(int id, Map<String, dynamic> categoryData) async {
    try {
      final response = await dio.put('/api/categories/$id', data: categoryData);
      return Category.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Failed to update category: ${e.message}');
    }
  }

  Future<void> deleteCategory(int id) async {
    try {
      await dio.delete('/api/categories/$id');
    } on DioException catch (e) {
      throw Exception('Failed to delete category: ${e.message}');
    }
  }
}
