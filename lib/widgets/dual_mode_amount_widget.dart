import 'package:flutter/material.dart';
import 'detail_item_view.dart';
import 'flexible_detail_item_view.dart';

class DualModeAmountWidget extends StatefulWidget {
  final bool isEditMode;
  final int amount;
  final Function(int) onChanged;

  const DualModeAmountWidget({
    Key? key,
    required this.isEditMode,
    required this.amount,
    required this.onChanged,
  }) : super(key: key);

  @override
  _DualModeAmountWidgetState createState() => _DualModeAmountWidgetState();
}

class _DualModeAmountWidgetState extends State<DualModeAmountWidget> {
  late bool _isIncome;
  late double _amountValue;

  @override
  void initState() {
    super.initState();
    _isIncome = widget.amount >= 0;
    _amountValue = (widget.amount / 100).abs();
  }

  void _updateAmount(double value) {
    int amountInCents = (value * 100).round();
    widget.onChanged(_isIncome ? amountInCents : -amountInCents);
  }

  @override
  Widget build(BuildContext context) {
    return widget.isEditMode ? _buildAmountEdit() : DetailItemView(
      title: 'Amount:',
      value: _formatAmount(widget.amount),
    );
  }

  Widget _buildAmountEdit() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FlexibleDetailItemView(
          title: 'Transaction Type:',
          rightWidget: ToggleButtons(
            isSelected: [_isIncome, !_isIncome],
            onPressed: (index) {
              setState(() {
                _isIncome = index == 0;
                _updateAmount(_amountValue);
              });
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
          initialValue: _amountValue.toStringAsFixed(2),
          decoration: const InputDecoration(labelText: 'Amount (€)'),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (value) {
            if (value.isNotEmpty) {
              _amountValue = double.parse(value);
              _updateAmount(_amountValue);
            }
          },
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

  String _formatAmount(int amount) {
    final double amountInEuros = amount / 100.0;
    return '${amountInEuros.toStringAsFixed(2)}€';
  }
}
