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

// Additional methods for CRUD operations on categories can be added here
}
