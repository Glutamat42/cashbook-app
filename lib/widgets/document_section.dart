import 'package:cashbook/config/app_config.dart';
import 'package:cashbook/stores/entry_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import '../models/document.dart';
import '../services/locator.dart';
import '../stores/auth_store.dart';
import 'full_screen_image_viewer.dart';

class DocumentSection extends StatelessWidget {
  final int entryId;
  final bool isEditable;

  const DocumentSection({Key? key, required this.entryId, this.isEditable = false}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final EntryStore entryStore = locator<EntryStore>();
    entryStore.loadDocumentsForEntry(entryId);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text('Documents', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Observer(
            builder: (_) {
              int indexOffset = isEditable ? 1 : 0;
              return Container(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: entryStore.getDocumentsForEntry(entryId).length + indexOffset, // +1 for the add button
                  itemBuilder: (context, index) {
                    if (isEditable && index == 0) {
                      return _buildAddButton();
                    } else if (!isEditable) {
                      var document = entryStore.getDocumentsForEntry(entryId)[index - indexOffset];
                      return _buildThumbnailTile(document, context);
                    }
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton() {
    // TODO: Implement add button logic
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 8),
      color: Colors.grey[300],
      child: const Center(child: Icon(Icons.add)),
    );
  }

  Widget _buildThumbnailTile(Document document, context) {
    AuthStore authStore = locator<AuthStore>();
    String token = authStore.user?.token ?? "";
    String thumbnailUrl = '${AppConfig().apiBaseUrl}/${document.thumbnailLink}';
    String fullImageUrl = '${AppConfig().apiBaseUrl}/${document.documentLink}';

    if (token.isEmpty) {
      throw Exception("Token is empty");
    }

    return GestureDetector(
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => FullScreenImageViewer(imageUrl: fullImageUrl, token: token, filename: document.originalFilename != null ? document.originalFilename! : "Document"),
          ));
        },
        child: Container(
          width: 100,
          margin: const EdgeInsets.only(right: 8),
          color: Colors.grey[300],
          child: Image.network(
            thumbnailUrl,
            headers: {"Authorization": "Bearer $token"},
            fit: BoxFit.cover,
          ),
        ));
  }
}
