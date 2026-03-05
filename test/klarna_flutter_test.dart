import 'package:flutter_test/flutter_test.dart';
import 'package:klarna_flutter/klarna_flutter.dart';
import 'package:klarna_flutter/klarna_flutter_platform_interface.dart';
import 'package:klarna_flutter/klarna_flutter_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockKlarnaFlutterPlatform
    with MockPlatformInterfaceMixin
    implements KlarnaFlutterPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final KlarnaFlutterPlatform initialPlatform = KlarnaFlutterPlatform.instance;

  test('$MethodChannelKlarnaFlutter is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelKlarnaFlutter>());
  });

  test('getPlatformVersion', () async {
    KlarnaFlutter klarnaFlutterPlugin = KlarnaFlutter();
    MockKlarnaFlutterPlatform fakePlatform = MockKlarnaFlutterPlatform();
    KlarnaFlutterPlatform.instance = fakePlatform;

    expect(await klarnaFlutterPlugin.getPlatformVersion(), '42');
  });
}
