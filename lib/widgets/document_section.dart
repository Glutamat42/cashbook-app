import 'package:cashbook/stores/entry_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:image_picker/image_picker.dart';
import '../models/document.dart';
import '../services/locator.dart';
import '../stores/auth_store.dart';
import 'document_gallery_viewer.dart';

class DocumentSection extends StatelessWidget {
  final int? entryId;
  final bool isEditable;

  const DocumentSection({Key? key, required this.entryId, this.isEditable = false})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final EntryStore entryStore = locator<EntryStore>();
    final isNew = entryId == null;

    if (!isNew) {
      entryStore.loadDocumentsForEntry(entryId!);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text('Documents', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Observer(
            builder: (_) {
              List<Document> documents = isNew ? [] : entryStore.getDocumentsForEntry(entryId!);
              int itemCount = isEditable
                  ? documents.length + 1
                  : documents.length; // +1 for add button if editable

              return Container(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: itemCount,
                  itemBuilder: (context, index) {
                    if (isEditable && index == 0) {
                      return _buildAddButton(context);
                    }
                    int docIndex =
                        isEditable ? index - 1 : index; // Adjust index if in editable mode
                    return _buildThumbnailTile(documents, docIndex, context);
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton(BuildContext context) {
    return GestureDetector(
      onTap: () => _addDocument(context),
      child: Container(
        width: 100,
        height: 100,
        margin: const EdgeInsets.only(right: 8),
        color: Colors.grey[300],
        child: const Center(child: Icon(Icons.add)),
      ),
    );
  }

  Future<void> _addDocument(BuildContext context) async {
    final picker = ImagePicker();
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Gallery'),
                  onTap: () async {
                    Navigator.pop(context);
                    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                    if (pickedFile != null) {
                      _uploadDocument(pickedFile.path, context);
                    }
                  }),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Camera'),
                onTap: () async {
                  Navigator.pop(context);
                  final pickedFile = await picker.pickImage(source: ImageSource.camera);
                  if (pickedFile != null) {
                    _uploadDocument(pickedFile.path, context);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }


  Widget _buildThumbnailTile(List<Document> documents, int index, context) {
    Document document = documents[index];
    AuthStore authStore = locator<AuthStore>();
    String token = authStore.user?.token ?? "";
    String thumbnailUrl = '${authStore.baseUrl}/${document.thumbnailLink}';

    if (token.isEmpty) {
      throw Exception("Token is empty");
    }

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => DocumentGalleryViewer(
            initialIndex: index,
            documents: documents,
            token: token,
            baseUrl: authStore.baseUrl!,
          ),
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
      ),
    );
  }

  void _uploadDocument(String filePath, BuildContext context) {
    // Implement the logic to upload the document
    // After uploading, update the EntryStore with the new document
    // e.g., entryStore.addDocumentToEntry(entryId, uploadedDocument);
  }
}
