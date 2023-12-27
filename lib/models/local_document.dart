import 'package:cashbook/models/document.dart';

class LocalDocument extends Document {
  String filePath;

  @override
  String get originalFilename => filePath.split('/').last;

  @override
  String get thumbnailLink => filePath;

  @override
  String get documentLink => filePath;

  @override
  String get originalLink => filePath;

  LocalDocument({id, entryId, required this.filePath}) : super(id: id, entryId: entryId);

  @override
  factory LocalDocument.fromJson(Map<String, dynamic> json) {
    return LocalDocument(
      id: json['id'],
      entryId: json['entry_id'],
      filePath: json['file_path'],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['entry_id'] = entryId;
    data['file_path'] = filePath;
    return data;
  }
}
