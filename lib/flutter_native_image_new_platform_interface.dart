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
}
