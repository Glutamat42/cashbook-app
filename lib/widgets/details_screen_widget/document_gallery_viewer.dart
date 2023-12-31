import 'package:cashbook/models/local_document.dart';
import 'package:cashbook/stores/auth_store.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import '../../services/locator.dart';
import '../../models/document.dart';
import '../../models/remote_document.dart';
import 'package:http/http.dart' as http;
import 'full_screen_image_viewer.dart';
import 'package:mime/mime.dart' as mime;
import 'dart:typed_data';
import 'package:flutter/services.dart';

import 'package:cashbook/utils/downloads/share_mobile.dart'
    if (dart.library.html) 'package:cashbook/utils/downloads/share_web.dart';

class DocumentGalleryViewer extends StatefulWidget {
  final int initialIndex;
  final List<Document> documents;
  final bool showDeleteButton;
  final Function(int)? onDocumentDeleted;
  final Function(int)? onDocumentUndeleted;

  const DocumentGalleryViewer({
    Key? key,
    required this.initialIndex,
    required this.documents,
    required this.showDeleteButton,
    this.onDocumentDeleted,
    this.onDocumentUndeleted,
  }) : super(key: key);

  @override
  _DocumentGalleryViewerState createState() => _DocumentGalleryViewerState();
}

class _DocumentGalleryViewerState extends State<DocumentGalleryViewer> {
  final Logger _log = Logger('_DocumentGalleryViewerState');
  late PageController _pageController;
  late int _currentIndex;
  final AuthStore authStore = locator<AuthStore>();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.documents[_currentIndex].originalFilename ?? "Document"),
        actions: [
          // widget.documents[_currentIndex] is RemoteDocument
          //     ? IconButton(
          //         icon: Icon(Icons.share),
          //         onPressed: () {
          //           // Implement share functionality for _currentIndex document
          //         },
          //       )
          //     : Container(),
          _buildDeleteButton(),
          PopupMenuButton<String>(
            onSelected: _handleMenuSelection,
            itemBuilder: (BuildContext context) {
              return {'Download Original'}.map((String choice) {
                return PopupMenuItem<String>(
                  value: choice,
                  child: Text(choice),
                );
              }).toList();
            },
          ),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.documents.length,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        itemBuilder: (context, index) {
          return _buildFullScreenImageViewerWithDeletionState(widget.documents[index]);
        },
      ),
    );
  }

  Widget _buildFullScreenImageViewerWithDeletionState(Document document) {
    if (widget.documents[_currentIndex].deleted) {
      return ColorFiltered(
        colorFilter: const ColorFilter.mode(
          Colors.grey,
          BlendMode.saturation,
        ),
        child: FullScreenImageViewer(document: widget.documents[_currentIndex]),
      );
    } else {
      return FullScreenImageViewer(document: widget.documents[_currentIndex]);
    }
  }

  Widget _buildDeleteButton() {
    if (widget.showDeleteButton && widget.onDocumentDeleted != null && widget.onDocumentUndeleted != null) {
      if (widget.documents[_currentIndex].deleted) {
        return IconButton(
          icon: const Icon(Icons.undo),
          onPressed: () {
            widget.onDocumentUndeleted!(widget.documents[_currentIndex].id!);
            setState(() {}); // TODO: not really happy with this, it should update without it
          },
        );
      } else {
        return IconButton(
          icon: const Icon(Icons.delete),
          onPressed: () {
            widget.onDocumentDeleted!(widget.documents[_currentIndex].id!);
            setState(() {}); // TODO: not really happy with this, it should update without it
          },
        );
      }
    } else {
      return Container();
    }
  }

  void _handleMenuSelection(String choice) {
    if (choice == 'Download Original') {
      _downloadAndShareOriginal();
    }
  }

  String? _getMimeType(List<int> binaryFileData) {
    _log.finest('Binary file data length: ${binaryFileData.length}');
    final List<int> header = binaryFileData.sublist(0, mime.defaultMagicNumbersMaxLength);

    // Empty string for the file name because it's not relevant.
    String? mimeType = mime.lookupMimeType('', headerBytes: header);
    _log.fine('Mime type: $mimeType');
    return mimeType;
  }

  Future<void> _downloadAndShareOriginal() async {
    final currentDocument = widget.documents[_currentIndex];

    // Mobile and mobile web browser logic to share the file
    Uint8List fileBytes;
    String fileName;
    String mimeType;

    if (currentDocument is RemoteDocument) {
      // Download the file for mobile platforms
      final response = await http.get(Uri.parse("${authStore.baseUrl!}/${currentDocument.originalLink}"),
          headers: {"Authorization": "Bearer ${authStore.user!.token}"});
      fileBytes = response.bodyBytes;
    } else {
      // Local file
      fileBytes = (currentDocument as LocalDocument).originalBinaryData;
    }
    fileName = currentDocument.originalFilename ?? 'file';
    mimeType = _getMimeType(fileBytes.toList())!;

    Sharing.share(fileBytes, fileName, mimeType);
  }
}
