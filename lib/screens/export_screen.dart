import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:cashbook/stores/export_store.dart';
import 'package:cashbook/services/locator.dart';
import 'package:logging/logging.dart';

class ExportScreen extends StatefulWidget {
  @override
  _ExportScreenState createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  final _log = Logger('_ExportScreenState');
  final ExportStore _exportStore = locator<ExportStore>();
  bool _exportDocuments = true;
  bool _convertToJpeg = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Export Management'),
        leading: const BackButton(),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCreateSection(),
            // Placeholder for the future list of exports
          ],
        ),
      ),
    );
  }

  Widget _buildCreateSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Observer(
          builder: (_) => CheckboxListTile(
            title: const Text('Export Documents'),
            value: _exportDocuments,
            onChanged: (bool? value) {
              setState(() {
                _exportDocuments = value!;
                if (!value) {
                  _convertToJpeg = false;
                }
              });
            },
          ),
        ),
        Observer(
          builder: (_) => CheckboxListTile(
            title: const Text('Convert Documents to JPEG'),
            value: _convertToJpeg,
            onChanged: _exportDocuments
                ? (bool? value) {
                    setState(() {
                      _convertToJpeg = value!;
                    });
                  }
                : null,
          ),
        ),
        ElevatedButton(
          onPressed: _createExport,
          child: const Text('Create Export'),
        ),
      ],
    );
  }

  Future<void> _createExport() async {
    try {
      await _exportStore.createExport(_exportDocuments, _convertToJpeg);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Creating export in Background. This will take a while')),
        );
        _log.info('Started creating export');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error creating export')));
        _log.warning('Error creating export: $e');
      }
    }
  }
}
