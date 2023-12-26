import 'package:flutter/material.dart';
import 'flexible_detail_item_view.dart';

class DualModeAmountWidget extends StatelessWidget {
  final bool isEditMode;
  final bool isIncome;
  final int? amount;
  final Function(int?, bool) onChanged;

  const DualModeAmountWidget({
    Key? key,
    required this.isEditMode,
    required this.isIncome,
    required this.amount,
    required this.onChanged,
  }) : super(key: key);

  double? _centToEuro(int? amountInCents) {
    return amountInCents == null ? null : amountInCents / 100;
  }

  int? _euroToCent(String? amountInEuros) {
    return amountInEuros == null
        ? null
        : (double.parse(amountInEuros) * 100).round();
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
            rightWidget: Text(_formatAmount(_centToEuro(amount))),
          );
  }

  Widget _buildAmountEdit() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FlexibleDetailItemView(
          title: 'Transaction Type:',
          rightWidget: ToggleButtons(  // TODO: replace with something more clear
            isSelected: [isIncome, !isIncome],
            onPressed: (index) {
              _updateIsIncome(index == 0);
            },
            children: const [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('Income'),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('Expense'),
              ),
            ],
          ),
        ),
        TextFormField(
          initialValue:
              _centToEuro(amount) == null ? "" : _centToEuro(amount)!.toStringAsFixed(2),
          decoration: const InputDecoration(labelText: 'Amount (€)'),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: _updateAmount,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Amount is required';
            }
            if (double.tryParse(value) == null) {
              return 'Enter a valid number';
            }
            return null;
          },
        ),
      ],
    );
  }

  String _formatAmount(double? amountInEuros) {
    return amountInEuros == null ? "" : '${amountInEuros.toStringAsFixed(2)}€';
  }
}
