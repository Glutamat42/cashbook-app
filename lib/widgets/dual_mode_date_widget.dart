import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'detail_item_view.dart';
import 'flexible_detail_item_view.dart';

class DualModeDateWidget extends StatefulWidget {
  final bool isEditMode;
  final DateTime date;
  final Function(DateTime) onChanged;

  const DualModeDateWidget({
    Key? key,
    required this.isEditMode,
    required this.date,
    required this.onChanged,
  }) : super(key: key);

  @override
  _DualModeDateWidgetState createState() => _DualModeDateWidgetState();
}

class _DualModeDateWidgetState extends State<DualModeDateWidget> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.date;
  }

  @override
  Widget build(BuildContext context) {
    return widget.isEditMode
        ? _buildDatePickerEdit()
        : DetailItemView(
            title: 'Date:',
            value: DateFormat('yyyy-MM-dd').format(_selectedDate),
          );
  }

  Widget _buildDatePickerEdit() {
    return FlexibleDetailItemView(
      title: 'Date:',
      rightWidget: Row(
        mainAxisAlignment: MainAxisAlignment.start, // Aligns children to the end (right)
        mainAxisSize: MainAxisSize.min, // Minimizes the row size to fit children
        children: [
          IconButton(
            icon: Icon(Icons.calendar_today),
            onPressed: () => _selectDate(context),
          ),
          Text(DateFormat('yyyy-MM-dd').format(_selectedDate)),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
      });
      widget.onChanged(pickedDate);
    }
  }
}
