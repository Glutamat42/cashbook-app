import 'package:flutter/material.dart';

class FlexibleDetailItemView extends StatelessWidget {
  final String title;
  final Widget rightWidget;

  const FlexibleDetailItemView({
    Key? key,
    required this.title,
    required this.rightWidget,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Expanded(
            flex: 1,
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 2,
            child: rightWidget,
          ),
        ],
      ),
    );
  }
}
