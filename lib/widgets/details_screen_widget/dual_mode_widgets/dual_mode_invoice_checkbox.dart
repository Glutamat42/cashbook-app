import 'package:flutter/material.dart';
import '../flexible_detail_item_view.dart';

class DualModeInvoiceCheckbox extends StatelessWidget {
  final bool isEditMode;
  final bool noInvoice;
  final Function(bool) onChanged; // Updated function signature

  const DualModeInvoiceCheckbox({
    Key? key,
    required this.isEditMode,
    required this.noInvoice,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return isEditMode
        ? _buildInvoiceCheckboxEdit()
        : FlexibleDetailItemView(
            title: 'No Invoice:',
            rightWidget: Text(noInvoice ? 'Yes' : 'No'),
          );
  }

  Widget _buildInvoiceCheckboxEdit() {
    return FlexibleDetailItemView(
      title: 'No Invoice:',
      rightWidget: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        // Aligns checkbox to the left
        children: [
          Checkbox(
            value: noInvoice,
            onChanged: (bool? newValue) {
              onChanged(
                  newValue == true); // Call the updated function signature
            },
          ),
        ],
      ),
    );
  }
}
