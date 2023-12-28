import 'dart:convert';
import 'dart:typed_data';
import 'package:js/js.dart';
import 'package:logging/logging.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:html' as html;

import '../helpers.dart';

class Sharing {
  static Logger _log = Logger('Sharing');

  static void shareWeb(Uint8List fileBytes, String fileName, String mimeType) {
    // This should work but doesnt. It says "TypeError: this.share is not a function"
    // Same code is working fine on mobile target
    // It is following the official example from https://github.com/fluttercommunity/plus_plugins/blob/main/packages/share_plus/share_plus/example/lib/main.dart
    // There are a couple of issues about this, eg:
    // - https://github.com/fluttercommunity/plus_plugins/issues/1643
    // - https://github.com/fluttercommunity/plus_plugins/issues/1320
    _log.info('Sharing file $fileName with share_plus');
    _log.fine('File bytes length: ${fileBytes.length}, mimeType: $mimeType');
    Share.shareXFiles([XFile.fromData(fileBytes, name: fileName, mimeType: mimeType)], text: fileName);
  }

  static void downloadWeb(Uint8List fileBytes, String fileName, String mimeType) {
    final blob = html.Blob([fileBytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute("download", fileName)
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  static void share(Uint8List fileBytes, String fileName, String mimeType) {
    if (Helpers.isDesktopWebBrowser) {
      downloadWeb(fileBytes, fileName, mimeType);
    } else {
      _log.info("Falling back to web download for mobile browsers as sharing with share_plus doesn't work");
      downloadWeb(fileBytes, fileName, mimeType);
      // shareWeb(fileBytes, fileName, mimeType);
    }
  }
}
