import 'package:cashbook/utils/helpers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_avif/flutter_avif.dart';
import 'package:photo_view/photo_view.dart';

import '../../models/document.dart';
import '../../models/local_document.dart';
import '../../models/remote_document.dart';

class FullScreenImageViewer extends StatelessWidget {
  final Document document;

  const FullScreenImageViewer({Key? key, required this.document}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (document is LocalDocument) {

      return _buildPhotoView(_buildLocalDocumentImageProvider(), context);
    } else {
      return FutureBuilder(
          future: (document as RemoteDocument).documentBinaryData,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return _buildPhotoView(_buildMemoryImageProviderWithAvif(snapshot.data!), context);
            } else if (snapshot.hasError) {
              return const Center(child: Text('Error loading image'));
            } else {
              return const Center(child: CircularProgressIndicator());
            }
          });
    }
  }

  Widget _buildPhotoView(ImageProvider imageProvider, context) {
    return PhotoView(
      imageProvider: imageProvider,
      minScale: PhotoViewComputedScale.contained * 1.0,
      maxScale: PhotoViewComputedScale.covered * 2.5,
      initialScale: PhotoViewComputedScale.contained,
      backgroundDecoration: BoxDecoration(
        color: Theme.of(context).canvasColor,
      ),
    );
  }

  ImageProvider _buildLocalDocumentImageProvider() {
    if (Helpers.getMimeType((document as LocalDocument).originalBinaryData) == 'application/pdf') {
      if (kIsWeb) {
        return const NetworkImage('assets/images/icon-picture_as_pdf.png');
      } else {
        return const AssetImage('assets/images/icon-picture_as_pdf.png');
      }
    } else {
      return _buildMemoryImageProviderWithAvif((document as LocalDocument).documentBinaryData);
    }
  }

  ImageProvider _buildMemoryImageProviderWithAvif(Uint8List imageData) {
    if (Helpers.getMimeType(imageData) == 'image/avif') {
      return MemoryAvifImage(imageData);
    } else {
      return MemoryImage(imageData);
    }
  }
}
