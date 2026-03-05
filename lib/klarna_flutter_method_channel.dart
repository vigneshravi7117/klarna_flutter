import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'klarna_flutter_platform_interface.dart';

/// An implementation of [KlarnaFlutterPlatform] that uses method channels.
class MethodChannelKlarnaFlutter extends KlarnaFlutterPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('klarna_flutter');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
