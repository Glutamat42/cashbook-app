

import 'package:cashbook/models/category.dart';
import 'package:cashbook/services/locator.dart';
import 'package:cashbook/stores/category_store.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

class NewCategoryDialog{
  final Logger _log = Logger('newCategoryDialog');
  String _newCategoryName = '';
  final _categoryStore = locator<CategoryStore>();
  final Function(int?)? onChanged;
  final BuildContext context;

  NewCategoryDialog(this.context, {this.onChanged});


  void showCategoryDialog() {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: const Text('Manage Categories'),
                content: SizedBox(
                  width: double.maxFinite, // Ensures the dialog is wide enough
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      // Existing categories list
                      Expanded(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: _categoryStore.categories.length,
                          itemBuilder: (context, index) {
                            final category = _categoryStore.categories[index];
                            return ListTile(title: Text(category.name));
                          },
                        ),
                      ),
                      // TextField for new category
                      TextField(
                        onChanged: (value) => _newCategoryName = value,
                        onSubmitted: (_) => _submitNewCategory(context, _newCategoryName),
                        decoration: InputDecoration(
                          hintText: 'New Category',
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.check),
                            onPressed: () => _submitNewCategory(context, _newCategoryName),
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

  void _submitNewCategory(BuildContext context, String newCategoryName) async {
    final categoryStore = locator<CategoryStore>();
    {
      if (newCategoryName.isNotEmpty) {
        Category newCategory;
        SnackBar snackBar;
        try {
          newCategory = await categoryStore.createCategory(newCategoryName);
          snackBar = const SnackBar(content: Text('Category created and selected for current entry.'));
          if (onChanged != null) onChanged!(newCategory.id!); // Update the parent widget state
        } catch (e) {
          _log.severe('Failed to create category: $e');
          snackBar = const SnackBar(content: Text('Failed to create category'));
        }

        if (context.mounted) {
          // Check if the widget is still in the widget tree
          Navigator.of(context).pop(); // Close the dialog
          ScaffoldMessenger.of(context).showSnackBar(snackBar); // Show the snackbar
        }
      }
    }
  }
}