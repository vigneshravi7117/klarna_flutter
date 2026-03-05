import Flutter
import UIKit

public class KlarnaFlutterPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "klarna_flutter", binaryMessenger: registrar.messenger())
    let instance = KlarnaFlutterPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)

    // Register Platform View Factory for KlarnaPaymentView
    let factory = KlarnaPaymentViewFactory(messenger: registrar.messenger())
    registrar.register(factory, withId: "klarna_flutter/payment_view")
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformVersion":
      result("iOS " + UIDevice.current.systemVersion)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  public func application(
    _ application: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey : Any] = [:]
  ) -> Bool {
    // Post notification so KlarnaPlatformView can intercept and resume
    NotificationCenter.default.post(name: NSNotification.Name("KlarnaFlutterOpenURL"), object: url)
    return true
  }
}
