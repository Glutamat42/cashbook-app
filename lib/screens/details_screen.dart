import 'package:cashbook/stores/entry_store.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import '../models/entry.dart';
import '../models/user.dart';
import '../stores/user_store.dart';
import '../services/locator.dart';
import '../widgets/document_section.dart';
import '../widgets/dual_mode_amount_widget.dart';
import '../widgets/dual_mode_category_widget.dart';
import '../widgets/dual_mode_date_widget.dart';
import '../widgets/dual_mode_invoice_checkbox.dart';
import '../widgets/dual_mode_payment_method_widget.dart';
import '../widgets/dual_mode_text_widget.dart';
import '../widgets/flexible_detail_item_view.dart';

class DetailsScreen extends StatefulWidget {
  final Entry entry;

  const DetailsScreen({Key? key, required this.entry}) : super(key: key);

  @override
  _DetailsScreenState createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> {
  late Entry _editableEntry;
  final Logger _log = Logger('DetailsScreen');
  bool _isEditMode = false;
  bool _isNew = false;
  DateTime? _currentlySelectedDate;
  AutovalidateMode _autoValidate = AutovalidateMode.disabled;
  final UserStore _userStore = locator<UserStore>();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _recipientSenderController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  final EntryStore _entryStore = locator<EntryStore>();

  @override
  void initState() {
    super.initState();
    _isNew = widget.entry.id == null;
    if (_isNew) {
      _isEditMode = true;
    }
    _editableEntry = Entry.fromJson(widget.entry.toJson());

    _recipientSenderController.text = _editableEntry.recipientSender ?? '';
    _descriptionController.text = _editableEntry.description ?? '';

    _currentlySelectedDate = _editableEntry.date;
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
            setState(() {
              _isEditMode = false;
            });
            if (_isNew) {
              if (context.mounted) Navigator.of(context).pop();
            }
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Entry Details'),
          actions: <Widget>[
            // IconButton(
            //   icon: Icon(Icons.delete),
            //     onPressed: onPressed
            // ),
            IconButton(
              icon: Icon(_isEditMode ? Icons.check : Icons.edit),
              onPressed: () async {
                if (_isEditMode) {
                  if (await _saveEntry()) {
                    setState(() {
                      _isEditMode = false;
                    });
                  }
                } else {
                  setState(() => _isEditMode = !_isEditMode);
                }
              },
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            autovalidateMode: _autoValidate,
            child: ListView(
              children: <Widget>[
                DualModeTextWidget(
                  isEditMode: _isEditMode,
                  controller: _recipientSenderController,
                  label: 'Recipient/Sender',
                  validator: (value) => value!.isEmpty ? 'This field cannot be empty' : null,
                ),
                DualModeTextWidget(
                  isEditMode: _isEditMode,
                  controller: _descriptionController,
                  label: 'Description',
                  validator: (value) => value!.isEmpty ? 'This field cannot be empty' : null,
                ),
                DualModeAmountWidget(
                  isEditMode: _isEditMode,
                  amount: _editableEntry.amount,
                  isIncome: _editableEntry.isIncome,
                  onChanged: (amount, isIncome) => setState(() {
                    _editableEntry.amount = amount;
                    _editableEntry.isIncome = isIncome;
                  }),
                ),
                DualModeDateWidget(
                  isEditMode: _isEditMode,
                  date: _currentlySelectedDate,
                  onChanged: (date) => setState(() => _currentlySelectedDate = date),
                  validator: (_) {
                    if (_currentlySelectedDate == null) {
                      return 'Please select a date';
                    }
                    if (_currentlySelectedDate!.isBefore(DateTime(2000))) {
                      return 'Date cannot be before year 2000';
                    }
                  },
                ),
                DocumentSection(
                  isEditable: _isEditMode,
                  entryId: _editableEntry.id,
                ),
                DualModeInvoiceCheckbox(
                  isEditMode: _isEditMode,
                  noInvoice: _editableEntry.noInvoice,
                  onChanged: (val) => setState(() => _editableEntry.noInvoice = val),
                ),
                DualModeCategoryWidget(
                  isEditMode: _isEditMode,
                  categoryId: _editableEntry.categoryId,
                  onChanged: (newCategoryId) => _editableEntry.categoryId = newCategoryId,
                  validator: (value) => value == null ? 'Please select a category' : null,
                ),
                DualModePaymentMethodWidget(
                  isEditMode: _isEditMode,
                  paymentMethod: _editableEntry.paymentMethod,
                  onChanged: (val) => setState(() => _editableEntry.paymentMethod = val),
                ),
                ..._buildCreatedModifiedInfo(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _recipientSenderController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _discardChanges(context) {
    if (!_isNew) {
      setState(() {
        _editableEntry = Entry.fromJson(widget.entry.toJson()); // Revert to original state
      });
    }
  }

  Future<bool> _saveEntry() async {
    setState(() {
      _autoValidate = AutovalidateMode.always;
    });
    if (_formKey.currentState!.validate()) {
      try {
        Entry updatedEntry;

        // assemble updatedEntry from controllers and values
        _editableEntry.recipientSender = _recipientSenderController.text;
        _editableEntry.description = _descriptionController.text;
        _editableEntry.date = _currentlySelectedDate!;


        if (_isNew) {
          updatedEntry = await _entryStore.createEntry(_editableEntry);
          _showSnackbar(context, 'Entry created successfully', Colors.green);
        } else {
          updatedEntry = await _entryStore.updateEntry(_editableEntry);
          _showSnackbar(context, 'Changes saved successfully', Colors.green);
        }
        // As _editableEntry might get updated from widget.entry it has to be updated
        widget.entry.updateFrom(updatedEntry);
        setState(() {
          // Update _editableEntry to reflect serverside changes (e.g. id, updatedAt, etc.)
          _editableEntry.updateFrom(updatedEntry);
        });
      } catch (error) {
        _showSnackbar(context, 'Failed to save changes: ${error.toString()}', Colors.red);
        _log.warning('Error saving entry: $error');
        return false;
      }
      return true;
    }
    _log.info('Form validation failed');
    return false;
  }

  void _showSnackbar(BuildContext context, String message, Color backgroundColor) {
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
      return '${_formatDateTime(_editableEntry.updatedAt)} by $modifiedByUser';
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

  Future<bool> _showSaveChangesDialog(BuildContext context) async {
    return (await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
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
            onPressed: () async {
              if (await _saveEntry()) {
                if (context.mounted) Navigator.of(context).pop(true);
              }
            },
          ),
        ],
      ),
    )) ??
        false;
  }
}
