import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:intl/intl.dart';
import '../models/entry.dart';
import '../screens/details_screen.dart';
import '../services/locator.dart';
import '../stores/entry_store.dart';

class EntryItem extends StatelessWidget {
  final Entry entry;
  final EntryStore entryStore = locator<EntryStore>();

  EntryItem({Key? key, required this.entry}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool invoiceMissing = entry.noInvoice == false && (entryStore.entryDocuments[entry.id] ?? []).isEmpty;
    bool notPayed = entry.paymentMethod == 'not_payed';

    return Observer(
      builder: (_) => Container(
        color: _getBackgroundColor(invoiceMissing, notPayed), // Highlight for no invoice
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
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: 24,
                      child: invoiceMissing ? const Icon(
                        Icons.text_snippet_outlined,
                        color: Colors.red,
                      ):null,
                    ),
                    SizedBox(
                      height: 24,
                      child: notPayed ? const Icon(
                        Icons.attach_money,
                        color: Colors.red,
                      ):null,
                    ),
                  ],
                ),
                const SizedBox(width: 4),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(_formatAmount(entry.amount, entry.isIncome),
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: entry.isIncome ? Colors.green : Colors.red)),
                    const SizedBox(height: 4),
                    Text(_formatDate(entry.date)),
                  ],
                ),
              ],
            )),
      ),
    );
  }

  String _formatAmount(int? amount, bool isIncome) {
    if (amount == null) {
      return "";
    }
    final double amountInEuros = amount / 100;
    return '${isIncome ? '+' : '-'}${amountInEuros.toStringAsFixed(2)}€';
  }

  String _formatDate(DateTime? date) {
    if (date == null) {
      return "";
    }
    return DateFormat('dd.MM.yyyy').format(date);
  }

  Color _getBackgroundColor(bool invoiceMissing, bool notPayed) {
    if (invoiceMissing || notPayed) {
      return Colors.orange.withOpacity(0.3); // Color for entries with no invoice
    }
    return Colors.transparent;
  }
}
