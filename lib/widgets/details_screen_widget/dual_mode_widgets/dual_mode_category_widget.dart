import 'package:cashbook/dialogs/new_category_dialog.dart';
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
          onPressed: () {
            _log.fine('Add new category');
            NewCategoryDialog(context, onChanged: onChanged).showCategoryDialog();
          },
        ),
      ],
    );
  }

  Widget _buildCategoryDisplay() {
    return FlexibleDetailItemView(
      title: 'Category:',
      rightWidget: Text(categoryStore.findCategoryName(categoryId)),
    );
  }
}
