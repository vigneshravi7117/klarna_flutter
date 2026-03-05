import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'klarna_flutter_method_channel.dart';

abstract class KlarnaFlutterPlatform extends PlatformInterface {
  /// Constructs a KlarnaFlutterPlatform.
  KlarnaFlutterPlatform() : super(token: _token);

  static final Object _token = Object();

  static KlarnaFlutterPlatform _instance = MethodChannelKlarnaFlutter();

  /// The default instance of [KlarnaFlutterPlatform] to use.
  ///
  /// Defaults to [MethodChannelKlarnaFlutter].
  static KlarnaFlutterPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [KlarnaFlutterPlatform] when
  /// they register themselves.
  static set instance(KlarnaFlutterPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
