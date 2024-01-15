import 'package:cashbook/widgets/details_screen_widget/flexible_detail_item_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';

enum AmountType { income, expense }

class DualModeAmountWidget extends StatelessWidget {
  final _log = Logger('DualModeAmountWidget');
  final bool isEditMode;
  final bool? isIncome;
  final int? amount;
  final Function(int?, bool) onChanged;
  final FormFieldValidator<String>? validator;
  final FormFieldValidator<bool>? isIncomeValidator;

  DualModeAmountWidget({
    Key? key,
    required this.isEditMode,
    required this.isIncome,
    required this.amount,
    required this.onChanged,
    this.validator,
    this.isIncomeValidator,
  }) : super(key: key);

  double? _centToEuro(int? amountInCents) {
    return amountInCents == null ? null : amountInCents / 100;
  }

  int? _euroToCent(String? amountInEuros) {
    if (amountInEuros == null || amountInEuros.isEmpty) {
      return null;
    }
    if (amountInEuros.endsWith(',') || amountInEuros.endsWith('.')) {
      amountInEuros = '${amountInEuros}0';
    }
    if (amountInEuros.contains(',')) {
      amountInEuros = amountInEuros.replaceAll(',', '.');
    }
    return (double.parse(amountInEuros) * 100).round();
  }

  void _updateAmount(String? value) {
    if (isIncome == null) {
      _log.warning('isIncome is null');
      return;
    }
    onChanged(_euroToCent(value), isIncome!);
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
              isIncome != null ? (isIncome! ? "+" : "-") + _formatAmount(_centToEuro(amount)) : "-",
              style: isIncome != null ? TextStyle(color: isIncome! ? Colors.green : Colors.red) : null,
            ),
          );
  }

  Widget _buildAmountEdit() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormField<bool>(
          validator: isIncomeValidator,
          initialValue: isIncome,
          builder: (FormFieldState<bool> field) {
            return Column(
              children: <Widget>[
                FlexibleDetailItemView(
                  title: 'Transaction Type:',
                  rightWidget: Column(
                    children: <Widget>[
                      RadioListTile<bool>(
                        title: Text('Income', style: TextStyle(color: field.hasError ? Colors.red : null)),
                        value: true,
                        groupValue: (field.value == true),
                        onChanged: (_) {
                          field.didChange(true);
                          _updateIsIncome(true);
                        },
                      ),
                      RadioListTile<bool>(
                        title: Text('Expense', style: TextStyle(color: field.hasError ? Colors.red : null)),
                        value: true,
                        groupValue: (field.value == false),
                        onChanged: (_) {
                          field.didChange(false);
                          _updateIsIncome(false);
                        },
                      ),
                    ],
                  ),
                ),
                if (field.errorText != null) ...[
                  const SizedBox(height: 5.0),
                  Text(
                    field.errorText!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
              ],
            );
          },
        ),
        TextFormField(
          initialValue: _centToEuro(amount) == null ? "" : _centToEuro(amount)!.toStringAsFixed(2),
          decoration: const InputDecoration(labelText: 'Amount (€)'),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: _updateAmount,
          inputFormatters: <TextInputFormatter>[
            // for below version 2 use this
            FilteringTextInputFormatter.allow(RegExp(r'^[0-9]*([,.][0-9]{0,2})?')),
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
