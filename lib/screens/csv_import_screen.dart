import 'dart:typed_data';

import 'package:cashbook/dialogs/new_category_dialog.dart';
import 'package:cashbook/models/category.dart';
import 'package:cashbook/services/locator.dart';
import 'package:cashbook/stores/category_store.dart';
import 'package:cashbook/utils/csv_processor.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:logging/logging.dart';

enum MergeStrategy { fillEmpty, overrideExisting }

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
  Map<String, MergeStrategy> mergeStrategy = {
    "description": MergeStrategy.fillEmpty,
    "recipientSender": MergeStrategy.fillEmpty,
    "date": MergeStrategy.fillEmpty,
    "paymentMethod": MergeStrategy.fillEmpty,
    "category": MergeStrategy.fillEmpty,
    "category_default": MergeStrategy.fillEmpty,
    "amount": MergeStrategy.fillEmpty,
    "isIncome": MergeStrategy.fillEmpty,
  };
  final _formKey = GlobalKey<FormState>();
  final CategoryStore _categoryStore = locator<CategoryStore>();
  bool showMergeStrategyOptions = false;
  final List<String> incomeOptions = ["---", "Positive amount as Income", "Negative amount as Income"];

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
              _buildCsvSelectionArea(csvHeaders != null),
              const Divider(),
              if (csvHeaders != null) ...[
                _buildTemplateSelectionArea(),
                const Divider(),
                buildFieldMappingArea(context),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTemplateSelectionArea() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Text("Select a template"),
          const SizedBox(height: 10),
          Row(
            children: [
              OutlinedButton(
                  onPressed: () {
                    String? defaultCategoryName;
                    try {
                      defaultCategoryName = _categoryStore.categories.firstWhere((element) => element.name == "Imported").name;
                    } catch (e) {
                      _log.info("Failed to find category 'Imported'. This is expected if it was not yet manually created: ${e.toString()}");
                      defaultCategoryName = null;
                      // show snackbar
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Category 'Imported' not found. Please create it manually or select another category as default."),
                          ),
                        );
                      }
                    }
                    setState(() {
                      fieldMappings = {
                        "description": "Verwendungszweck",
                        "recipientSender": "Beguenstigter/Zahlungspflichtiger",
                        "date": "Buchungstag",
                        "paymentMethod_default": "bank_transfer",
                        "category": null,
                        "category_default": defaultCategoryName,
                        "amount": "Betrag",
                        "isIncome": incomeOptions[1],
                      };
                    });
                  },
                  child: Text("Sparkasse")),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildCsvSelectionArea(bool csvSelected) {
    if (csvSelected) {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Text("Selected File: $selectedFileName"),
            const SizedBox(height: 10),
            Row(
              children: [
                const Expanded(child: Text("Show Merge Strategy Options. Default: Only fill empty fields")),
                Switch(
                    value: showMergeStrategyOptions,
                    onChanged: (bool state) => setState(() => showMergeStrategyOptions = state)),
              ],
            )
          ],
        ),
      );
    } else {
      return ElevatedButton(
        onPressed: () => pickCsvFile(context),
        child: const Text('Pick CSV File'),
      );
    }
  }

  Widget _buildMergeStrategyRadioButtons(MergeStrategy state, Function(MergeStrategy) onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Expanded(
          child: Row(children: [
            Radio<MergeStrategy>(
              value: MergeStrategy.fillEmpty,
              groupValue: state,
              onChanged: (MergeStrategy? value) {
                onChanged(value!);
              },
            ),
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () {
                  onChanged(MergeStrategy.fillEmpty);
                },
                child: const Text('Fill Empty', style: TextStyle(fontSize: 16.0)),
              ),
            ),
          ]),
        ),
        Expanded(
          child: Row(children: [
            Radio<MergeStrategy>(
              value: MergeStrategy.overrideExisting,
              groupValue: state,
              onChanged: (MergeStrategy? value) {
                onChanged(value!);
              },
            ),
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () {
                  onChanged(MergeStrategy.overrideExisting);
                },
                child: const Text('Override', style: TextStyle(fontSize: 16.0)),
              ),
            ),
          ]),
        ),
      ],
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



    return Form(
      key: _formKey, // Define this key in your state class
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          buildDropdown("description", "Description", selectableHeaders, required: true),
          if (showMergeStrategyOptions)
            _buildMergeStrategyRow(mergeStrategy["description"]!, (MergeStrategy state) {
              setState(() {
                mergeStrategy["description"] = state;
              });
            }),
          const Divider(),
          buildDropdown("recipientSender", "Recipient/Sender", selectableHeaders, required: true),
          if (showMergeStrategyOptions)
            _buildMergeStrategyRow(mergeStrategy["recipientSender"]!, (MergeStrategy state) {
              setState(() {
                mergeStrategy["recipientSender"] = state;
              });
            }),
          const Divider(),
          buildDropdown("date", "Date", selectableHeaders),
          if (showMergeStrategyOptions)
            _buildMergeStrategyRow(mergeStrategy["date"]!, (MergeStrategy state) {
              setState(() {
                mergeStrategy["date"] = state;
              });
            }),
          const Divider(),
          buildDropdown("paymentMethod_default", "Payment Method (default)", ['cash', 'bank_transfer', 'not_payed']),
          if (showMergeStrategyOptions)
            _buildMergeStrategyRow(mergeStrategy["paymentMethod"]!, (MergeStrategy state) {
              setState(() {
                mergeStrategy["paymentMethod"] = state;
              });
            }),
          const Divider(),
          // buildDropdown("noInvoice", "No Invoice", selectableHeaders),

          buildDropdown("category", "Category", selectableHeaders, enabled: true),
          buildDropdown(
            "category_default",
            "Category (default)",
            categories,
            required: true,
            trailing: _buildAddCategoryButton(context),
          ),
          if (showMergeStrategyOptions)
            _buildMergeStrategyRow(mergeStrategy["category"]!, (MergeStrategy state) {
              setState(() {
                mergeStrategy["category"] = state;
              });
            }),
          const Divider(),

          // Special handling for the isIncome field
          buildDropdown("amount", "Amount", selectableHeaders, required: true),
          if (showMergeStrategyOptions)
            _buildMergeStrategyRow(mergeStrategy["amount"]!, (MergeStrategy state) {
              setState(() {
                mergeStrategy["amount"] = state;
              });
            }),
          const Divider(),
          buildDropdown("isIncome", "Is Income", incomeOptions, required: true),
          if (showMergeStrategyOptions)
            _buildMergeStrategyRow(mergeStrategy["isIncome"]!, (MergeStrategy state) {
              setState(() {
                mergeStrategy["isIncome"] = state;
              });
            }),
          const Divider(),

          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
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
          ),
        ],
      ),
    );
  }

  Widget _buildMergeStrategyRow(MergeStrategy state, Function(MergeStrategy) onChanged) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8.0, 4, 8.0, 4),
      child: Row(
        children: [
          const Expanded(flex: 1, child: Text("merge strategy")),
          Expanded(flex: 2, child: _buildMergeStrategyRadioButtons(state, onChanged)),
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
      padding: const EdgeInsets.fromLTRB(8.0, 4, 8.0, 4),
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
                        return 'Please select a value.';
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
