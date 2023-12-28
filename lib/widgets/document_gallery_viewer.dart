import 'package:cashbook/models/local_document.dart';
import 'package:cashbook/stores/auth_store.dart';
import 'package:flutter/material.dart';
import '../services/locator.dart';
import '../models/document.dart';
import '../models/remote_document.dart';
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

  const DocumentGalleryViewer({
    Key? key,
    required this.initialIndex,
    required this.documents,
    required this.showDeleteButton,
  }) : super(key: key);

  @override
  _DocumentGalleryViewerState createState() => _DocumentGalleryViewerState();
}

class _DocumentGalleryViewerState extends State<DocumentGalleryViewer> {
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
          widget.documents[_currentIndex] is RemoteDocument
              ? IconButton(
                  icon: Icon(Icons.share),
                  onPressed: () {
                    // Implement share functionality for _currentIndex document
                  },
                )
              : Container(),
          widget.showDeleteButton
              ? IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () {
                    // Implement delete functionality for _currentIndex document
                  },
                )
              : Container(),
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
          return FullScreenImageViewer(document: widget.documents[index]);
        },
      ),
    );
  }

  void _handleMenuSelection(String choice) {
    if (choice == 'Download Original') {
      _downloadAndShareOriginal();
    }
  }

  String? _getMimeType(List<int> binaryFileData) {
    final List<int> header = binaryFileData.sublist(0, mime.defaultMagicNumbersMaxLength);

    // Empty string for the file name because it's not relevant.
    return mime.lookupMimeType('', headerBytes: header);
  }

  Future<void> _downloadAndShareOriginal() async {
    final currentDocument = widget.documents[_currentIndex];

    // Mobile and mobile web browser logic to share the file
    Uint8List fileBytes;
    String fileName;
    String mimeType;

    if (currentDocument is RemoteDocument) {
      // Download the file for mobile platforms
      final response = await http
          .get(Uri.parse(currentDocument.documentLink), headers: {"Authorization": "Bearer ${authStore.user!.token}"});
      fileBytes = response.bodyBytes;
    } else {
      // Local file
      fileBytes = (currentDocument as LocalDocument).originalBinaryData;
    }
    fileName = currentDocument.originalFilename ?? 'file';
    mimeType = _getMimeType(fileBytes.toList())!;

    // Share the file based on platform
    // if (Helpers.isDesktopWebBrowser && currentDocument is RemoteDocument) {
    //   // Desktop Web Browser logic to download the file
    //   Sharing.share(fileBytes, fileName);
    // }

    Sharing.share(fileBytes, fileName, mimeType);
    // else {
    //   if (kIsWeb) {
    //     // For web, use HTML anchor element for downloading
    //     final blob = html.Blob([fileBytes]);
    //     final url = html.Url.createObjectUrlFromBlob(blob);
    //     html.AnchorElement(href: url)
    //       ..setAttribute("download", fileName)
    //       ..click();
    //     html.Url.revokeObjectUrl(url);
    //   } else {
    //     // For non-web, use Share package
    //     await Share.shareXFiles([XFile.fromData(fileBytes, name: fileName)]);
    //   }
    // }
  }
}
