import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import '../models/entry.dart';
import '../models/user.dart';
import '../stores/user_store.dart';
import '../stores/category_store.dart';
import '../services/locator.dart';
import '../widgets/document_section.dart';
import '../widgets/dual_mode_amount_widget.dart';
import '../widgets/dual_mode_category_widget.dart';
import '../widgets/dual_mode_date_widget.dart';
import '../widgets/dual_mode_invoice_checkbox.dart';
import '../widgets/dual_mode_payment_method_widget.dart';
import '../widgets/dual_mode_text_widget.dart';

class DetailsScreen extends StatefulWidget {
  final Entry entry;

  const DetailsScreen({Key? key, required this.entry}) : super(key: key);

  @override
  _DetailsScreenState createState() => _DetailsScreenState();
}

// TODO: if edit mode: warn on back button

class _DetailsScreenState extends State<DetailsScreen> {
  final Logger _log = Logger('DetailsScreen');
  late Entry entry;
  bool _isEditMode = false;
  final UserStore _userStore = locator<UserStore>();
  final CategoryStore _categoryStore = locator<CategoryStore>();

  @override
  void initState() {
    super.initState();
    entry = widget.entry;
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Entry Details'),
        actions: <Widget>[
          IconButton(
            icon: Icon(_isEditMode ? Icons.check : Icons.edit),
            onPressed: () {
              if (_isEditMode) {
                // TODO: Handle save logic
              }
              setState(() => _isEditMode = !_isEditMode);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: <Widget>[
            DualModeTextWidget(
              isEditMode: _isEditMode,
              value: widget.entry.recipientSender,
              onChanged: (val) => setState(() => widget.entry.recipientSender = val),
              label: 'Recipient/Sender',
            ),
            DualModeTextWidget(
              isEditMode: _isEditMode,
              value: widget.entry.description,
              onChanged: (val) => setState(() => widget.entry.description = val),
              label: 'Description',
            ),
            DualModeAmountWidget(
              isEditMode: _isEditMode,
              amount: widget.entry.amount,
              onChanged: (val) => setState(() => widget.entry.amount = val),
            ),
            DualModeDateWidget(
              isEditMode: _isEditMode,
              date: widget.entry.date,
              onChanged: (val) => setState(() => widget.entry.date = val),
            ),
            const DocumentSection(),
            DualModeInvoiceCheckbox(
              isEditMode: _isEditMode,
              noInvoice: widget.entry.noInvoice,
              onChanged: (val) => setState(() => widget.entry.noInvoice = val),
            ),
            DualModeCategoryWidget(
              isEditMode: _isEditMode,
              categoryId: widget.entry.categoryId,
              onChanged: (val) => setState(() => widget.entry.categoryId = val),
            ),
            DualModePaymentMethodWidget(
              isEditMode: _isEditMode,
              paymentMethod: widget.entry.paymentMethod,
              onChanged: (val) => setState(() => widget.entry.paymentMethod = val),
            ),
            ..._buildCreatedModifiedInfo(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildCreatedModifiedInfo() {
    String createdByUser = _findUserName(entry.userId);
    String lastModifiedInfo = _getLastModifiedInfo();

    return [
      _buildDetailItem(
          'Created:', '${_formatDateTime(entry.createdAt)} by $createdByUser'),
      _buildDetailItem('Last Modified:', lastModifiedInfo),
    ];
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
