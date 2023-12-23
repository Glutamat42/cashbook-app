import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import '../models/entry.dart';
import '../models/user.dart';
import '../stores/user_store.dart';
import '../stores/category_store.dart';
import '../services/locator.dart';
import '../widgets/document_section.dart';

class DetailsScreen extends StatelessWidget {
  final Logger _log = Logger('DetailsScreen');
  final Entry entry;
  final UserStore _userStore = locator<UserStore>();
  final CategoryStore _categoryStore = locator<CategoryStore>();

  DetailsScreen({Key? key, required this.entry}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String createdByUser = _findUserName(entry.userId);
    String modifiedByUser = _findUserName(entry.userIdLastModified);
    String categoryName = _findCategoryName(entry.categoryId);
    String lastModifiedInfo = _getLastModifiedInfo();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Entry Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: <Widget>[
            _buildDetailItem('Recipient/Sender:', entry.recipientSender),
            _buildDetailItem('Description:', entry.description),
            _buildDetailItem('Amount:', _formatAmount(entry.amount)),
            _buildDetailItem('Category:', categoryName),
            _buildDetailItem('Date:', _formatDate(entry.date)),
            const DocumentSection(),
            _buildDetailItem('No Invoice:', entry.noInvoice ? 'Yes' : 'No',
                isInvoice: true),
            _buildDetailItem('Payment Method:', entry.paymentMethod),
            _buildDetailItem('Created:',
                '${_formatDateTime(entry.createdAt)} by $createdByUser'),
            _buildDetailItem('Last Modified:', lastModifiedInfo),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String title, String value,
      {bool isInvoice = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
              flex: 1,
              child: Text(title,
                  style: const TextStyle(fontWeight: FontWeight.bold))),
          Expanded(
            flex: 2,
            child: isInvoice
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Radio<bool>(
                        value: true,
                        groupValue: entry.noInvoice,
                        onChanged: null, // Disabled
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(entry.noInvoice ? 'Yes' : 'No'),
                      ),
                    ],
                  )
                : Text(value),
          ),
        ],
      ),
    );
  }

  String _getLastModifiedInfo() {
    if (entry.createdAt == entry.updatedAt) {
      return 'Not modified since creation';
    } else {
      String modifiedByUser = _findUserName(entry.userIdLastModified);
      return 'Last Modified: ${_formatDateTime(entry.updatedAt)} by $modifiedByUser';
    }
  }

  String _formatAmount(int amount) {
    final double amountInEuros = amount / 100;
    return '${amount >= 0 ? '+' : ''}${amountInEuros.toStringAsFixed(2)}€';
  }

  String _formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  String _formatDateTime(String? dateTime) {
    if (dateTime == null) return 'N/A';
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.parse(dateTime));
  }

  String _findUserName(int? userId) {
    String username = 'Unknown';
    try {
      final User user = _userStore.users.firstWhere((u) => u.id == userId);
      username = user.username;
    } catch (e) {
      _log.warning('User with id $userId not found');
    }
    return username;
  }

  String _findCategoryName(int? categoryId) {
    String categoryName = 'Unknown';
    try {
      final category =
          _categoryStore.categories.firstWhere((c) => c.id == categoryId);
      return category.name;
    } catch (e) {
      _log.warning('Category with id $categoryId not found');
    }
    return categoryName;
  }
}
