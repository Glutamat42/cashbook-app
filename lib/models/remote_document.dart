import 'dart:io';
import 'package:cashbook/services/locator.dart';
import 'package:dio/dio.dart';

import 'package:cashbook/models/document.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';

class RemoteDocument extends Document {
  final Logger _log = Logger('RemoteDocument');

  String? createdAt;
  String? updatedAt;

  RemoteDocument({id, entryId, originalFilename, this.createdAt, this.updatedAt}) : super(id: id, entryId: entryId, originalFilename: originalFilename);

  String get _thumbnailLink => '/api/documents/$id/thumbnail';

  String get _documentLink => '/api/documents/$id';

  String get _originalLink => '/api/documents/$id/original';

  Future<Uint8List> get thumbnailBinaryData async => _getBinaryData(_thumbnailLink);
  Future<Uint8List> get documentBinaryData async => _getBinaryData(_documentLink);
  Future<Uint8List> get originalBinaryData async => _getBinaryData(_originalLink, cache: false);

  Future<Uint8List> _getBinaryData(String url, {bool cache = true}) async {
    // Check if the file is cached
    if (!kIsWeb) {
      final cachedFile = await _getCachedFile(url);
      if (cachedFile != null && cachedFile.existsSync()) {
        _log.fine('File is loaded from cache');
        return cachedFile.readAsBytes();
      }
    }

    // Download and optionally cache the file
    final fileBytes = await _downloadFile(url);
    _log.fine('File downloaded');

    if (!kIsWeb && cache && fileBytes != null) {
      try {
        await _saveToCache(url, fileBytes);
        _log.fine('File stored to cached');
      } catch (e) {
        _log.severe('Error saving file to cache: $e');
      }
    }

    if (fileBytes != null) {
      return fileBytes;
    }
    throw Exception('Error loading file');
  }

  Future<File?> _saveToCache(String url, Uint8List fileBytes) async {
    // validate data
    final cacheDir = await getTemporaryDirectory();
    final filePath = '${cacheDir.path}/documents/$id/${Uri.parse(url).pathSegments.last}';
    final file = File(filePath);

    // Create the directory if it doesn't exist
    final directory = file.parent;
    if (!directory.existsSync()) {
      directory.createSync(recursive: true);
    }

    // Write the file
    return file.writeAsBytes(fileBytes);
  }

  Future<Uint8List?> _downloadFile(String url) async {
    Dio dio = locator<Dio>();

    // Download the file
    try {
      var response = await dio.get(url, options: Options(responseType: ResponseType.bytes));
      // var response = await http.get(Uri.parse(url), headers: {"Authorization": "Bearer ${_authStore.user!.token}"});
      return Uint8List.fromList(response.data);
    } catch (e) {
      _log.severe('Error downloading file: $e');
      return null;
    }
  }

  Future<File?> _getCachedFile(String url) async {
    final cacheDir = await getTemporaryDirectory();
    final filePath = '${cacheDir.path}/documents/$id/${Uri.parse(url).pathSegments.last}';
    final file = File(filePath);

    try {
      return file.existsSync() ? file : null;
    } catch (e) {
      return null;
    }
  }


  @override
  factory RemoteDocument.fromJson(Map<String, dynamic> json) {
    return RemoteDocument(
      id: json['id'],
      entryId: json['entry_id'],
      originalFilename: json['original_filename'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['entry_id'] = entryId;
    data['original_filename'] = originalFilename;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    return data;
  }
}
