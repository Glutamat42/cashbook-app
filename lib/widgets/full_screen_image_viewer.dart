import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

class FullScreenImageViewer extends StatelessWidget {
  final String imageUrl;
  final String token;
  final String filename;

  const FullScreenImageViewer({Key? key, required this.imageUrl, required this.token, required this.filename})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(filename),
        actions: [
          IconButton(
            icon: Icon(Icons.share),
            onPressed: () {
              // TODO: Implement share functionality
            },
          ),
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: () {
              // TODO: Implement delete functionality
            },
          ),
        ],
      ),
      body: PhotoView(
        imageProvider: NetworkImage(
          imageUrl,
          headers: {"Authorization": "Bearer $token"},
        ),
        minScale: PhotoViewComputedScale.contained * 0.8,
        maxScale: PhotoViewComputedScale.covered * 2,
        initialScale: PhotoViewComputedScale.contained,
        backgroundDecoration: BoxDecoration(
          color: Theme.of(context).canvasColor,
        ),
      ),
    );
  }
}
