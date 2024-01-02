import 'package:flutter/foundation.dart';
import 'package:mime/mime.dart' as mime;


class Helpers {
  static bool get isDesktopWebBrowser{
    return kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.linux ||
            defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.macOS);
        }

  static String? getMimeType(List<int> binaryFileData) {
    final List<int> header = binaryFileData.sublist(0, mime.defaultMagicNumbersMaxLength);

    // Empty string for the file name because it's not relevant.
    return mime.lookupMimeType('', headerBytes: header);
  }

}