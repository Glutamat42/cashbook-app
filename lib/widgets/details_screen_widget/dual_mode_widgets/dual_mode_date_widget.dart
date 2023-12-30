import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import '../flexible_detail_item_view.dart';

class DualModeDateWidget extends StatelessWidget {
  final Logger _log = Logger('DualModeDateWidget');
  final bool isEditMode;
  final DateTime? date;
  final Function(DateTime?) onChanged;
  final FormFieldValidator<String>? validator;
  final String dateFormat = "dd.MM.yyyy"; // TODO: get form locale

  DualModeDateWidget({
    Key? key,
    required this.isEditMode,
    required this.date,
    this.validator,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return isEditMode ? _buildDatePickerEdit(context) : _buildDateDisplay();
  }

  Widget _buildDateDisplay() {
    return FlexibleDetailItemView(
      title: 'Date:',
      rightWidget: Text(date == null ? "" : DateFormat(dateFormat).format(date!)),
    );
  }

  Widget _buildDatePickerEdit(BuildContext context) {
    return FlexibleDetailItemView(
      title: 'Date:',
      rightWidget: Row(
        children: [
          Expanded(
            child: TextFormField(
              decoration: InputDecoration(
                  labelText: 'Date',
                  hintText: dateFormat,
              ),
              // onTap: () => _selectDate(context),
              initialValue: date == null ? "" : DateFormat(dateFormat).format(date!),
              keyboardType: TextInputType.datetime,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9-./]')),
              ],
              // onEditingComplete: ,
              onChanged: _handleDateTextInputFieldChange,
              validator: validator,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _selectDate(context),
          ),
        ],
      ),
    );
  }

  void _handleDateTextInputFieldChange(String value) {
    if (value.isEmpty) {
      onChanged(null);
      return;
    }
    try {
      final DateTime parsedDate = DateFormat(dateFormat).parse(value);
      _log.finer('Current user Input "$value" is parse-able to date: $parsedDate');
      onChanged(parsedDate);
    } catch (e) {
      _log.fine('Current user Input is not parse-able to date: $value');
      onChanged(null);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: date ?? DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      onChanged(pickedDate);
    }
  }
}
