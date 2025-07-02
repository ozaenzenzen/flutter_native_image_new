import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_native_image_new/flutter_native_image_new.dart';
import 'package:flutter_native_image_new/flutter_native_image_new_platform_interface.dart';
import 'package:flutter_native_image_new/flutter_native_image_new_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockFlutterNativeImageNewPlatform with MockPlatformInterfaceMixin implements FlutterNativeImageNewPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');

  @override
  Future<File> compressImage(String fileName, {int percentage = 70, int quality = 70, int targetWidth = 0, int targetHeight = 0}) {
    // TODO: implement compressImage
    throw UnimplementedError();
  }

  @override
  Future<File> cropImage(String fileName, {required int originX, required int originY, required int width, required int height}) {
    // TODO: implement cropImage
    throw UnimplementedError();
  }

  @override
  Future<ImageProperties> getImageProperties(String fileName) {
    // TODO: implement getImageProperties
    throw UnimplementedError();
  }
}

void main() {
  final FlutterNativeImageNewPlatform initialPlatform = FlutterNativeImageNewPlatform.instance;

  test('$MethodChannelFlutterNativeImageNew is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelFlutterNativeImageNew>());
  });

  test('getPlatformVersion', () async {
    FlutterNativeImageNew flutterNativeImageNewPlugin = FlutterNativeImageNew();
    MockFlutterNativeImageNewPlatform fakePlatform = MockFlutterNativeImageNewPlatform();
    FlutterNativeImageNewPlatform.instance = fakePlatform;

    expect(await flutterNativeImageNewPlugin.getPlatformVersion(), '42');
  });
}
