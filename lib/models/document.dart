abstract class Document {
  int? id;
  int? entryId;  // does not exist for new entries
  String? originalFilename;
  bool deleted = false;

  Document({this.id, required this.entryId, this.originalFilename});

  Map<String, dynamic> toJson();
}
