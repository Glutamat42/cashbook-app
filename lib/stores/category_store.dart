import 'package:dio/dio.dart';
import 'package:mobx/mobx.dart';
import '../models/category.dart';
import '../repositories/categories_repository.dart';
import '../services/locator.dart';

part 'category_store.g.dart';

class CategoryStore = _CategoryStore with _$CategoryStore;

abstract class _CategoryStore with Store {
  final CategoriesRepository _categoriesRepository = locator<CategoriesRepository>();

  @observable
  ObservableList<Category> categories = ObservableList<Category>();

  @action
  Future<void> loadCategories() async {
    try {
      final fetchedCategories = await _categoriesRepository.getCategories();
      categories = ObservableList<Category>.of(fetchedCategories);
    } catch (e) {
      // Handle errors, e.g., show a message
    }
  }

  Category getCategoryById(int id) {
    return categories.firstWhere((category) => category.id == id);
  }

  @action createCategory(String category) async {
    try {
      final newCategory = await _categoriesRepository.createCategory(Category(name: category));
      categories.add(newCategory);
      return newCategory;
    } on DioException catch (e) {
      throw Exception('Failed to create category: ${e.message}');
    } on Exception catch (e) {
      throw Exception('Failed to create category: ${e.toString()}');
    }
  }

// Additional methods for CRUD operations on categories can be added here
}
