import 'dart:io';

import 'package:flutter_native_image_new/flutter_native_image_new.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'flutter_native_image_new_method_channel.dart';

abstract class FlutterNativeImageNewPlatform extends PlatformInterface {
  /// Constructs a FlutterNativeImageNewPlatform.
  FlutterNativeImageNewPlatform() : super(token: _token);

  static final Object _token = Object();

  static FlutterNativeImageNewPlatform _instance = MethodChannelFlutterNativeImageNew();

  /// The default instance of [FlutterNativeImageNewPlatform] to use.
  ///
  /// Defaults to [MethodChannelFlutterNativeImageNew].
  static FlutterNativeImageNewPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FlutterNativeImageNewPlatform] when
  /// they register themselves.
  static set instance(FlutterNativeImageNewPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  Future<File> compressImage(
    String fileName, {
    int percentage = 70,
    int quality = 70,
    int targetWidth = 0,
    int targetHeight = 0,
  }) {
    throw UnimplementedError('compressImage() has not been implemented.');
  }

  Future<ImageProperties> getImageProperties(String fileName) {
    throw UnimplementedError('getImageProperties() has not been implemented.');
  }

  Future<File> cropImage(
    String fileName, {
    required int originX,
    required int originY,
    required int width,
    required int height,
  }) {
    throw UnimplementedError('cropImage() has not been implemented.');
  }
}
