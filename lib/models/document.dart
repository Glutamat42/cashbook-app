abstract class Document {
  int? id;
  int entryId;
  String? originalFilename;
  bool deleted = false;

  String get thumbnailLink;

  String get documentLink;

  String get originalLink;

  Document({this.id, required this.entryId, this.originalFilename});

  Map<String, dynamic> toJson();
}
