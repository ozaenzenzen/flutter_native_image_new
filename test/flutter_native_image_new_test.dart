import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_native_image_new/flutter_native_image_new.dart';
import 'package:flutter_native_image_new/flutter_native_image_new_platform_interface.dart';
import 'package:flutter_native_image_new/flutter_native_image_new_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockFlutterNativeImageNewPlatform
    with MockPlatformInterfaceMixin
    implements FlutterNativeImageNewPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
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
