import 'dart:typed_data';

import 'package:cashbook/utils/helpers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_avif/flutter_avif.dart';

class MemoryImageWithAvif extends StatelessWidget {
  final Uint8List imageData;
  final BoxFit fit;

  const MemoryImageWithAvif({super.key, required this.imageData, this.fit = BoxFit.cover});

  @override
  Widget build(BuildContext context) {
    if (Helpers.getMimeType(imageData) == 'image/avif') {
      return AvifImage.memory(
        imageData,
        fit: fit,
      );
    } else {
      return Image.memory(
        imageData,
        fit: fit,
      );
    }
  }
}