import 'package:flutter/material.dart';
import 'detail_item_view.dart';
import 'flexible_detail_item_view.dart';

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
  _DualModePaymentMethodWidgetState createState() => _DualModePaymentMethodWidgetState();
}

class _DualModePaymentMethodWidgetState extends State<DualModePaymentMethodWidget> {
  late String _currentMethod;

  @override
  void initState() {
    super.initState();
    _currentMethod = widget.paymentMethod;
  }

  @override
  Widget build(BuildContext context) {
    return widget.isEditMode ? _buildPaymentMethodEdit() : DetailItemView(
      title: 'Payment Method:',
      value: _currentMethod,
    );
  }

  Widget _buildPaymentMethodEdit() {
    return FlexibleDetailItemView(
      title: 'Payment Method:',
      rightWidget: Column(
        children: [
          _buildRadioTile('Cash'),
          _buildRadioTile('Bank Transfer'),
          _buildRadioTile('Not Payed'), // New option
        ],
      ),
    );
  }

  Widget _buildRadioTile(String method) {
    return RadioListTile<String>(
      title: Text(method),
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
