import 'package:flutter/foundation.dart';

class Helpers {
  static bool get isDesktopWebBrowser{
    return kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.linux ||
            defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.macOS);
        }
}