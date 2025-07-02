import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

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
}
