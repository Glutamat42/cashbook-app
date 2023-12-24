import 'package:dio/dio.dart';
import '../models/category.dart'; // Make sure you have a Category model

class CategoriesRepository {
  final Dio dio;

  CategoriesRepository(this.dio);

  Future<List<Category>> getCategories() async {
    try {
      final response = await dio.get('/api/categories');
      List<Category> categories = (response.data as List)
          .map((categoryData) => Category.fromJson(categoryData))
          .toList();
      return categories;
    } on DioException catch (e) {
      throw Exception('Failed to load categories: ${e.message}');
    } on Exception catch (e) {
      throw Exception('Failed to load categories: ${e.toString()}');
    }
  }

  Future<Category> createCategory(Category newCategory) async {
    try {
      final response = await dio.post('/api/categories', data: newCategory.toJson());
      return Category.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Failed to create category: ${e.message}');
    } on Exception catch (e) {
      throw Exception('Failed to create category: ${e.toString()}');
    }
  }

  Future<Category> updateCategory(int id, Map<String, dynamic> categoryData) async {
    try {
      final response = await dio.put('/api/categories/$id', data: categoryData);
      return Category.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Failed to update category: ${e.message}');
    } on Exception catch (e) {
      throw Exception('Failed to update category: ${e.toString()}');
    }
  }

  Future<void> deleteCategory(int id) async {
    try {
      await dio.delete('/api/categories/$id');
    } on DioException catch (e) {
      throw Exception('Failed to delete category: ${e.message}');
    } on Exception catch (e) {
      throw Exception('Failed to delete category: ${e.toString()}');
    }
  }
}
