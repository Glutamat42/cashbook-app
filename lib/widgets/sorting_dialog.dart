import 'package:cashbook/stores/entry_store.dart';
import 'package:flutter/material.dart';

class SortingDialog extends StatefulWidget {
  final SortField initialSortField;
  final SortOrder initialSortOrder;

  const SortingDialog({
    Key? key,
    required this.initialSortField,
    required this.initialSortOrder,
  }) : super(key: key);

  @override
  _SortingDialogState createState() => _SortingDialogState();
}

class _SortingDialogState extends State<SortingDialog> {
  SortField? _selectedField = SortField.date;
  SortOrder? _selectedOrder = SortOrder.ascending;

  @override
  void initState() {
    super.initState();
    _selectedField = widget.initialSortField;
    _selectedOrder = widget.initialSortOrder;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Sort Entries'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          DropdownButton<SortField>(
            value: _selectedField,
            onChanged: (SortField? newValue) {
              setState(() {
                _selectedField = newValue;
              });
            },
            items: SortField.values.map<DropdownMenuItem<SortField>>((SortField value) {
              return DropdownMenuItem<SortField>(
                value: value,
                child: Text(_getSortFieldText(value)),
              );
            }).toList(),
          ),
          DropdownButton<SortOrder>(
            value: _selectedOrder,
            onChanged: (SortOrder? newValue) {
              setState(() {
                _selectedOrder = newValue;
              });
            },
            items: SortOrder.values.map<DropdownMenuItem<SortOrder>>((SortOrder value) {
              return DropdownMenuItem<SortOrder>(
                value: value,
                child: Text(_getSortOrderText(value)),
              );
            }).toList(),
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Cancel'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        TextButton(
          child: const Text('Sort'),
          onPressed: () {
            Navigator.of(context).pop({'field': _selectedField, 'order': _selectedOrder});
          },
        ),
      ],
    );
  }

  String _getSortFieldText(SortField field) {
    switch (field) {
      case SortField.date:
        return 'Date';
      case SortField.amount:
        return 'Amount';
      case SortField.recipient:
        return 'Recipient/Sender';
      default:
        return '';
    }
  }

  String _getSortOrderText(SortOrder order) {
    return order == SortOrder.ascending ? 'Ascending' : 'Descending';
  }
}
