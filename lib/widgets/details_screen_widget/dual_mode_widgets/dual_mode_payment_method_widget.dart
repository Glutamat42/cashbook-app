import 'package:flutter/material.dart';
import '../flexible_detail_item_view.dart';

class DualModePaymentMethodWidget extends StatefulWidget {
  final bool isEditMode;
  final String paymentMethod;
  final Function(String) onChanged;

  const DualModePaymentMethodWidget({
    Key? key,
    required this.isEditMode,
    required this.paymentMethod,
    required this.onChanged,
  }) : super(key: key);

  @override
  _DualModePaymentMethodWidgetState createState() =>
      _DualModePaymentMethodWidgetState();
}

class _DualModePaymentMethodWidgetState
    extends State<DualModePaymentMethodWidget> {
  late String _currentMethod;

  @override
  void initState() {
    super.initState();
    _currentMethod = widget.paymentMethod;
  }

  @override
  Widget build(BuildContext context) {
    return widget.isEditMode
        ? _buildPaymentMethodEdit()
        : FlexibleDetailItemView(
            title: 'Payment Method:',
            rightWidget: Text(_currentMethod),
          );
  }

  Widget _buildPaymentMethodEdit() {
    return FlexibleDetailItemView(
      title: 'Payment Method:',
      rightWidget: Column(
        children: [
          _buildRadioTile('cash'),
          _buildRadioTile('bank_transfer'),
          _buildRadioTile('not_payed'), // New option
        ],
      ),
    );
  }

  Widget _buildRadioTile(String method) {
    String uiText = "";
    switch (method) {
      case 'cash':
        uiText = "Cash";
        break;
      case 'bank_transfer':
        uiText = "Bank transfer";
        break;
      case 'not_payed':
      default:
        uiText = "Not payed";
        break;
    }
    return RadioListTile<String>(
      title: Text(uiText),
      value: method,
      groupValue: _currentMethod,
      onChanged: (String? value) {
        if (value != null) {
          setState(() => _currentMethod = value);
          widget.onChanged(value);
        }
      },
    );
  }
}
