import 'package:cashbook/stores/auth_store.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:mime/mime.dart' as mime;

import '../models/document.dart';
import '../models/local_document.dart';
import '../models/remote_document.dart';
import '../services/locator.dart';

class FullScreenImageViewer extends StatelessWidget {
  final Document document;

  const FullScreenImageViewer({Key? key, required this.document})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final AuthStore authStore = locator<AuthStore>();

    return PhotoView(
      imageProvider: _buildImageProvider(authStore),
      minScale: PhotoViewComputedScale.contained * 0.8,
      maxScale: PhotoViewComputedScale.covered * 2,
      initialScale: PhotoViewComputedScale.contained,
      backgroundDecoration: BoxDecoration(
        color: Theme.of(context).canvasColor,
      ),
    );
  }

  ImageProvider _buildImageProvider(AuthStore authStore) {
    if (document is RemoteDocument) {
      return NetworkImage(
        "${authStore.baseUrl!}/${(document as RemoteDocument).documentLink}",
        headers: {"Authorization": "Bearer ${authStore.user!.token}"},
      );
    } else {
      if (_getMimeType((document as LocalDocument).thumbnailBinaryData) == 'application/pdf') {
        if (kIsWeb) {
          return const NetworkImage('assets/images/icon-picture_as_pdf.png');
        } else {
          return const AssetImage('assets/images/icon-picture_as_pdf.png');
        }
      } else {
        return MemoryImage((document as LocalDocument).documentBinaryData);
      }
    }
  }

  String? _getMimeType(List<int> binaryFileData)  {
    final List<int> header = binaryFileData.sublist(0, mime.defaultMagicNumbersMaxLength);

    // Empty string for the file name because it's not relevant.
    return mime.lookupMimeType('', headerBytes: header);
  }
}
