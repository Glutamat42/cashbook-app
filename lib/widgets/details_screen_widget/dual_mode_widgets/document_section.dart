import 'dart:io';

import 'package:cashbook/models/document.dart';
import 'package:cashbook/models/local_document.dart';
import 'package:cashbook/models/remote_document.dart';
import 'package:cashbook/utils/helpers.dart';
import 'package:cashbook/widgets/memory_image_with_avif.dart';
import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logging/logging.dart';
import '../document_gallery_viewer.dart';
import 'package:file_picker/file_picker.dart';

class DocumentSection extends StatelessWidget {
  final Logger _log = Logger('DocumentSection');
  final int? entryId;
  final bool isEditable;
  final bool isLoadingDocumentsList;
  final List<Document> documents;
  final Function(List<Document>) onDocumentsChanged;

  DocumentSection({
    Key? key,
    required this.entryId,
    this.isEditable = false,
    required this.isLoadingDocumentsList,
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
              builder: (_) => SizedBox(
                    height: 100,
                    child: isLoadingDocumentsList && !isNew
                        ? const Center(child: CircularProgressIndicator())
                        : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount:
                                isEditable ? documents.length + 1 : documents.length, // +1 for add button if editable
                            itemBuilder: (context, index) {
                              if (isEditable && index == 0) {
                                return _buildAddButton(context);
                              }
                              int docIndex = isEditable ? index - 1 : index; // Adjust index if in editable mode
                              return _buildThumbnailTile(documents, docIndex, context);
                            },
                          ),
                  ))
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
    if (Helpers.isDesktopWebBrowser || !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
      // Directly open file dialog for desktop web platforms
      final FilePickerResult? pickedFile = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          // heic, heif only work on ios and maybe other apple devices
          allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'gif', 'bmp', 'tiff', 'tif', 'webp', 'avif', 'heic', 'heif'],
          withData: true);
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
                  leading: const Icon(Icons.photo_camera),
                  title: const Text('Camera Document Scan'),
                  onTap: () async {
                    Navigator.pop(context);
                    final List<String>? imagesPath = await CunningDocumentScanner.getPictures(isGalleryImportAllowed: true);
                    if (imagesPath != null && context.mounted) {
                      final File file = File(imagesPath[0]);
                      _newDocumentOpened(file.readAsBytesSync(), imagesPath[0].split("/").last, context, entryId);
                    }
                  }),
              ListTile(
                  leading: const Icon(Icons.photo_camera),
                  title: const Text('Camera fallback'),
                  onTap: () async {
                    Navigator.pop(context);
                    final XFile? pickedFile = await picker.pickImage(source: ImageSource.camera);
                    if (pickedFile != null && context.mounted) {
                      _newDocumentOpened(await pickedFile.readAsBytes(), pickedFile.name, context, entryId);
                    }
                  }),
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
                  leading: const Icon(Icons.attach_file),
                  title: const Text('File'),
                  onTap: () async {
                    Navigator.pop(context);
                    try {
                      final FilePickerResult? pickedFile = await FilePicker.platform.pickFiles(
                          type: FileType.custom,
                          // heic, heif only work on ios and maybe other apple devices
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
                            'avif',
                            'heic',
                            'heif'
                          ],
                          withData: true);
                      if (pickedFile != null &&
                          (pickedFile.files.single.bytes != null || pickedFile.files.single.path != null) &&
                          context.mounted) {
                        // TODO: File(...) part might be redundant now as i added withData:true
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

    return FutureBuilder(
        future:
            document is LocalDocument ? document.compressionFuture : (document as RemoteDocument).thumbnailBinaryData,
        builder: (context, data) {
          if (document is RemoteDocument) {
            if (data.hasError) {
              _log.warning('Error loading thumbnail: ${data.error}');
              return Container(
                width: 100,
                margin: const EdgeInsets.only(right: 8),
                child: const Center(child: Icon(Icons.error)),
              );
            }
            if (!data.hasData || data.data is! Uint8List) {
              return Container(
                width: 100,
                margin: const EdgeInsets.only(right: 8),
                child: const Center(child: CircularProgressIndicator()),
              );
            }
          }

          if (document is RemoteDocument && !data.hasData ||
                  document is RemoteDocument &&
                      data.data
                          is! Uint8List // no idea why this happens. When adding an image to an entry that already has images and then discarding the changes, this code is called with Future state "done" and data.data is a List without data.
              ) {
            return Container(
              width: 100,
              margin: const EdgeInsets.only(right: 8),
              child: const Center(child: CircularProgressIndicator()),
            );
          }

          Uint8List thumbnailBytes = document is LocalDocument ? document.thumbnailBinaryData : data.data as Uint8List;
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
                height: 100,
                margin: const EdgeInsets.only(right: 8),
                color: Colors.grey[300],
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildImageWithDeletionState(document, thumbnailBytes),
                    if (document is LocalDocument && data.connectionState == ConnectionState.waiting)
                      const Center(child: CircularProgressIndicator()),
                  ],
                )),
          );
        });
  }

  Widget _buildImageWithDeletionState(Document document, Uint8List thumbnailBytes) {
    if (document.deleted) {
      return ClipRect(
        child: ColorFiltered(
          colorFilter: const ColorFilter.mode(
            Colors.grey,
            BlendMode.saturation,
          ),
          child: _buildImage(document, thumbnailBytes),
        ),
      );
    } else {
      return _buildImage(document, thumbnailBytes);
    }
  }

  Widget _buildImage(Document document, Uint8List thumbnailBytes) {
    if (document is LocalDocument && Helpers.getMimeType(document.originalBinaryData) == 'application/pdf') {
      return Image.asset('assets/images/icon-picture_as_pdf.png');
    } else {
      return MemoryImageWithAvif(imageData: thumbnailBytes);
    }
  }

  void _newDocumentOpened(Uint8List fileData, String filename, BuildContext context, int? entryId) {
    onDocumentsChanged([
      LocalDocument(
          originalFilename: filename, fileBytes: fileData, id: _generateLikelyUniqueDocumentId(), entryId: entryId),
      ...documents
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
