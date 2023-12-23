import 'package:flutter/material.dart';

class EntryItem extends StatelessWidget {
  final String description;
  final String recipientSender;
  final int amount;

  const EntryItem({
    Key? key,
    required this.description,
    required this.recipientSender,
    required this.amount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(description),
      subtitle: Text(recipientSender),
      trailing: Text('€$amount'),
      onTap: () {
        // TODO: Navigate to details screen
      },
    );
  }
}
