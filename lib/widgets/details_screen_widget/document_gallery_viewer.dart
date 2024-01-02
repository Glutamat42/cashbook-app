import 'dart:async';

import 'package:cashbook/models/local_document.dart';
import 'package:cashbook/stores/auth_store.dart';
import 'package:cashbook/utils/helpers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:logging/logging.dart';
import '../../services/locator.dart';
import '../../models/document.dart';
import '../../models/remote_document.dart';
import 'full_screen_image_viewer.dart';

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
  bool shareSupported = false;

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
          shareSupported
              ? IconButton(
                  icon: const Icon(kIsWeb ? Icons.download : Icons.share),
                  onPressed: () {
                    // _downloadAndShare(QualityType.original);
                    _downloadAndShare(QualityType.document);
                  },
                )
              : IconButton(
                  icon: const Icon(kIsWeb ? Icons.download : Icons.share),
                  onPressed: () {
                    _downloadAndShare(QualityType.original);
                  },
                ),
          _buildDeleteButton(),
          if (shareSupported)
            PopupMenuButton<String>(
              onSelected: _handleMenuSelection,
              itemBuilder: (BuildContext context) {
                return {'Download/share Original'}.map((String choice) {
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

  void _checkShareSupported(Document document) async {
    Uint8List imageData;
    if (document is LocalDocument) {
      imageData = document.documentBinaryData;
    } else {
      imageData = await (document as RemoteDocument).documentBinaryData;
    }
    final bool isSupported = Helpers.getMimeType(imageData) != 'image/avif';
    if (shareSupported != isSupported) {
      setState(() {
        shareSupported = isSupported;
      });
    }
  }

  Widget _buildFullScreenImageViewerWithDeletionState(Document document) {
    _checkShareSupported(widget.documents[_currentIndex]);

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
      _downloadAndShare(QualityType.original);
    }
  }

  Future<void> _downloadAndShare(QualityType qualityType, {bool convertToJpeg = true}) async {
    Document document = widget.documents[_currentIndex];
    // Mobile and mobile web browser logic to share the file
    Uint8List fileBytes;
    String fileName;
    String mimeType;

    if (document is RemoteDocument) {
      // Download the file for mobile platforms
      switch (qualityType) {
        case QualityType.original:
          fileBytes = await (document).originalBinaryData;
        case QualityType.document:
          fileBytes = await (document).documentBinaryData;
        case QualityType.thumbnail:
          fileBytes = await (document).thumbnailBinaryData;
      }
    } else {
      // Local file
      switch (qualityType) {
        case QualityType.original:
          fileBytes = (document as LocalDocument).originalBinaryData;
        case QualityType.document:
          fileBytes = (document as LocalDocument).documentBinaryData;
        case QualityType.thumbnail:
          fileBytes = (document as LocalDocument).thumbnailBinaryData;
      }
    }
    fileName = document.originalFilename ?? 'file';
    mimeType = Helpers.getMimeType(fileBytes.toList())!;

    // convert
    if (convertToJpeg) {
      if (mimeType == 'image/avif') {
        _log.warning('Cannot convert AVIF to JPEG');
      } else if (mimeType == 'image/webp') {
        final image = img.decodeImage(fileBytes);
        fileBytes = img.encodeJpg(image!, quality: 90);
        mimeType = 'image/jpeg';
      }
    }

    Sharing.share(fileBytes, fileName, mimeType);
  }
}

enum QualityType {
  original,
  document,
  thumbnail,
}
