import 'package:cashbook/models/document.dart';

class RemoteDocument extends Document {
  String? createdAt;
  String? updatedAt;

  @override
  String get thumbnailLink => 'api/documents/$id/thumbnail';

  @override
  String get documentLink => 'api/documents/$id';

  @override
  String get originalLink => 'api/documents/$id/original';

  RemoteDocument({id, entryId, originalFilename, this.createdAt, this.updatedAt}) : super(id: id, entryId: entryId, originalFilename: originalFilename);

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
