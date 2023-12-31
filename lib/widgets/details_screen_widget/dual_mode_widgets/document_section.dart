import 'dart:io';

import 'package:cashbook/models/document.dart';
import 'package:cashbook/models/local_document.dart';
import 'package:cashbook/models/remote_document.dart';
import 'package:cashbook/services/locator.dart';
import 'package:cashbook/stores/auth_store.dart';
import 'package:cashbook/utils/helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logging/logging.dart';
import 'package:mime/mime.dart' as mime;
import '../document_gallery_viewer.dart';
import 'package:file_picker/file_picker.dart';

class DocumentSection extends StatelessWidget {
  final Logger _log = Logger('DocumentSection');
  final int? entryId;
  final bool isEditable;
  final bool isLoading;
  final List<Document> documents;
  final Function(List<Document>) onDocumentsChanged;

  DocumentSection({
    Key? key,
    required this.entryId,
    this.isEditable = false,
    required this.isLoading,
    required this.documents,
    required this.onDocumentsChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isNew = entryId == null;
    return _buildDocumentSection(context, isNew);
  }

  Widget _buildDocumentSection(BuildContext context, bool isNew) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text('Documents (Images, PDFs)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Observer(
            builder: (_) =>
               SizedBox(
                height: 100,
                child: isLoading && !isNew ? const Center(child: CircularProgressIndicator()) :ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: isEditable ? documents.length + 1 : documents.length, // +1 for add button if editable
                  itemBuilder: (context, index) {
                    if (isEditable && index == 0) {
                      return _buildAddButton(context);
                    }
                    int docIndex = isEditable ? index - 1 : index; // Adjust index if in editable mode
                    return _buildThumbnailTile(documents, docIndex, context);
                  },
                ),
              )
          )
    ]
            ,
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
    if (Helpers.isDesktopWebBrowser) {
      // Directly open file dialog for desktop web platforms
      final FilePickerResult? pickedFile = await FilePicker.platform.pickFiles();
      if (pickedFile != null && context.mounted) {
        _newDocumentOpened(pickedFile.files.single.bytes!, pickedFile.files.single.name, context, entryId);
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
                    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);
                    if (pickedFile != null && context.mounted) {
                      _newDocumentOpened(await pickedFile.readAsBytes(), pickedFile.name, context, entryId);
                    }
                  }),
              ListTile(
                  leading: const Icon(Icons.photo_camera),
                  title: const Text('Camera'),
                  onTap: () async {
                    Navigator.pop(context);
                    final XFile? pickedFile = await picker.pickImage(source: ImageSource.camera);
                    if (pickedFile != null && context.mounted) {
                      _newDocumentOpened(await pickedFile.readAsBytes(), pickedFile.name, context, entryId);
                    }
                  }),
              ListTile(
                  leading: const Icon(Icons.attach_file),
                  title: const Text('File'),
                  onTap: () async {
                    Navigator.pop(context);
                    try {
                      final FilePickerResult? pickedFile = await FilePicker.platform.pickFiles(
                        type: FileType.custom,
                        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'gif', 'bmp', 'tiff', 'tif', 'webp', 'avif'],
                      );
                      if (pickedFile != null &&
                          (pickedFile.files.single.bytes != null || pickedFile.files.single.path != null) &&
                          context.mounted) {
                        Uint8List bytes =
                            pickedFile.files.single.bytes ?? File(pickedFile.files.single.path!).readAsBytesSync();
                        _newDocumentOpened(bytes, pickedFile.files.single.name, context, entryId);
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
            showDeleteButton: isEditable,
            onDocumentDeleted: isEditable ? (int id) => _documentDeletedChanged(id, true) : null,
            onDocumentUndeleted: isEditable ? (int id) => _documentDeletedChanged(id, false) : null,
          ),
        ));
      },
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: 8),
        color: Colors.grey[300],
        child: _buildImageWithDeletionState(document, authStore.baseUrl!, token),
      ),
    );
  }

  Widget _buildImageWithDeletionState(Document document, String baseUrl, String token) {
    if (document.deleted) {
      return ClipRect(
        child: ColorFiltered(
          colorFilter: const ColorFilter.mode(
            Colors.grey,
            BlendMode.saturation,
          ),
          child: _buildImage(document, baseUrl, token),
        ),
      );
    } else {
      return _buildImage(document, baseUrl, token);
    }
  }

  Widget _buildImage(Document document, String baseUrl, String token) {
    if (document is RemoteDocument) {
      return Image.network(
        '$baseUrl/${document.thumbnailLink}',
        headers: {'Authorization': 'Bearer $token'},
        fit: BoxFit.cover,
      );
    } else {
      if (_getMimeType((document as LocalDocument).originalBinaryData) == 'application/pdf') {
        return Image.asset('/assets/images/icon-picture_as_pdf.png');
      }
      return Image.memory(
        document.thumbnailBinaryData,
        fit: BoxFit.cover,
      );
    }
  }

  String? _getMimeType(List<int> binaryFileData) {
    final List<int> header = binaryFileData.sublist(0, mime.defaultMagicNumbersMaxLength);

    // Empty string for the file name because it's not relevant.
    return mime.lookupMimeType('', headerBytes: header);
  }

  void _newDocumentOpened(Uint8List fileData, String filename, BuildContext context, int? entryId) {
    onDocumentsChanged([
      ...documents,
      LocalDocument(
          originalFilename: filename, fileBytes: fileData, id: _generateLikelyUniqueDocumentId(), entryId: entryId)
    ]);
  }

  void _documentDeletedChanged(int documentId, bool isDeleted) {
    onDocumentsChanged(documents.map((doc) {
      if (doc.id == documentId) {
        doc.deleted = isDeleted;
      }
      return doc;
    }).toList());
  }

  int _generateLikelyUniqueDocumentId() {
    return -(int.parse("${DateTime.now().millisecondsSinceEpoch}${documents.length + 1}"));
  }
}
