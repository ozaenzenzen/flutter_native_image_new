import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_image_new/flutter_native_image_new.dart';

import 'flutter_native_image_new_platform_interface.dart';

/// An implementation of [FlutterNativeImageNewPlatform] that uses method channels.
class MethodChannelFlutterNativeImageNew extends FlutterNativeImageNewPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('flutter_native_image_new');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }

  @override
  Future<File> compressImage(
    String fileName, {
    int percentage = 70,
    int quality = 70,
    int targetWidth = 0,
    int targetHeight = 0,
  }) async {
    var file = await methodChannel.invokeMethod(
      "compressImage",
      {
        'file': fileName,
        'quality': quality,
        'percentage': percentage,
        'targetWidth': targetWidth,
        'targetHeight': targetHeight,
      },
    );

    return File(file);
  }

  @override
  Future<ImageProperties> getImageProperties(String fileName) async {
    ImageOrientation decodeOrientation(int? orientation) {
      // For details, see: https://developer.android.com/reference/android/media/ExifInterface
      switch (orientation) {
        case 1:
          return ImageOrientation.normal;
        case 2:
          return ImageOrientation.flipHorizontal;
        case 3:
          return ImageOrientation.rotate180;
        case 4:
          return ImageOrientation.flipVertical;
        case 5:
          return ImageOrientation.transpose;
        case 6:
          return ImageOrientation.rotate90;
        case 7:
          return ImageOrientation.transverse;
        case 8:
          return ImageOrientation.rotate270;
        default:
          return ImageOrientation.undefined;
      }
    }

    var properties = Map.from(
      await (methodChannel.invokeMethod(
        "getImageProperties",
        {
          'file': fileName,
        },
      )),
    );
    return ImageProperties(
      width: properties["width"],
      height: properties["height"],
      orientation: decodeOrientation(
        properties["orientation"],
      ),
    );
  }

  @override
  Future<File> cropImage(
    String fileName, {
    required int originX,
    required int originY,
    required int width,
    required int height,
  }) async {
    var file = await methodChannel.invokeMethod(
      "cropImage",
      {
        'file': fileName,
        'originX': originX,
        'originY': originY,
        'width': width,
        'height': height,
      },
    );

    return File(file);
  }
}
