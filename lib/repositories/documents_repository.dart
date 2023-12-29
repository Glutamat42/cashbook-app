import 'package:dio/dio.dart';
import '../models/remote_document.dart'; // You need to create a Document model class

class DocumentsRepository {
  final Dio dio;

  DocumentsRepository(this.dio);

  Future<List<RemoteDocument>> getDocumentsByEntryId(int entryId) async {
    try {
      final response = await dio.get('/api/entries/$entryId/documents');
      return (response.data as List).map((d) => RemoteDocument.fromJson(d)).toList();
    } catch (e) {
      throw Exception('Failed to load documents: ${e.toString()}');
    }
  }

  Future<List<RemoteDocument>> getAll() async {
    try {
      final response = await dio.get('/api/documents');
      return (response.data as List).map((d) => RemoteDocument.fromJson(d)).toList();
    } catch (e) {
      throw Exception('Failed to load documents: ${e.toString()}');
    }
  }
}
