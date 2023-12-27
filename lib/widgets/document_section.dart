import 'dart:io';

import 'package:cashbook/stores/entry_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logging/logging.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:mime/mime.dart';
import '../models/document.dart';
import '../models/local_document.dart';
import '../models/remote_document.dart';
import '../services/locator.dart';
import '../stores/auth_store.dart';
import 'document_gallery_viewer.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform;

class DocumentSection extends StatefulWidget {
  final int? entryId;
  final bool isEditable;

  const DocumentSection({Key? key, required this.entryId, this.isEditable = false})
      : super(key: key);

  @override
  State<DocumentSection> createState() => _DocumentSectionState();
}

class _DocumentSectionState extends State<DocumentSection> {
  final Logger _log = Logger('DocumentSection');
  final EntryStore _entryStore = locator<EntryStore>();
  List<Document> documents = [];
  late final isNew;
  late Future loadDocumentsFuture;

  @override
  void initState() {
    isNew = widget.entryId == null;
    if (!isNew) {
      loadDocumentsFuture = _entryStore.loadDocumentsForEntry(widget.entryId!);
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: loadDocumentsFuture,
      builder: (context, data) {
        if (data.connectionState == ConnectionState.done) {
          return _buildDocumentSection(context);
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }

  Widget _buildDocumentSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text('Documents (Images, PDFs)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Observer(
            builder: (_) {
              int itemCount = widget.isEditable
                  ? documents.length + 1 // +1 for add button if editable
                  : documents.length;
              return Container(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: itemCount,
                  itemBuilder: (context, index) {
                    if (widget.isEditable && index == 0) {
                      return _buildAddButton(context);
                    }
                    int docIndex =
                        widget.isEditable ? index - 1 : index; // Adjust index if in editable mode
                    return _buildThumbnailTile(documents, docIndex, context);
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton(BuildContext context) {
    return GestureDetector(
      onTap: () => _addDocument(context),
      child: Container(
        width: 100,
        height: 100,
        margin: const EdgeInsets.only(right: 8),
        color: Colors.grey[300],
        child: const Center(child: Icon(Icons.add)),
      ),
    );
  }

  Future<void> _addDocument(BuildContext context) async {
    if (kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.linux ||
            defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.macOS)) {
      // Directly open file dialog for desktop web platforms
      final pickedFile = await FilePicker.platform.pickFiles();
      if (pickedFile != null && pickedFile.files.single.path != null) {
        _uploadDocument(pickedFile.files.single.path!, context, widget.entryId!);
      }
    } else {
      _showMobileAddDocumentOptions(context);
    }
  }

  void _showMobileAddDocumentOptions(BuildContext context) {
    final picker = ImagePicker();
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Gallery'),
                  onTap: () async {
                    Navigator.pop(context);
                    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                    if (pickedFile != null) {
                      _uploadDocument(pickedFile.path, context, widget.entryId!);
                    }
                  }),
              ListTile(
                  leading: const Icon(Icons.photo_camera),
                  title: const Text('Camera'),
                  onTap: () async {
                    Navigator.pop(context);
                    final pickedFile = await picker.pickImage(source: ImageSource.camera);
                    if (pickedFile != null) {
                      _uploadDocument(pickedFile.path, context, widget.entryId!);
                    }
                  }),
              ListTile(
                  leading: const Icon(Icons.attach_file),
                  title: const Text('File'),
                  onTap: () async {
                    Navigator.pop(context);
                    try {
                      final pickedFile = await FilePicker.platform.pickFiles(
                        type: FileType.custom,
                        allowedExtensions: [
                          'pdf',
                          'jpg',
                          'jpeg',
                          'png',
                          'gif',
                          'bmp',
                          'tiff',
                          'tif',
                          'webp',
                          'avif'
                        ],
                      );
                      if (pickedFile != null && pickedFile.files.single.path != null) {
                        _uploadDocument(pickedFile.files.single.path!, context, widget.entryId!);
                      }
                    } on PlatformException catch (e) {
                      if (e.code == 'read_external_storage_denied') {
                        _log.warning('Permission denied: ${e.toString()}');

                        const snackBar = SnackBar(
                          content: Text('No permission to access files'),
                          backgroundColor: Colors.red,
                        );
                        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(snackBar);
                      } else {
                        _log.warning('Error picking file: ${e.toString()}');

                        const snackBar = SnackBar(
                          content: Text('Error picking file'),
                          backgroundColor: Colors.red,
                        );
                        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(snackBar);
                      }
                    } catch (e) {
                      _log.warning('Error picking file: ${e.toString()}');

                      const snackBar = SnackBar(
                        content: Text('Error picking file'),
                        backgroundColor: Colors.red,
                      );
                      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(snackBar);
                    }
                  }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildThumbnailTile(List<Document> documents, int index, context) {
    Document document = documents[index];
    AuthStore authStore = locator<AuthStore>();
    String token = authStore.user?.token ?? "";

    if (token.isEmpty) {
      throw Exception("Token is empty");
    }

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => DocumentGalleryViewer(
            initialIndex: index,
            documents: documents,
          ),
        ));
      },
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: 8),
        color: Colors.grey[300],
        child: _buildImage(document, authStore.baseUrl!, token),
      ),
    );
  }

  Widget _buildImage(Document document, String baseUrl, String token) {
    if (document is RemoteDocument) {
      return Image.network(
        '$baseUrl/${document.thumbnailLink}',
        headers: {'Authorization': 'Bearer $token'},
        fit: BoxFit.cover,
      );
    } else {
      if (lookupMimeType(document.thumbnailLink) == 'application/pdf') {
        return const Icon(Symbols.picture_as_pdf);
      }
      return Image.file(
        File(document.thumbnailLink),
        fit: BoxFit.cover,
      );
    }
  }

  void _uploadDocument(String filePath, BuildContext context, int entryId) {
    setState(() {
      documents.add(LocalDocument(filePath: filePath, id: -(documents.length - 1), entryId: entryId));
    });
    _log.info('Uploading document: $filePath');
    // Implement the logic to upload the document
    // After uploading, update the EntryStore with the new document
    // e.g., entryStore.addDocumentToEntry(entryId, uploadedDocument);
  }
}
