class Export {
  final String filename;
  final int filesize;
  final DateTime createdTimestamp;
  final bool containsDocuments;
  final bool imagesConvertedToJpeg;
  final String downloadParameter;

  Export({
    required this.filename,
    required this.filesize,
    required this.createdTimestamp,
    required this.containsDocuments,
    required this.imagesConvertedToJpeg,
    required this.downloadParameter,
  });

  factory Export.fromJson(Map<String, dynamic> json) {
    return Export(
      filename: json['filename'],
      filesize: json['filesize'],
      createdTimestamp: DateTime.parse(json['created_timestamp']),
      containsDocuments: json['contains_documents'],
      imagesConvertedToJpeg: json['images_converted_to_jpeg'],
      downloadParameter: json['download_parameter'],
    );
  }
}