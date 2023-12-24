import 'package:flutter/material.dart';
import 'flexible_detail_item_view.dart';

class DetailItemView extends StatelessWidget {
  final String title;
  final String value;

  const DetailItemView({
    Key? key,
    required this.title,
    required this.value,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FlexibleDetailItemView(
      title: title,
      rightWidget: Text(value),
    );
  }
}
