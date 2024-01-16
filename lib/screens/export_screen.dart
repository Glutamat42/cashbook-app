import 'package:cashbook/models/export.dart';
import 'package:cashbook/stores/auth_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:cashbook/stores/export_store.dart';
import 'package:cashbook/services/locator.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:url_launcher/url_launcher.dart';

class ExportScreen extends StatefulWidget {
  @override
  _ExportScreenState createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  final _log = Logger('_ExportScreenState');
  final ExportStore _exportStore = locator<ExportStore>();
  final AuthStore _authStore = locator<AuthStore>();
  bool _exportDocuments = true;
  bool _convertToJpeg = true;

  @override
  void initState() {
    super.initState();
    _exportStore.fetchExports(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Export Management'),
        leading: const BackButton(),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _exportStore.fetchExports(refresh: true),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCreateSection(),
            const SizedBox(height: 16.0),
            const Divider(),
            const SizedBox(height: 16.0),
            Expanded(child: _buildExportList()),
          ],
        ),
      ),
    );
  }

  Widget _buildExportList() {
    return Observer(
      builder: (_) {
        final exports = _exportStore.exports;
        if (exports == null) {
          return const Center(child: CircularProgressIndicator());
        }
        if (exports.isEmpty) {
          return const Center(child: Text("No exports available"));
        }
        return RefreshIndicator(
          onRefresh: () => _exportStore.fetchExports(refresh: true),
          child: ListView.builder(
            itemCount: exports.length,
            itemBuilder: (context, index) {
              final export = exports[index];
              return ListTile(
                title: Text(DateFormat('dd.MM.yyyy HH:mm').format(export.createdTimestamp)),
                subtitle: Text(_buildExportSubtitle(export)),
                trailing: IconButton(
                  icon: const Icon(Icons.file_download),
                  onPressed: () => _downloadExport(export.downloadParameter),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _downloadExport(String downloadParameter) async {
    final baseUrl = _authStore.baseUrl;
    await launchUrl(Uri.parse('$baseUrl/api/export/download?$downloadParameter'));
  }

  String _buildExportSubtitle(Export export) {
    return "Achive format: ${export.archiveFormat.toUpperCase()}, ${export.containsDocuments ? 'With Documents${export.imagesConvertedToJpeg ? ' (JPEG)' : ''}' : 'No Documents'}, ${_formatFileSize(export.filesize)}MB";
  }

  String _formatFileSize(int filesize) {
    final fileSizeInMB = (filesize / (1024 * 1024)).toStringAsFixed(2);
    if (fileSizeInMB == '0.00') {
      return '<0.01';
    } else {
      return fileSizeInMB;
    }
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
        const SizedBox(height: 16.0),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ElevatedButton(
              onPressed: _createExport,
              child: const Text('Create Export'),
            ),
          ],
        )
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
