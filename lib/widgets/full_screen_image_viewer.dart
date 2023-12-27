import 'dart:io';

import 'package:cashbook/stores/auth_store.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

import '../models/document.dart';
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
        "${authStore.baseUrl!}/${document.thumbnailLink}",
        headers: {"Authorization": "Bearer ${authStore.user!.token}"},
      );
    } else {
      return FileImage(File(document.documentLink));
    }
  }
}
