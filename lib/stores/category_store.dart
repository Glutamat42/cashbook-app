import 'package:dio/dio.dart';
import 'package:logging/logging.dart';
import 'package:mobx/mobx.dart';
import '../models/category.dart';
import '../repositories/categories_repository.dart';
import '../services/locator.dart';

part 'category_store.g.dart';

class CategoryStore = _CategoryStore with _$CategoryStore;

abstract class _CategoryStore with Store {
  final Logger _log = Logger('_CategoryStore');
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
    _log.info('Loaded ${categories.length} categories');
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

  @action
  Future<void> onLogout() async {
    categories.clear();
  }

  String findCategoryName(int? categoryId) {
    String categoryName = 'Unknown';
    if (categoryId == null) {
      categoryName = "";
    } else {
      try {
        final category =
        categories.firstWhere((c) => c.id == categoryId);
        categoryName = category.name;
      } catch (e) {
        _log.warning('Category with id $categoryId not found. This is expected before the categories are loaded.');
      }
    }
    return categoryName;
  }
}
