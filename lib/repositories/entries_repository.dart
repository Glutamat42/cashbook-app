import 'package:dio/dio.dart';
import '../models/entry.dart'; // Assuming you have an Entry model defined
import '../services/locator.dart';

class EntriesRepository {
  final Dio dio;

  EntriesRepository(this.dio);

  Future<List<Entry>> getEntries() async {
    try {
      final response = await dio.get('/api/entries');
      List<Entry> entries = (response.data as List)
          .map((entryData) => Entry.fromJson(entryData))
          .toList();
      return entries;
    } on DioException catch (e) {
      throw Exception('Failed to load entries: ${e.message}');
    } on FormatException catch (e) {
      throw Exception('Data parsing error: ${e.message}');
    }
  }

  Future<Entry> createEntry(Map<String, dynamic> entryData) async {
    try {
      final response = await dio.post('/api/entries', data: entryData);
      return Entry.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Failed to create entry: ${e.message}');
    }
  }

  Future<Entry> updateEntry(int id, Map<String, dynamic> entryData) async {
    try {
      final response = await dio.put('/api/entries/$id', data: entryData);
      return Entry.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Failed to update entry: ${e.message}');
    }
  }

  Future<void> deleteEntry(int id) async {
    try {
      await dio.delete('/api/entries/$id');
    } on DioException catch (e) {
      throw Exception('Failed to delete entry: ${e.message}');
    }
  }
}
