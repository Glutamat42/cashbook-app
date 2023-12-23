import 'package:flutter/material.dart';
import '../stores/category_store.dart';
import '../stores/entry_store.dart';
import '../services/locator.dart';

class FilterDialog extends StatefulWidget {
  final Map<FilterField, dynamic> currentFilters;

  const FilterDialog({Key? key, required this.currentFilters}) : super(key: key);

  @override
  _FilterDialogState createState() => _FilterDialogState();
}

class _FilterDialogState extends State<FilterDialog> {
  late Map<FilterField, dynamic> _selectedFilters;
  late CategoryStore _categoryStore;
  int? _selectedCategoryId;
  bool _isInvoiceMissing = false;

  @override
  void initState() {
    super.initState();
    _categoryStore = locator<CategoryStore>();
    _selectedFilters = Map.from(widget.currentFilters);
    _selectedCategoryId = _selectedFilters[FilterField.category];
    _isInvoiceMissing = _selectedFilters[FilterField.invoiceMissing] ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Filters'),
      content: SingleChildScrollView(
        child: Column(
          children: [
            DropdownButton<int>(
              value: _selectedCategoryId,
              hint: const Text('Select Category'),
              onChanged: (int? newValue) {
                setState(() {
                  _selectedCategoryId = newValue;
                });
              },
              items: [
                const DropdownMenuItem<int>(
                  value: null,
                  child: Text('All'),
                ),
                ..._categoryStore.categories.map<DropdownMenuItem<int>>((category) {
                  return DropdownMenuItem<int>(
                    value: category.id,
                    child: Text(category.name),
                  );
                }).toList(),
              ]
            ),
            CheckboxListTile(
              title: const Text('Invoice Missing'),
              value: _isInvoiceMissing,
              onChanged: (bool? newValue) {
                setState(() {
                  _isInvoiceMissing = newValue!;
                });
              },
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Cancel'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        TextButton(
          child: const Text('Apply Filters'),
          onPressed: () {
            Navigator.of(context).pop({
              FilterField.category: _selectedCategoryId,
              FilterField.invoiceMissing: _isInvoiceMissing,
            });
          },
        ),
      ],
    );
  }

  String _getFilterFieldText(FilterField field) {
    switch (field) {
      case FilterField.category:
        return 'Category';
      case FilterField.invoiceMissing:
        return 'Invoice Missing';
      default:
        return '';
    }
  }
}
