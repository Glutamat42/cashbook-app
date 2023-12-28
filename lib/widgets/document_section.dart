import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cashbook/stores/entry_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logging/logging.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:mime/mime.dart' as mime;
import '../utils/helpers.dart';
import '../models/document.dart';
import '../models/local_document.dart';
import '../models/remote_document.dart';
import '../services/locator.dart';
import '../stores/auth_store.dart';
import 'document_gallery_viewer.dart';
import 'package:file_picker/file_picker.dart';

class DocumentSection extends StatefulWidget {
  final int? entryId;
  final bool isEditable;
  final bool isLoading;
  final List<Document> documents;
  final Function(List<Document>) onDocumentsChanged;

  const DocumentSection({
    Key? key,
    required this.entryId,
    this.isEditable = false,
    required this.isLoading,
    required this.documents,
    required this.onDocumentsChanged,
  }) : super(key: key);

  @override
  State<DocumentSection> createState() => _DocumentSectionState();
}
// TODO: convert to stateless
class _DocumentSectionState extends State<DocumentSection> {
  final Logger _log = Logger('DocumentSection');
  late final isNew;

  @override
  void initState() {
    isNew = widget.entryId == null;
    if (!isNew) {}
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (isNew) {
      return _buildDocumentSection(context);
    } else {
      if (!widget.isLoading) {
        return _buildDocumentSection(context);
      } else {
        return const Center(child: CircularProgressIndicator());
      }
    }
  }

  Widget _buildDocumentSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text('Documents (Images, PDFs)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Observer(
            builder: (_) {
              int itemCount = widget.isEditable
                  ? widget.documents.length + 1 // +1 for add button if editable
                  : widget.documents.length;
              return Container(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: itemCount,
                  itemBuilder: (context, index) {
                    if (widget.isEditable && index == 0) {
                      return _buildAddButton(context);
                    }
                    int docIndex = widget.isEditable ? index - 1 : index; // Adjust index if in editable mode
                    return _buildThumbnailTile(widget.documents, docIndex, context);
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
    if (Helpers.isDesktopWebBrowser) {
      // Directly open file dialog for desktop web platforms
      final FilePickerResult? pickedFile = await FilePicker.platform.pickFiles();
      if (pickedFile != null) {
        _newDocumentOpened(pickedFile.files.single.bytes!, pickedFile.files.single.name, context, widget.entryId);
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
                    if (pickedFile != null) {
                      _newDocumentOpened(await pickedFile.readAsBytes(), pickedFile.name, context, widget.entryId);
                    }
                  }),
              ListTile(
                  leading: const Icon(Icons.photo_camera),
                  title: const Text('Camera'),
                  onTap: () async {
                    Navigator.pop(context);
                    final XFile? pickedFile = await picker.pickImage(source: ImageSource.camera);
                    if (pickedFile != null) {
                      _newDocumentOpened(await pickedFile.readAsBytes(), pickedFile.name, context, widget.entryId);
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
                      if (pickedFile != null && // TODO
                          (pickedFile.files.single.bytes != null || pickedFile.files.single.path != null)) {
                        Uint8List bytes =
                            pickedFile.files.single.bytes ?? File(pickedFile.files.single.path!).readAsBytesSync();
                        _newDocumentOpened(bytes, pickedFile.files.single.name, context, widget.entryId);
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
            showDeleteButton: widget.isEditable,
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
      if (_getMimeType((document as LocalDocument).originalBinaryData) == 'application/pdf') {
        return const Icon(Symbols.picture_as_pdf);
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
    widget.onDocumentsChanged([
      ...widget.documents,
      LocalDocument(
          originalFilename: filename, fileBytes: fileData, id: _generateLikelyUniqueDocumentId(), entryId: entryId)
    ]);
  }

  void _documentDeleted(Document document) {
    widget.onDocumentsChanged(widget.documents.map((doc) {
      if (doc.id == document.id) {
        doc.deleted = true;
      }
      return doc;
    }).toList());
  }

  int _generateLikelyUniqueDocumentId() {
    return -(int.parse("${DateTime.now().millisecondsSinceEpoch}${widget.documents.length + 1}"));
  }
}
