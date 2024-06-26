import 'package:cashbook/stores/category_store.dart';
import 'package:cashbook/utils/helpers.dart';
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
  final CategoryStore categoryStore = locator<CategoryStore>();

  EntryItem({Key? key, required this.entry}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool invoiceMissing = entry.noInvoice == false && (entryStore.entryDocuments[entry.id] ?? []).isEmpty;
    bool notPayed = entry.paymentMethod == 'not_payed';

    return Observer(
      builder: (_) => Container(
        color: _getBackgroundColor(invoiceMissing, notPayed), // Highlight for no invoice
        child: ListTile(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DetailsScreen(entry: entry),
                ),
              );
            },
            subtitle: Row(children: [
              Text(
                "${categoryStore.findCategoryName(entry.categoryId)} | ",
                style: const TextStyle(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                entry.recipientSender,
                overflow: TextOverflow.ellipsis,
              )
            ],) ,
            title: Text(
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
                      child: notPayed ? const Icon(
                        Icons.attach_money,
                        color: Colors.red,
                      ):null,
                    ),
                    SizedBox(
                      height: 24,
                      child: invoiceMissing ? const Icon(
                        Icons.text_snippet_outlined,
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
                    Text(entry.amount == null ? "" : '${entry.isIncome! ? '+' : '-'}${Helpers.formatAmountOfCents(entry.amount)}€',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: entry.isIncome! ? Colors.green : Colors.red)),
                    const SizedBox(height: 4),
                    Text(_formatDate(entry.date)),
                  ],
                ),
              ],
            )),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) {
      return "";
    }
    return DateFormat('dd.MM.yyyy').format(date.toLocal());
  }

  Color _getBackgroundColor(bool invoiceMissing, bool notPayed) {
    if (invoiceMissing || notPayed) {
      return Colors.orange.withOpacity(0.3); // Color for entries with no invoice
    }
    return Colors.transparent;
  }
}
