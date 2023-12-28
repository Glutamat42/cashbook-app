import 'dart:typed_data';

import 'package:cashbook/models/document.dart';

class LocalDocument extends Document {
  Uint8List fileBytes;

  Uint8List get thumbnailBinaryData => fileBytes;
  Uint8List get documentBinaryData => fileBytes;
  Uint8List get originalBinaryData => fileBytes;


  LocalDocument({id, entryId, required originalFilename, required this.fileBytes}) : super(id: id, entryId: entryId, originalFilename: originalFilename);

  @override
  factory LocalDocument.fromJson(Map<String, dynamic> json) {
    throw UnimplementedError("LocalDocument.fromJson is not implemented");
  }

  @override
  Map<String, dynamic> toJson() {
    throw UnimplementedError("LocalDocument.toJson is not implemented");
  }
}
