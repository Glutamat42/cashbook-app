import 'package:flutter/foundation.dart';
import 'package:mime/mime.dart' as mime;
import 'package:mime/mime.dart';

class Helpers {
  static bool get isDesktopWebBrowser {
    return kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.linux ||
            defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.macOS);
  }

  static String? getMimeType(List<int> binaryFileData) {
    final List<int> header = binaryFileData.sublist(0, mime.defaultMagicNumbersMaxLength);

    final resolver = MimeTypeResolver();
    resolver.addMagicNumber(
      [0x00, 0x00, 0x00, 0x00, 0x66, 0x74, 0x79, 0x70, 0x61, 0x76, 0x69, 0x66],
      'image/avif',
      mask: [0x00, 0x00, 0x00, 0x00, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF],
    );
    // Empty string for the file name because it's not relevant.
    return resolver.lookup('', headerBytes: header);
  }
}
