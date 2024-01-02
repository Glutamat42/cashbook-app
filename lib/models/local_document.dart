import 'dart:typed_data';

import 'package:cashbook/models/document.dart';
import 'package:cashbook/utils/helpers.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:logging/logging.dart';

class LocalDocument extends Document {
  final Logger _logger = Logger('LocalDocument');
  late Uint8List _fileBytes;

  Uint8List get thumbnailBinaryData => _fileBytes;

  Uint8List get documentBinaryData => _fileBytes;

  Uint8List get originalBinaryData => _fileBytes;

  Map<String, int> _compressionSettings = {
    'minHeight': 2560,
    'minWidth': 2560,
    'quality': 80,
  };

  final List<Future> _compressionFutures = [];

  Future get compressionFuture => Future.wait(_compressionFutures);

  void compress() {
    String? mimeType = Helpers.getMimeType(originalBinaryData.toList());
    if (!mimeType!.startsWith('image/')) {
      _logger.info('File is not an image, not compressing');
    } else if (mimeType == 'image/avif' || mimeType == 'image/webp') {
      _logger.info('File is already compressed with a modern format, not recompressing');
  } else{
      _logger.fine('Compressing image');
      _logger.finest('File size before compression: ${(originalBinaryData.lengthInBytes / 1024).round()} kilobytes');
      Future compressionFuture = FlutterImageCompress.compressWithList(
        originalBinaryData,
        keepExif: true,
        // rotate: 0,
        // autoCorrectionAngle: true,
        minHeight: _compressionSettings['minHeight']!,
        minWidth: _compressionSettings['minWidth']!,
        quality: _compressionSettings['quality']!,
        format: CompressFormat.webp,
      );
      compressionFuture.then((value) {
        _logger.finer('File size after compression: ${(value.lengthInBytes / 1024).round()} kilobytes');
        return _fileBytes = value;
      });
      _compressionFutures.add(compressionFuture);
    }
  }

  LocalDocument(
      {id,
      entryId,
      required originalFilename,
      required Uint8List fileBytes,
      Map<String, int>? compressionSettings,
      bool enableCompression = true})
      : super(id: id, entryId: entryId, originalFilename: originalFilename) {
    _fileBytes = fileBytes;
    if (compressionSettings != null) _compressionSettings = compressionSettings;
    if (enableCompression) {
      compress();
    }
  }

  @override
  factory LocalDocument.fromJson(Map<String, dynamic> json) {
    throw UnimplementedError("LocalDocument.fromJson is not implemented");
  }

  @override
  Map<String, dynamic> toJson() {
    throw UnimplementedError("LocalDocument.toJson is not implemented");
  }
}
