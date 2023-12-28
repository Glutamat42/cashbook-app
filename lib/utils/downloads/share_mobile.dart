import 'dart:typed_data';
import 'package:share_plus/share_plus.dart';

class Sharing {
  static void shareMobile(Uint8List fileBytes, String fileName, String mimeType) {
    Share.shareXFiles([XFile.fromData(fileBytes, name: fileName, mimeType: mimeType)], text: fileName);
  }

  static Future<void> share(Uint8List fileBytes, String fileName, String mimeType) async {
    shareMobile(fileBytes, fileName, mimeType);
  }
}
