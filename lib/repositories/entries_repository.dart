import 'package:cashbook/models/remote_document.dart';
import 'package:dio/dio.dart';
import '../models/document.dart';
import '../models/entry.dart'; // Assuming you have an Entry model defined
import '../models/local_document.dart';
import '../services/locator.dart';

class EntriesRepository {
  final Dio dio;

  EntriesRepository(this.dio);

  Future<List<Entry>> getEntries() async {
    Response response;
    try {
      response = await dio.get('/api/entries');
    } on DioException catch (e) {
      throw Exception('Failed to load entries: ${e.message}');
    }

    try {
      List<Entry> entries = (response.data as List).map((entryData) => Entry.fromJson(entryData)).toList();
      return entries;
    } on FormatException catch (e) {
      throw Exception('Data parsing error: ${e.message}');
    }
  }

  Future<Entry> createEntry(Entry entryData, List<Document> documents) async {
    FormData formData = _prepareFormData(entryData, documents);

    try {
      final response = await dio.post('/api/entries', data: formData);
      return Entry.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Failed to create entry: ${e.message}');
    } on Exception catch (e) {
      throw Exception('Failed to create entry: ${e.toString()}');
    }
  }

  Future<Entry> updateEntry(int id, Entry entryData, List<Document> documents) async {
    FormData formData = _prepareFormData(entryData, documents);
    // Add deleted document IDs to the FormData
    formData.fields
        .addAll(_getDeletedDocumentIds(documents).map((docId) => MapEntry('deleted_documents[]', docId.toString())));

    try {
      final response = await dio.post('/api/entries/$id', data: formData);
      return Entry.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Failed to update entry: ${e.message}');
    } on Exception catch (e) {
      throw Exception('Failed to update entry: ${e.toString()}');
    }
  }

  Future<void> deleteEntry(int id) async {
    try {
      await dio.delete('/api/entries/$id');
    } on DioException catch (e) {
      throw Exception('Failed to delete entry: ${e.message}');
    } on Exception catch (e) {
      throw Exception('Failed to delete entry: ${e.toString()}');
    }
  }

  FormData _prepareFormData(Entry entryData, List<Document> documents) {
    // Create a multipart request
    FormData formData = FormData();

    // Add entry fields
    formData.fields.addAll([
      MapEntry('description', entryData.description),
      MapEntry('recipient_sender', entryData.recipientSender),
      MapEntry('amount', entryData.amount.toString()),
      MapEntry('is_income', entryData.isIncome == true ? '1' : '0'),
      MapEntry('date', entryData.date.toIso8601String()),
      MapEntry('category_id', entryData.categoryId.toString()),
      MapEntry('payment_method', entryData.paymentMethod),
      MapEntry('no_invoice', entryData.noInvoice == true ? '1' : '0'),
    ]);

    if (entryData.id != null) {
      formData.fields.add(MapEntry('id', entryData.id.toString()));
    }

    // remove entries with value null
    formData.fields.removeWhere((element) => element.value == "null");

    // Add documents as part of the multipart request
    for (Document doc in documents) {
      if (doc is LocalDocument && !doc.deleted) {
        String filename = doc.originalFilename!;
        MultipartFile multipartFile = MultipartFile.fromBytes(doc.fileBytes, filename: filename);
        formData.files.add(MapEntry('document[]', multipartFile));
      }
    }

    return formData;
  }

  List<int> _getDeletedDocumentIds(List<Document> documents) {
    List<int> deletedDocumentIds = [];
    for (Document doc in documents) {
      if (doc is RemoteDocument && doc.deleted) {
        deletedDocumentIds.add(doc.id!);
      }
    }
    return deletedDocumentIds;
  }
}
