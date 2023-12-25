import 'package:flutter/material.dart';
import '../models/document.dart';
import 'full_screen_image_viewer.dart';

class DocumentGalleryViewer extends StatefulWidget {
  final int initialIndex;
  final List<Document> documents;
  final String token;
  final String baseUrl;

  const DocumentGalleryViewer({
    Key? key,
    required this.initialIndex,
    required this.documents,
    required this.token,
    required this.baseUrl,
  }) : super(key: key);

  @override
  _DocumentGalleryViewerState createState() => _DocumentGalleryViewerState();
}

class _DocumentGalleryViewerState extends State<DocumentGalleryViewer> {
  late PageController _pageController;
  late int _currentIndex;

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
        title: Text('Document Gallery'),
        actions: [
          IconButton(
            icon: Icon(Icons.share),
            onPressed: () {
              // Implement share functionality for _currentIndex document
            },
          ),
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: () {
              // Implement delete functionality for _currentIndex document
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
          String imageUrl = '${widget.baseUrl}/${widget.documents[index].documentLink}';
          return FullScreenImageViewer(imageUrl: imageUrl, token: widget.token, filename: widget.documents[index].originalFilename ?? "");
        },
      ),
    );
  }
}