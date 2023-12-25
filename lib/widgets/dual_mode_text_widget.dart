import 'package:flutter/material.dart';

class DualModeTextWidget extends StatefulWidget {
  final bool isEditMode;
  final String value;
  final Function(String) onChanged;
  final String label;

  const DualModeTextWidget({
    Key? key,
    required this.isEditMode,
    required this.value,
    required this.onChanged,
    required this.label,
  }) : super(key: key);

  @override
  _DualModeTextWidgetState createState() => _DualModeTextWidgetState();
}

class _DualModeTextWidgetState extends State<DualModeTextWidget> {
  late TextEditingController _textEditingController;

  @override
  void initState() {
    super.initState();
    _textEditingController = TextEditingController(text: widget.value);
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.isEditMode ? _buildTextEdit() : FlexibleDetailItemView(
      title: widget.label,
      value: widget.value,
    );
  }

  Widget _buildTextEdit() {
    return TextFormField(
      controller: _textEditingController,
      decoration: InputDecoration(labelText: widget.label),
      onChanged: widget.onChanged,
      validator: (value) => value == null || value.isEmpty ? 'This field cannot be empty' : null,
    );
  }
}
