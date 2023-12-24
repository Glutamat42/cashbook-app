import 'package:dio/dio.dart';
import '../models/document.dart'; // You need to create a Document model class

class DocumentsRepository {
  final Dio dio;

  DocumentsRepository(this.dio);

  Future<List<Document>> getDocumentsByEntryId(int entryId) async {
    try {
      final response = await dio.get('/api/entries/$entryId/documents');
      return (response.data as List).map((d) => Document.fromJson(d)).toList();
    } catch (e) {
      throw Exception('Failed to load documents: ${e.toString()}');
    }
  }

// ... other methods for handling document-related API calls
}
