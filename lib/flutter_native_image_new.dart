import 'dart:io';

import 'flutter_native_image_new_platform_interface.dart';

class FlutterNativeImageNew {
  Future<String?> getPlatformVersion() {
    return FlutterNativeImageNewPlatform.instance.getPlatformVersion();
  }

  static Future<File> compressImage(
    String fileName, {
    int percentage = 70,
    int quality = 70,
    int targetWidth = 0,
    int targetHeight = 0,
  }) {
    return FlutterNativeImageNewPlatform.instance.compressImage(
      fileName,
      percentage: percentage,
      quality: quality,
      targetWidth: targetWidth,
      targetHeight: targetHeight,
    );
  }

  static Future<ImageProperties> getImageProperties(String fileName) {
    return FlutterNativeImageNewPlatform.instance.getImageProperties(fileName);
  }

  static Future<File> cropImage(
    String fileName,
    int originX,
    int originY,
    int width,
    int height,
  ) {
    return FlutterNativeImageNewPlatform.instance.cropImage(
      fileName,
      originX: originX,
      originY: originY,
      width: width,
      height: height,
    );
  }
}

/// Return value of [getImageProperties].
class ImageProperties {
  int? width;
  int? height;
  ImageOrientation orientation;

  ImageProperties({
    this.width = 0,
    this.height = 0,
    this.orientation = ImageOrientation.undefined,
  });
}

/// Imageorientation enum used for [getImageProperties].
enum ImageOrientation {
  normal,
  rotate90,
  rotate180,
  rotate270,
  flipHorizontal,
  flipVertical,
  transpose,
  transverse,
  undefined,
}
