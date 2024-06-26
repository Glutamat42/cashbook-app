import 'package:cashbook/models/document.dart';
import 'package:cashbook/utils/helpers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_avif/flutter_avif.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:logging/logging.dart';
import 'package:image/image.dart' as img;

class LocalDocument extends Document {
  final Logger _logger = Logger('LocalDocument');
  late Uint8List _fileBytes;

  Uint8List get thumbnailBinaryData => _fileBytes;

  Uint8List get documentBinaryData => _fileBytes;

  Uint8List get originalBinaryData => _fileBytes;

  final List<Future> _compressionFutures = [];

  Future get compressionFuture => Future.wait(_compressionFutures);

  // TODO: as of flutter_avif 2.4.0 there is a new feature: Option to keep exif data while encoding
  void _compress() {
    String? mimeType = Helpers.getMimeType(originalBinaryData.toList());
    if (mimeType == null) {
      _logger.severe('Could not determine mime type of file (null)');
      throw Exception('Could not determine mime type of file');
    } else if (!mimeType.startsWith('image/')) {
      _logger.info('File is not an image, not compressing');
    } else if (mimeType == 'image/avif' || mimeType == 'image/webp' && originalBinaryData.lengthInBytes < 500000) {
      _logger.info('File is already compressed with a modern format and smaller than 500kB, not recompressing');
      // } else if (mimeType == 'image/heif') {
      //   _logger.info('File is in HEIF format, not compressing');
    } else {
      _logger.fine('Compressing image');
      _logger.finest('File size before compression: ${(originalBinaryData.lengthInBytes / 1024).round()} kilobytes');

      _compressionFutures.add(_executeCompression());
    }
  }

  Map<String, Map<String, int?>> _compressionSettings = {
    'webp': {
      'minHeight': null,
      'minWidth': null,
      'quality': 60,
    },
    'avif': {
      'minHeight': null,
      'minWidth': null,
      'minQuantizer': 15,
      'maxQuantizer': 38,
      'speed': 6,
    },
  };

  Future<void> _executeCompression() async {
    Map<String, int?> profile;
    String targetFormat;
    if (kIsWeb) {
      profile = _compressionSettings['webp']!;
      targetFormat = 'webp';
    } else {
      profile = _compressionSettings['avif']!;
      targetFormat = 'avif';
    }

    // resize
    Uint8List resizedBytes = originalBinaryData;
    if (!kIsWeb) {
      _logger.finest('Starting to decode image');
      // TODO: image commands are blocking on web, so the app freezes during these operations
      img.Image image = img.decodeImage(originalBinaryData)!;
      // compress in case: minHeight and minWidth are set and image is larger than either of them or image is larger than 4000x4000 on at least one side
      if (profile['minHeight'] != null &&
              profile['minWidth'] != null &&
              (image.height > profile['minHeight']! || image.width > profile['minWidth']!) ||
          image.width > 4500 ||
          image.height > 4500) {
        _logger.info('Resizing image');
        _logger.finer('Image size before resizing: ${image.width}x${image.height}');
        if (image.height >= image.width) {
          image = img.copyResize(image, height: profile['minHeight'] ?? 4500);
        } else {
          image = img.copyResize(image, width: profile['minWidth'] ?? 4500);
        }
        resizedBytes = img.encodeJpg(image, quality: 100);
      }
    } else {
      _logger.warning('Image resizing is disabled on web due to performance issues');
    }

    // compress
    Uint8List compressedBytes;
    try {
      if (targetFormat == 'webp') {
        compressedBytes = await FlutterImageCompress.compressWithList(
          resizedBytes,
          keepExif: true,
          // rotate: 0,
          // autoCorrectionAngle: true,
          minHeight: 4000,
          // should not rescale here, but compressWithList has default values -> override them
          minWidth: 4000,
          quality: profile['quality']!,
          format: CompressFormat.webp,
        );
      } else {
        compressedBytes = await encodeAvif(originalBinaryData,
            maxQuantizer: profile['maxQuantizer'],
            minQuantizer: profile['minQuantizer'],
            maxQuantizerAlpha: profile['maxQuantizer'],
            minQuantizerAlpha: profile['minQuantizer'],
            maxThreads: 8,
            speed: profile['speed']);
      }
    } catch (e) {
      _logger.severe(
          'Failed to compress image, using original file. This is expected on web with aggressive fingerprinting protection. $e');
      compressedBytes = resizedBytes;
    }

    _logger.finer('File size after compression: ${(compressedBytes.lengthInBytes / 1024).round()} kilobytes');
    _fileBytes = compressedBytes;
    originalFilename = originalFilename!.replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), '.$targetFormat');
  }

  LocalDocument(
      {id,
      entryId,
      required originalFilename,
      required Uint8List fileBytes,
      Map<String, Map<String, int?>>? compressionSettings,
      bool enableCompression = true})
      : super(id: id, entryId: entryId, originalFilename: originalFilename) {
    _fileBytes = fileBytes;
    if (compressionSettings != null) _compressionSettings = compressionSettings;
    if (enableCompression) {
      _compress();
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
