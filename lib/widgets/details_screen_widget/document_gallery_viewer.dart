import 'dart:async';

import 'package:cashbook/models/local_document.dart';
import 'package:cashbook/stores/auth_store.dart';
import 'package:cashbook/utils/helpers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_avif/flutter_avif.dart';
import 'package:logging/logging.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import '../../services/locator.dart';
import '../../models/document.dart';
import '../../models/remote_document.dart';
import 'package:image/image.dart' as img;

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
  late List<ImageProvider> imageProviders = [];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);

    for (int i = 0; i < widget.documents.length; i++) {
      Document document = widget.documents[i];
      if (document is LocalDocument) {
        if (Helpers.getMimeType(document.originalBinaryData) == 'application/pdf') {
          imageProviders.add(const AssetImage('assets/images/icon-picture_as_pdf.png'));
        } else {
          imageProviders.add(_buildMemoryImageProviderWithAvif(document.documentBinaryData));
        }
      } else {
        imageProviders.add(const AssetImage('assets/images/icon-hourglass-top.png'));
        (document as RemoteDocument).documentBinaryData.then((value) {
          if (mounted) {
            setState(() {
              imageProviders[i] = _buildMemoryImageProviderWithAvif(value);
            });
          }
        });
      }
    }
  }

  ImageProvider _buildMemoryImageProviderWithAvif(Uint8List imageData) {
    if (Helpers.getMimeType(imageData) == 'image/avif') {
      return MemoryAvifImage(imageData);
    } else {
      return MemoryImage(imageData);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text((widget.documents[_currentIndex].deleted ? "DELETE: " : "") +
            (widget.documents[_currentIndex].originalFilename ?? "Document")),
        actions: [
          _buildDeleteButton(),
          IconButton(
            icon: const Icon(kIsWeb ? Icons.download : Icons.share),
            onPressed: () {
              _downloadAndShare(QualityType.document, context: context);
            },
          ),
          PopupMenuButton<String>(
            onSelected: _handleMenuSelection,
            itemBuilder: (BuildContext context) {
              return {'Download/share Original'}.map((String choice) {
                return PopupMenuItem<String>(
                  value: choice,
                  child: const Text("Download/share Original"),
                );
              }).toList();
            },
          ),
        ],
      ),
      body: ColorFiltered(
        colorFilter: widget.documents[_currentIndex].deleted
            ? const ColorFilter.mode(Colors.grey, BlendMode.saturation)
            : const ColorFilter.mode(Colors.transparent, BlendMode.saturation),
        child: PhotoViewGallery.builder(
          itemCount: widget.documents.length,
          pageController: _pageController,
          onPageChanged: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          builder: (context, index) {
            return PhotoViewGalleryPageOptions(
              imageProvider: imageProviders[index],
              minScale: PhotoViewComputedScale.contained * 1.0,
              maxScale: PhotoViewComputedScale.covered * 4,
              initialScale: PhotoViewComputedScale.contained,
              heroAttributes: PhotoViewHeroAttributes(tag: index.toString()),
            );
          },
          scrollPhysics: const BouncingScrollPhysics(),
          backgroundDecoration: BoxDecoration(
            color: Theme.of(context).canvasColor,
          ),
        ),
      ),
    );
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
    if (choice == 'Download/share Original') {
      _downloadAndShare(QualityType.original, context: context);
    }
  }

  Future<void> _downloadAndShare(QualityType qualityType, {bool convertToJpeg = true, BuildContext? context}) async {
    if (context != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preparing share...')));
    }

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
        final frames = await decodeAvif(fileBytes);

        // final byteData = await frames[0].image.toByteData(format: ImageByteFormat.png);
        // final pngBytes = byteData!.buffer.asUint8List();
        // // fileBytes = await FlutterImageCompress.compressWithList(pngBytes, format: CompressFormat.jpeg, quality: 90);
        // // alternative with Image package
        // final img.Image? imageLibImage = img.decodeImage(pngBytes);
        final imageLibImage = img.Image.fromBytes(
            width: frames[0].image.width,
            height: frames[0].image.height,
            bytes: (await frames[0].image.toByteData())!.buffer,
            numChannels: 4);
        fileBytes = img.encodeJpg(imageLibImage, quality: 90);
        mimeType = 'image/jpeg';
      } else if (mimeType == 'image/webp') {
        img.Image image = img.decodeImage(fileBytes)!;
        fileBytes = img.encodeJpg(image, quality: 90);
        // fileBytes = await FlutterImageCompress.compressWithList(fileBytes, format: CompressFormat.jpeg, quality: 90);
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
