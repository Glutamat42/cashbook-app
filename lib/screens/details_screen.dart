import 'package:cashbook/stores/category_store.dart';
import 'package:cashbook/stores/entry_store.dart';
import 'package:cashbook/widgets/details_screen_widget/dual_mode_widgets/document_section.dart';
import 'package:cashbook/widgets/details_screen_widget/dual_mode_widgets/dual_mode_amount_widget.dart';
import 'package:cashbook/widgets/details_screen_widget/dual_mode_widgets/dual_mode_category_widget.dart';
import 'package:cashbook/widgets/details_screen_widget/dual_mode_widgets/dual_mode_date_widget.dart';
import 'package:cashbook/widgets/details_screen_widget/dual_mode_widgets/dual_mode_invoice_checkbox.dart';
import 'package:cashbook/widgets/details_screen_widget/dual_mode_widgets/dual_mode_payment_method_widget.dart';
import 'package:cashbook/widgets/details_screen_widget/dual_mode_widgets/dual_mode_text_widget.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import '../models/document.dart';
import '../models/entry.dart';
import '../models/user.dart';
import '../stores/user_store.dart';
import '../services/locator.dart';
import '../widgets/details_screen_widget/flexible_detail_item_view.dart';
// todo proper navigation url to this page
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
  final EntryStore _entryStore = locator<EntryStore>();
  final CategoryStore _categoryStore = locator<CategoryStore>();
  final _formKey = GlobalKey<FormState>();
  late List<Document> documents = [];
  late Future loadDocumentsFuture;
  late Entry entry;

  final TextEditingController _recipientSenderController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  @override
  void initState() {
    _isNew = widget.entry.id == null;
    if (_isNew) {
      _isEditMode = true;
      loadDocumentsFuture = Future.value([]);
      entry = widget.entry; // is new entry, refresh is not relevant here
    } else {
      entry = _entryStore.allEntries.firstWhere((e) => e.id == widget.entry.id);
      loadDocumentsFuture = _entryStore.loadDocumentsForEntry(entry.id!);
    }
    _editableEntry = Entry.fromJson(entry.toJson());

    _recipientSenderController.text = _editableEntry.recipientSender ?? '';
    _descriptionController.text = _editableEntry.description ?? '';

    _currentlySelectedDate = _editableEntry.date;
    super.initState();
  }


  @override
  Widget build(BuildContext context) {
    _log.fine('InitState, entry: ${entry.toJson()}');
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
            // IconButton( // TODO: implement deleteentry
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
          child: _isEditMode ? _buildForm() : RefreshIndicator(
            onRefresh: _refreshData,
            child: _buildForm(),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      autovalidateMode: _autoValidate,
      child: ListView(
        children: <Widget>[
          DualModeTextWidget(
            isEditMode: _isEditMode,
            controller: _recipientSenderController,
            label: 'Recipient/Sender',
            validator: (value) => value!.isEmpty ? 'This field cannot be empty' : null,
            suggestions: _entryStore.allEntries.map((e) => e.recipientSender).toSet().toList(),
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
            onChanged: (amount, isIncome) =>
                setState(() {
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
          FutureBuilder(
            future: loadDocumentsFuture,
            builder: (context, data) {
              bool isLoading = false;
              if (data.connectionState == ConnectionState.done) {
                if (documents.isEmpty && !_isNew) {
                  documents = _entryStore.entryDocuments[entry.id!] ?? [];
                }
              } else {
                isLoading = true;
              }
              return DocumentSection(
                isEditable: _isEditMode,
                entryId: _editableEntry.id,
                isLoading: isLoading,
                documents: documents,
                onDocumentsChanged: (List<Document> updatedDocuments) {
                  setState(() => documents = updatedDocuments);
                },
              );
            },
          ),
          DualModeInvoiceCheckbox(
            isEditMode: _isEditMode,
            noInvoice: _editableEntry.noInvoice,
            onChanged: (val) => setState(() => _editableEntry.noInvoice = val),
          ),
          DualModeCategoryWidget(
            isEditMode: _isEditMode,
            categoryId: _editableEntry.categoryId,
            onChanged: (newCategoryId) => setState(() => _editableEntry.categoryId = newCategoryId),
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
    );
  }

  Future<void> _refreshData() async {
    if (_isEditMode) {
      _log.warning('Refresh data called in edit mode');
      return; // just ensure this is only called in view mode
    }
    try {
      setState(() {
        loadDocumentsFuture = _entryStore.loadDocumentsForEntry(entry.id!);
      });
      _entryStore.loadEntries().then((value) => setState(() {
        entry = _entryStore.allEntries.firstWhere((e) => e.id == entry.id);
        _editableEntry = Entry.fromJson(entry.toJson());
        _recipientSenderController.text = _editableEntry.recipientSender ?? '';
        _descriptionController.text = _editableEntry.description ?? '';
        _currentlySelectedDate = _editableEntry.date;
      }));
      _categoryStore.loadCategories();
    } catch (e) {
      _log.warning('Error refreshing data: $e');
    }
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
        _editableEntry = Entry.fromJson(entry.toJson()); // Revert to original state
        documents = _entryStore.entryDocuments[entry.id!] ?? [];
      });
    }
  }

  Future<bool> _saveEntry() async {
    setState(() {
      _autoValidate = AutovalidateMode.always;
    });
    if (_formKey.currentState!.validate()) {
      try {
        _editableEntry.recipientSender = _recipientSenderController.text;
        _editableEntry.description = _descriptionController.text;
        _editableEntry.date = _currentlySelectedDate!;


        Entry updatedEntry;
        if (_isNew) {
          updatedEntry = await _entryStore.createEntry(_editableEntry, documents);
          _showSnackbar(context, 'Entry created successfully', Colors.green);
        } else {
          updatedEntry = await _entryStore.updateEntry(_editableEntry, documents);
          _showSnackbar(context, 'Changes saved successfully', Colors.green);
        }

        // As _editableEntry might get updated from entry it has to be updated
        entry.updateFrom(updatedEntry);
        setState(() {
          // Update _editableEntry to reflect serverside changes (e.g. id, updatedAt, etc.)
          _editableEntry.updateFrom(updatedEntry);
          // refresh documents
          loadDocumentsFuture = _entryStore.loadDocumentsForEntry(updatedEntry.id!);
        });
      } catch (error) {
        // TODO: show correct error message if request is too large
        // glaube da war ein error code der da kommen kann (wenn nginx wert zu klein)
        // oder das: {"errors":{"document.0":["The document.0 failed to upload."]}}
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
