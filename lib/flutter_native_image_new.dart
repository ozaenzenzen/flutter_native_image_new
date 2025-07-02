
import 'flutter_native_image_new_platform_interface.dart';

class FlutterNativeImageNew {
  Future<String?> getPlatformVersion() {
    return FlutterNativeImageNewPlatform.instance.getPlatformVersion();
  }
}
