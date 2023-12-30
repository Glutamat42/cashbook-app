import 'package:cashbook/models/category.dart';
import 'package:cashbook/services/locator.dart';
import 'package:cashbook/stores/category_store.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import '../flexible_detail_item_view.dart';

class DualModeCategoryWidget extends StatelessWidget {
  final bool isEditMode;
  final int? categoryId;
  final Function(int?)? onChanged;
  final Function(int?)? onSaved;
  final FormFieldValidator<int>? validator;
  final CategoryStore categoryStore = locator<CategoryStore>();
  final Logger _log = Logger('DualModeCategoryWidget');

  DualModeCategoryWidget({
    Key? key,
    required this.isEditMode,
    required this.categoryId,
    this.validator,
    this.onChanged,
    this.onSaved,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return isEditMode ? _buildCategoryEdit(context) : _buildCategoryDisplay();
  }

  Widget _buildCategoryEdit(context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: DropdownButtonFormField<int>(
            value: categoryId,
            items: categoryStore.categories.map<DropdownMenuItem<int>>((Category category) {
              return DropdownMenuItem<int>(
                value: category.id,
                child: Text(category.name),
              );
            }).toList(),
            decoration: const InputDecoration(labelText: 'Category'),
            onChanged: onChanged,
            onSaved: onSaved,
            validator: validator,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: () => _showCategoryDialog(context),
        ),
      ],
    );
  }

  Widget _buildCategoryDisplay() {
    return FlexibleDetailItemView(
      title: 'Category:',
      rightWidget: Text(_findCategoryName(categoryId)),
    );
  }

  void _showCategoryDialog(BuildContext context) {
    final categoryStore = locator<CategoryStore>();
    String newCategoryName = '';

    showDialog(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: Text('Manage Categories'),
                content: SizedBox(
                  width: double.maxFinite, // Ensures the dialog is wide enough
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      // Existing categories list
                      Expanded(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: categoryStore.categories.length,
                          itemBuilder: (context, index) {
                            final category = categoryStore.categories[index];
                            return ListTile(title: Text(category.name));
                          },
                        ),
                      ),
                      // TextField for new category
                      TextField(
                        onChanged: (value) => newCategoryName = value,
                        onSubmitted: (_) =>
                            _submitNewCategory(context, newCategoryName),
                        decoration: InputDecoration(
                          hintText: 'New Category',
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.check),
                            onPressed: () =>
                                _submitNewCategory(context, newCategoryName),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                actions: <Widget>[
                  TextButton(
                    child: const Text('Close'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              );
            },
          );
        });
  }

  void _submitNewCategory(
      BuildContext context, String newCategoryName) async {
    final categoryStore = locator<CategoryStore>();
    {
      if (newCategoryName.isNotEmpty) {
        Category newCategory;
        SnackBar snackBar;
        try {
          newCategory = await categoryStore.createCategory(newCategoryName);
          snackBar = const SnackBar(
              content:
                  Text('Category created and selected for current entry.'));
          if (onChanged != null) onChanged!(newCategory.id!); // Update the parent widget state
        } catch (e) {
          _log.severe('Failed to create category: $e');
          snackBar = const SnackBar(content: Text('Failed to create category'));
        }

        if (context.mounted) {
          // Check if the widget is still in the widget tree
          Navigator.of(context).pop(); // Close the dialog
          ScaffoldMessenger.of(context)
              .showSnackBar(snackBar); // Show the snackbar
        }
      }
    }
  }


  String _findCategoryName(int? categoryId) {
    String categoryName = 'Unknown';
    if (categoryId == null) {
      categoryName = "";
    } else {
      try {
        final category =
        categoryStore.categories.firstWhere((c) => c.id == categoryId);
        categoryName = category.name;
      } catch (e) {
        _log.warning('Category with id $categoryId not found');
      }
    }
    return categoryName;
  }
}
