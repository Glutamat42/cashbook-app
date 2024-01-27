import 'dart:typed_data';

import 'package:cashbook/dialogs/new_category_dialog.dart';
import 'package:cashbook/services/locator.dart';
import 'package:cashbook/stores/category_store.dart';
import 'package:cashbook/utils/csv_processor.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:logging/logging.dart';

class CsvImportScreen extends StatefulWidget {
  @override
  _CsvImportScreenState createState() => _CsvImportScreenState();
}

class _CsvImportScreenState extends State<CsvImportScreen> {
  final Logger _log = Logger('_CsvImportScreenState');
  Uint8List? csvData;
  List<String>? csvHeaders;
  String? selectedFileName;
  Map<String, String?> fieldMappings = {};
  final _formKey = GlobalKey<FormState>();
  final CategoryStore _categoryStore = locator<CategoryStore>();

  @override
  void initState() {
    super.initState();
    if (_categoryStore.categories.isEmpty) {
      _categoryStore.loadCategories();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("CSV Import"),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              csvHeaders != null
                  ? Text("Selected File: $selectedFileName")
                  : ElevatedButton(
                      onPressed: () => pickCsvFile(context),
                      child: const Text('Pick CSV File'),
                    ),
              Divider(),
              if (csvHeaders != null) buildFieldMappingArea(context),
              // Additional option fields go here, enabled based on isFilePicked
            ],
          ),
        ),
      ),
    );
  }

  void pickCsvFile(BuildContext context) async {
    FilePickerResult? result =
        await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['csv'], withData: true);
    Uint8List? csvSourceData = result?.files.single.bytes;

    if (result != null) {
      List<String>? parsedData;
      try {
        parsedData = CsvParser.processCsv(csvSourceData!);
      } catch (e) {
        _log.warning("Failed to parse CSV file: ${e.toString()}");
        // show snackbar
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Failed to parse CSV file"),
            ),
          );
        }
        return;
      }
      setState(() {
        csvHeaders = parsedData;
        csvData = csvSourceData;
        selectedFileName = result.files.single.name;
      });
    }
  }

  void updateFieldMapping(String field, String? value) {
    setState(() {
      fieldMappings[field] = value == "---" ? null : value;
    });
  }

  Widget buildFieldMappingArea(BuildContext context) {
    var selectableHeaders = List<String>.from(csvHeaders!);
    selectableHeaders.insert(0, "---");

    List<String> categories = _categoryStore.categories.map((category) => category.name).toList();
    if (categories.isEmpty) {
      // show error snackbar
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("There has to be at least one category."),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    categories.insert(0, "---");

    List<String> incomeOptions = ["---", "Positive amount as Income", "Negative amount as Income"];

//todo make dropdown values unique
    return Form(
      key: _formKey, // Define this key in your state class
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          buildDropdown("description", "Description", selectableHeaders, required: true),
          buildDropdown("recipientSender", "Recipient/Sender", selectableHeaders, required: true),
          buildDropdown("date", "Date", selectableHeaders),
          buildDropdown("paymentMethod", "Payment Method", selectableHeaders),
          buildDropdown("noInvoice", "No Invoice", selectableHeaders),

          buildDropdown("category", "Category", selectableHeaders, enabled: true),
          buildDropdown(
            "category_default",
            "Category (default)",
            categories,
            required: true,
            trailing: _buildAddCategoryButton(context),
          ),

          // Special handling for the isIncome field
          buildDropdown("amount", "Amount", selectableHeaders, required: true),
          buildDropdown("isIncome", "Is Income", incomeOptions, required: true),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                _log.info("Form validated");
                // Handle form submission
              } else {
                _log.info("Form validation failed");
              }
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  Widget _buildAddCategoryButton(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.add),
      onPressed: () {
        _log.fine('Add new category');
        NewCategoryDialog(
          context,
          onChanged: (int? newCategoryId) {
            if (newCategoryId != null) {
              setState(() {
                fieldMappings["category_default"] = _categoryStore.findCategoryName(newCategoryId);
              });
            }
          },
        ).showCategoryDialog();
      },
    );
  }

  Widget buildDropdown(String fieldValue, String title, List<String> headers,
      {bool enabled = true, bool required = false, Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 1,
            child: Text(
              title + (required ? " *" : ""),
              style: TextStyle(fontWeight: required ? FontWeight.bold : FontWeight.normal),
            ),
          ),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: fieldMappings[fieldValue] ?? "---",
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    onChanged: enabled
                        ? (String? newValue) {
                            updateFieldMapping(fieldValue, newValue);
                          }
                        : null,
                    validator: (value) {
                      if (required &&
                          (!fieldMappings.containsKey(fieldValue) ||
                              fieldMappings[fieldValue] == null ||
                              fieldMappings[fieldValue]!.isEmpty)) {
                        return 'Please select a value for $title';
                      }
                      return null;
                    },
                    items: headers.map<DropdownMenuItem<String>>((String header) {
                      return DropdownMenuItem<String>(
                        value: header,
                        child: Text(header),
                      );
                    }).toList(),
                  ),
                ),
                if (trailing != null) trailing
              ],
            ),
          ),
        ],
      ),
    );
  }
}
