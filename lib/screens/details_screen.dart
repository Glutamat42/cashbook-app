import 'package:cashbook/stores/entry_store.dart';
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
import '../widgets/flexible_detail_item_view.dart';

// todo: form validation

class DetailsScreen extends StatefulWidget {
  final Entry entry;

  const DetailsScreen({Key? key, required this.entry})
      : super(key: key);

  @override
  _DetailsScreenState createState() => _DetailsScreenState();
}

// TODO: if edit mode: warn on back button

class _DetailsScreenState extends State<DetailsScreen> {
  late Entry _editableEntry;
  final Logger _log = Logger('DetailsScreen');
  bool _isEditMode = false;
  bool _isNew = false;
  final UserStore _userStore = locator<UserStore>();
  final CategoryStore _categoryStore = locator<CategoryStore>();
  final EntryStore _entryStore = locator<EntryStore>();

  @override
  void initState() {
    super.initState();
    _isNew = widget.entry.id == null;
    if (_isNew) {
      _isEditMode = true;
    }
    _editableEntry = Entry.fromJson(widget.entry.toJson());
  }

  @override
  @override
  Widget build(BuildContext context) {
    return PopScope(
        canPop: !_isEditMode,
        onPopInvoked: (bool canPop) async {
          if (_isEditMode) {
            bool shouldClose = await _showSaveChangesDialog(context);
            if (shouldClose) {
              if (_isNew) {
                Navigator.of(context).pop();
              } else {
                setState(() {
                  _isEditMode = false;
                });
              }
            }
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: Text('Entry Details'),
            actions: <Widget>[
              IconButton(
                icon: Icon(_isEditMode ? Icons.check : Icons.edit),
                onPressed: () async {
                  if (_isEditMode) {
                    _saveEntry();
                  } else {
                    setState(() => _isEditMode = !_isEditMode);
                  }
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
                  value: _editableEntry.recipientSender,
                  onChanged: (val) =>
                      setState(() => _editableEntry.recipientSender = val),
                  label: 'Recipient/Sender',
                ),
                DualModeTextWidget(
                  isEditMode: _isEditMode,
                  value: _editableEntry.description,
                  onChanged: (val) =>
                      setState(() => _editableEntry.description = val),
                  label: 'Description',
                ),
                DualModeAmountWidget(
                  isEditMode: _isEditMode,
                  amount: _editableEntry.amount,
                  isIncome: _editableEntry.isIncome,
                  onChanged: (amount, isIncome) =>
                      setState(() {
                        _editableEntry.amount = amount;
                        _editableEntry.isIncome = isIncome;
                      }),
                ),
                DualModeDateWidget(
                  isEditMode: _isEditMode,
                  date: _editableEntry.date,
                  onChanged: (val) => setState(() => _editableEntry.date = val),
                ),
                DocumentSection(
                  isEditable: _isEditMode,
                  entryId: _editableEntry.id,
                ),
                DualModeInvoiceCheckbox(
                  isEditMode: _isEditMode,
                  noInvoice: _editableEntry.noInvoice,
                  onChanged: (val) =>
                      setState(() => _editableEntry.noInvoice = val),
                ),
                DualModeCategoryWidget(
                  isEditMode: _isEditMode,
                  categoryId: _editableEntry.categoryId,
                  onChanged: (val) =>
                      setState(() => _editableEntry.categoryId = val),
                ),
                DualModePaymentMethodWidget(
                  isEditMode: _isEditMode,
                  paymentMethod: _editableEntry.paymentMethod,
                  onChanged: (val) =>
                      setState(() => _editableEntry.paymentMethod = val),
                ),
                ..._buildCreatedModifiedInfo(),
              ],
            ),
          ),
        ));
  }

  Future<bool> _showSaveChangesDialog(BuildContext context) async {
    return (await showDialog<bool>(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: const Text('Save Changes?'),
            content: const Text('Do you want to save the changes?'),
            actions: <Widget>[
              TextButton(
                child: const Text('Cancel'),
                onPressed: () =>
                // Close dialog and stay in edit mode
                Navigator.of(context).pop(false),
              ),
              TextButton(
                child: const Text('Discard'),
                onPressed: () {
                  Navigator.of(context).pop(true);
                  _discardChanges(context); // Discard changes
                },
              ),
              TextButton(
                child: const Text('Save'),
                onPressed: () {
                  _saveEntry();
                  Navigator.of(context).pop(false); // Proceed with saving logic
                },
              ),
            ],
          ),
    )) ??
        false;
  }

  void _discardChanges(context) {
    if (_isNew) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _editableEntry =
            Entry.fromJson(widget.entry.toJson()); // Revert to original state
        _isEditMode = false; // Exit edit mode
      });
    }
  }

  void _saveEntry() async {
    try {
      if (_isNew) {
        Entry updatedEntry = await _entryStore.createEntry(_editableEntry);
        _showSnackbar(context, 'Changes saved successfully', Colors.green);
        Navigator.of(context).pop();
      } else {
        Entry updatedEntry = await _entryStore.updateEntry(_editableEntry);
        _showSnackbar(context, 'Changes saved successfully', Colors.green);
        // As _editableEntry might get updated from widget.entry it has to be updated
        widget.entry.updateFrom(updatedEntry);
        setState(() {
          // Update _editableEntry to reflect serverside changes (e.g. id, updatedAt, etc.)
          _editableEntry.updateFrom(updatedEntry);
          _isEditMode = false;
        });
      }
    } catch (error) {
      _showSnackbar(
          context, 'Failed to save changes: ${error.toString()}', Colors.red);
      _log.warning('Error saving entry: $error');
    }
  }

  void _showSnackbar(BuildContext context, String message,
      Color backgroundColor) {
    final snackBar = SnackBar(
      content: Text(message),
      backgroundColor: backgroundColor,
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  List<Widget> _buildCreatedModifiedInfo() {
    _log.fine('Building created/modified info, isNew: ${_isNew}');
    if (_isNew) {
      return [];
    }

    String createdByUser = _findUserName(_editableEntry.userId);
    String lastModifiedInfo = _getLastModifiedInfo();

    return [
      FlexibleDetailItemView(
        title: 'Created:',
        rightWidget: Text('${_formatDateTime(_editableEntry.createdAt)} by $createdByUser'),
      ),
      FlexibleDetailItemView(
        title: 'Last Modified:',
        rightWidget: Text(lastModifiedInfo),
      ),
    ];
  }

  String _getLastModifiedInfo() {
    if (_editableEntry.createdAt == _editableEntry.updatedAt) {
      return 'Not modified since creation';
    } else {
      String modifiedByUser = _findUserName(_editableEntry.userIdLastModified);
      return 'Last Modified: ${_formatDateTime(
          _editableEntry.updatedAt)} by $modifiedByUser';
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
}
