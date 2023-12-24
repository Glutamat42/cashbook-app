import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'detail_item_view.dart';
import '../models/category.dart';
import '../stores/category_store.dart';
import '../services/locator.dart';

class DualModeCategoryWidget extends StatefulWidget {
  final bool isEditMode;
  final int categoryId;
  final Function(int) onChanged;

  const DualModeCategoryWidget({
    Key? key,
    required this.isEditMode,
    required this.categoryId,
    required this.onChanged,
  }) : super(key: key);

  @override
  _DualModeCategoryWidgetState createState() => _DualModeCategoryWidgetState();
}

class _DualModeCategoryWidgetState extends State<DualModeCategoryWidget> {
  late CategoryStore _categoryStore;
  final Logger _log = Logger('DualModeCategoryWidget');

  @override
  void initState() {
    super.initState();
    _categoryStore = locator<CategoryStore>();
  }

  @override
  Widget build(BuildContext context) {
    return widget.isEditMode
        ? _buildCategoryEdit()
        : DetailItemView(
            title: 'Category:',
            value: _findCategoryName(widget.categoryId),
          );
  }

  Widget _buildCategoryEdit() {
    return Row(
      children: <Widget>[
        Expanded(
          child: _buildCategoryDropdown(),
        ),
        IconButton(
          icon: Icon(Icons.add),
          onPressed: () => _showCategoryDialog(context),
        ),
      ],
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
                        onSubmitted: (_) => _submitNewCategory(context, newCategoryName) ,
                        decoration: InputDecoration(
                          hintText: 'New Category',
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.check),
                            onPressed: () => _submitNewCategory(context, newCategoryName),
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

  void _submitNewCategory(BuildContext scaffoldContext, String newCategoryName) async {
    final categoryStore = locator<CategoryStore>();
    {
      if (newCategoryName.isNotEmpty) {
        Category newCategory;
        SnackBar snackBar;
        try {
          newCategory = await categoryStore.createCategory(newCategoryName);
          snackBar =
          const SnackBar(content: Text('Category created and selected for current entry.'));
          widget.onChanged(newCategory.id!); // Update the parent widget state
        } catch (e) {
          _log.severe('Failed to create category: $e');
          snackBar = const SnackBar(content: Text('Failed to create category'));
        }

        if (context.mounted) { // Check if the widget is still in the widget tree
          Navigator.of(scaffoldContext).pop(); // Close the dialog
          ScaffoldMessenger.of(scaffoldContext).showSnackBar(snackBar); // Show the snackbar
        }
      }
    }
  }

  Widget _buildCategoryDropdown() {
    final categories = _categoryStore.categories;

    return DropdownButtonFormField<int>(
      value: widget.categoryId,
      onChanged: (int? newValue) {
        if (newValue != null) {
          widget.onChanged(newValue);
        }
      },
      items: categories.map<DropdownMenuItem<int>>((Category category) {
        return DropdownMenuItem<int>(
          value: category.id,
          child: Text(category.name),
        );
      }).toList(),
      decoration: const InputDecoration(labelText: 'Category'),
    );
  }

  String _findCategoryName(int? categoryId) {
    String categoryName = 'Unknown';
    try {
      final category = _categoryStore.categories.firstWhere((c) => c.id == categoryId);
      categoryName = category.name;
    } catch (e) {
      debugPrint('Category with id $categoryId not found');
    }
    return categoryName;
  }
}
