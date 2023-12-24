class Document {
  int? id;
  int entryId;
  String? originalFilename;
  String? createdAt;
  String? updatedAt;

  String get thumbnailLink => 'api/documents/$id/thumbnail';

  String get documentLink => 'api/documents/$id';

  Document({this.id, required this.entryId, this.originalFilename, this.createdAt, this.updatedAt});

  factory Document.fromJson(Map<String, dynamic> json) {
    return Document(
      id: json['id'],
      entryId: json['entry_id'],
      originalFilename: json['original_filename'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

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
