import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'flexible_detail_item_view.dart';

enum AmountType { income, expense }

class DualModeAmountWidget extends StatelessWidget {
  final bool isEditMode;
  final bool isIncome;
  final int? amount;
  final Function(int?, bool) onChanged;
  final FormFieldValidator<String>? validator;

  const DualModeAmountWidget({
    Key? key,
    required this.isEditMode,
    required this.isIncome,
    required this.amount,
    required this.onChanged,
    this.validator,
  }) : super(key: key);

  double? _centToEuro(int? amountInCents) {
    return amountInCents == null ? null : amountInCents / 100;
  }

  int? _euroToCent(String? amountInEuros) {
    if (amountInEuros == null || amountInEuros.isEmpty) {
      return null;
    }
    if (amountInEuros.endsWith(',') || amountInEuros.endsWith('.')) {
      amountInEuros = amountInEuros + '0';
    }
    if (amountInEuros.contains(',')) {
      amountInEuros = amountInEuros.replaceAll(',', '.');
    }
    return (double.parse(amountInEuros) * 100).round();
  }

  void _updateAmount(String? value) {
    onChanged(_euroToCent(value), isIncome);
  }

  void _updateIsIncome(bool value) {
    onChanged(amount, value);
  }

  @override
  Widget build(BuildContext context) {
    return isEditMode
        ? _buildAmountEdit()
        : FlexibleDetailItemView(
            title: 'Amount:',
            rightWidget: Text(
              (isIncome ? "+" : "-") + _formatAmount(_centToEuro(amount)),
              style: TextStyle(color: isIncome ? Colors.green : Colors.red),
            ),
          );
  }

  Widget _buildAmountEdit() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FlexibleDetailItemView(
            title: 'Transaction Type:',
            rightWidget: Column(
              children: <Widget>[
                RadioListTile<bool>(
                  title: const Text('Income'),
                  value: true,
                  groupValue: isIncome,
                  onChanged: (_) {
                    _updateIsIncome(true);
                  },
                ),
                RadioListTile<bool>(
                  title: const Text('Expense'),
                  value: true,
                  groupValue: !isIncome,
                  onChanged: (_) {
                    _updateIsIncome(false);
                  },
                ),
              ],
            )

            // ToggleButtons(  // TODO: replace with something more clear
            //   isSelected: [isIncome, !isIncome],
            //   onPressed: (index) {
            //     _updateIsIncome(index == 0);
            //   },
            //   children: const [
            //     Padding(
            //       padding: EdgeInsets.symmetric(horizontal: 16),
            //       child: Text('Income'),
            //     ),
            //     Padding(
            //       padding: EdgeInsets.symmetric(horizontal: 16),
            //       child: Text('Expense'),
            //     ),
            //   ],
            // ),
            ),
        TextFormField(
          initialValue: _centToEuro(amount) == null
              ? ""
              : _centToEuro(amount)!.toStringAsFixed(2),
          decoration: const InputDecoration(labelText: 'Amount (€)'),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: _updateAmount,
          inputFormatters: <TextInputFormatter>[
            // for below version 2 use this
            FilteringTextInputFormatter.allow(
                RegExp(r'^[0-9]*([,.][0-9]{0,2})?')),
          ],
          validator: validator,
        ),
      ],
    );
  }

  String _formatAmount(double? amountInEuros) {
    return amountInEuros == null ? "" : '${amountInEuros.toStringAsFixed(2)}€';
  }
}
