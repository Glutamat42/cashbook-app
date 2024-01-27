import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import '../flexible_detail_item_view.dart';

class DualModeDateWidget extends StatefulWidget {
  final bool isEditMode;
  final DateTime? date;
  final Function(DateTime?) onChanged;
  final FormFieldValidator<String>? validator;

  const DualModeDateWidget({
    Key? key,
    required this.isEditMode,
    required this.date,
    this.validator,
    required this.onChanged,
  }) : super(key: key);

  @override
  State<DualModeDateWidget> createState() => _DualModeDateWidgetState();
}

class _DualModeDateWidgetState extends State<DualModeDateWidget> {
  final Logger _log = Logger('DualModeDateWidget');
  final _dateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _dateController.text = widget.date == null ? "" : DateFormat("dd.MM.yyyy").format(widget.date!.toLocal());
  }

  final String dateFormat = "dd.MM.yyyy";
  @override
  Widget build(BuildContext context) {
    return widget.isEditMode ? _buildDatePickerEdit(context) : _buildDateDisplay();
  }

  Widget _buildDateDisplay() {
    return FlexibleDetailItemView(
      title: 'Invoice Date:',
      rightWidget: Text(widget.date == null ? "" : DateFormat(dateFormat).format(widget.date!.toLocal())),
    );
  }

  Widget _buildDatePickerEdit(BuildContext context) {
    return FlexibleDetailItemView(
      title: 'Invoice date:',
      rightWidget: Row(
        children: [
          Expanded(
            child: TextFormField(
              decoration: InputDecoration(
                  labelText: 'Date',
                  hintText: dateFormat,
              ),
              // onTap: () => _selectDate(context),
              controller: _dateController,
              keyboardType: TextInputType.datetime,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9-./]')),
              ],
              // onEditingComplete: ,
              onChanged: _handleDateTextInputFieldChange,
              validator: widget.validator,
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
      widget.onChanged(null);
      return;
    }
    try {
      final DateTime parsedDate = DateFormat(dateFormat).parseStrict(value, true);
      _log.finer('Current user Input "$value" is parse-able to date: $parsedDate');
      widget.onChanged(parsedDate);
    } catch (e) {
      _log.fine('Current user Input is not parse-able to date: $value');
      widget.onChanged(null);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime now = DateTime.now();
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: widget.date ?? DateTime(now.year, now.month, now.day),
      firstDate: DateTime(2023),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      widget.onChanged(pickedDate);
      setState(() {
        _dateController.text = DateFormat(dateFormat).format(pickedDate.toLocal());
      });
    }
  }
}
