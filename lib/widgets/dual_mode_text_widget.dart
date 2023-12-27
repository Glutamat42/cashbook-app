import 'package:flutter/material.dart';

import 'flexible_detail_item_view.dart';

class DualModeTextWidget extends StatelessWidget {
  final bool isEditMode;
  final Function(String)? onChanged;
  final String label;
  final FormFieldValidator<String>? validator;
  final TextEditingController controller;

  const DualModeTextWidget({
    Key? key,
    required this.isEditMode,
    this.onChanged,
    required this.label,
    required this.controller,
    this.validator,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return isEditMode
        ? _buildTextEdit()
        : FlexibleDetailItemView(
            title: label,
            rightWidget: Text(controller.text),
          );
  }

  Widget _buildTextEdit() {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      onChanged: onChanged,
      validator: validator,
    );
  }
}
