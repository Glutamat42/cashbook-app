import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/entry.dart';
import '../screens/details_screen.dart';

class EntryItem extends StatelessWidget {
  final Entry entry;

  EntryItem({Key? key, required this.entry}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _getBackgroundColor(), // Highlight for no invoice
      child: ListTile(
        // In your ListView.builder:
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetailsScreen(entry: entry),
            ),
          );
        },
        title: Text(
          entry.recipientSender,
          style: const TextStyle(fontWeight: FontWeight.bold),
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          entry.description,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(_formatAmount(entry.amount),
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _amountColor(entry.amount))),
            const SizedBox(height: 4),
            Text(_formatDate(entry.date)),
          ],
        ),
      ),
    );
  }

  String _formatAmount(int amount) {
    final double amountInEuros = amount / 100;
    return '${amount >= 0 ? '+' : ''}${amountInEuros.toStringAsFixed(2)}€';
  }

  Color _amountColor(int amount) {
    return amount > 0 ? Colors.green : Colors.red;
  }

  String _formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  Color _getBackgroundColor() {
    if (entry.noInvoice == false) {
      // TODO: check document exists
      return Colors.orange
          .withOpacity(0.3); // Color for entries with no invoice
    }
    return Colors.transparent;
  }
}
