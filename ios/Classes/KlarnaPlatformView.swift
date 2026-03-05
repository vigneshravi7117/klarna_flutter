import Flutter
import UIKit
import KlarnaMobileSDK

class KlarnaPlatformView: NSObject, FlutterPlatformView, KlarnaPaymentEventListener {
    private var _view: UIView
    private var paymentView: KlarnaPaymentView?
    private var methodChannel: FlutterMethodChannel
    
    private let category: String
    private let returnUrl: URL?

    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?,
        binaryMessenger messenger: FlutterBinaryMessenger
    ) {
        _view = UIView(frame: frame)
        
        methodChannel = FlutterMethodChannel(name: "klarna_flutter/payment_view_\(viewId)", binaryMessenger: messenger)
        
        let params = args as? [String: Any]
        category = params?["category"] as? String ?? "klarna"
        
        if let returnUrlString = params?["returnUrl"] as? String, let url = URL(string: returnUrlString) {
            returnUrl = url
        } else {
            returnUrl = nil
        }

        super.init()
        
        setupKlarnaPaymentView()
        
        methodChannel.setMethodCallHandler({ [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
            self?.handle(call, result: result)
        })
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleOpenURL(_:)),
            name: NSNotification.Name("KlarnaFlutterOpenURL"),
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func view() -> UIView {
        return _view
    }

    @objc private func handleOpenURL(_ notification: Notification) {
        if let url = notification.object as? URL {
            // Unclear if Klarna iOS SDK needs explicit `resume` like some SDKs.
            // Often AppDelegate returnUrl is passed to Klarna if they have an intent bridge.
            // But usually the SDK listens themselves or doesn't need it. 
            // In case there is an API, we can leave this hook ready.
        }
    }

    private func setupKlarnaPaymentView() {
        do {
            if let returnUrl = returnUrl {
                paymentView = try KlarnaPaymentView(category: category, eventListener: self, returnURL: returnUrl)
            } else {
                paymentView = try KlarnaPaymentView(category: category, eventListener: self)
            }
            
            if let paymentView = paymentView {
                paymentView.translatesAutoresizingMaskIntoConstraints = false
                _view.addSubview(paymentView)
                
                NSLayoutConstraint.activate([
                    paymentView.topAnchor.constraint(equalTo: _view.topAnchor),
                    paymentView.leadingAnchor.constraint(equalTo: _view.leadingAnchor),
                    paymentView.trailingAnchor.constraint(equalTo: _view.trailingAnchor),
                    paymentView.bottomAnchor.constraint(equalTo: _view.bottomAnchor)
                ])
            }
        } catch {
            sendError(name: "INITIALIZATION_ERROR", message: "Failed to initialize KlarnaPaymentView: \(error.localizedDescription)")
        }
    }

    private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "initialize":
            guard let args = call.arguments as? [String: Any],
                  let clientToken = args["clientToken"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "clientToken is required", details: nil))
                return
            }
            initializeView(clientToken: clientToken, result: result)
        case "load":
            let args = call.arguments as? [String: Any]
            let sessionData = args?["sessionData"] as? String
            loadView(sessionData: sessionData, result: result)
        case "authorize":
            let args = call.arguments as? [String: Any]
            let sessionData = args?["sessionData"] as? String
            let autoFinalize = args?["autoFinalize"] as? Bool ?? true
            authorizeView(autoFinalize: autoFinalize, sessionData: sessionData, result: result)
        case "reauthorize":
            let args = call.arguments as? [String: Any]
            let sessionData = args?["sessionData"] as? String
            reauthorizeView(sessionData: sessionData, result: result)
        case "finalize":
            let args = call.arguments as? [String: Any]
            let sessionData = args?["sessionData"] as? String
            finalizeView(sessionData: sessionData, result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func initializeView(clientToken: String, result: @escaping FlutterResult) {
        guard let paymentView = paymentView else {
            result(FlutterError(code: "VIEW_NOT_INITIALIZED", message: "KlarnaPaymentView not initialized", details: nil))
            return
        }
        paymentView.initialize(clientToken: clientToken)
        result(nil)
    }

    private func loadView(sessionData: String?, result: @escaping FlutterResult) {
        guard let paymentView = paymentView else {
            result(FlutterError(code: "VIEW_NOT_INITIALIZED", message: "KlarnaPaymentView not initialized", details: nil))
            return
        }
        paymentView.load(sessionData: sessionData)
        result(nil)
    }

    private func authorizeView(autoFinalize: Bool, sessionData: String?, result: @escaping FlutterResult) {
        guard let paymentView = paymentView else {
            result(FlutterError(code: "VIEW_NOT_INITIALIZED", message: "KlarnaPaymentView not initialized", details: nil))
            return
        }
        paymentView.authorize(autoFinalize: autoFinalize, sessionData: sessionData)
        result(nil)
    }

    private func reauthorizeView(sessionData: String?, result: @escaping FlutterResult) {
        guard let paymentView = paymentView else {
            result(FlutterError(code: "VIEW_NOT_INITIALIZED", message: "KlarnaPaymentView not initialized", details: nil))
            return
        }
        paymentView.reauthorize(sessionData: sessionData)
        result(nil)
    }

    private func finalizeView(sessionData: String?, result: @escaping FlutterResult) {
        guard let paymentView = paymentView else {
            result(FlutterError(code: "VIEW_NOT_INITIALIZED", message: "KlarnaPaymentView not initialized", details: nil))
            return
        }
        paymentView.finalize(sessionData: sessionData)
        result(nil)
    }

    // MARK: - KlarnaPaymentEventListener

    func klarnaInitialized(paymentView: KlarnaPaymentView) {
        methodChannel.invokeMethod("onInitialized", arguments: nil)
    }

    func klarnaLoaded(paymentView: KlarnaPaymentView) {
        methodChannel.invokeMethod("onLoaded", arguments: nil)
    }

    func klarnaLoadedPaymentReview(paymentView: KlarnaPaymentView, showForm: Bool) {
        methodChannel.invokeMethod("onLoadPaymentReview", arguments: ["showForm": showForm])
    }

    func klarnaAuthorized(paymentView: KlarnaPaymentView, approved: Bool, authToken: String?, finalizeRequired: Bool) {
        methodChannel.invokeMethod("onAuthorized", arguments: [
            "approved": approved,
            "authToken": authToken,
            "finalizeRequired": finalizeRequired
        ])
    }

    func klarnaReauthorized(paymentView: KlarnaPaymentView, approved: Bool, authToken: String?) {
        methodChannel.invokeMethod("onReauthorized", arguments: [
            "approved": approved,
            "authToken": authToken
        ])
    }

    func klarnaFinalized(paymentView: KlarnaPaymentView, approved: Bool, authToken: String?) {
        methodChannel.invokeMethod("onFinalized", arguments: [
            "approved": approved,
            "authToken": authToken
        ])
    }

    func klarnaFailed(inPaymentView paymentView: KlarnaPaymentView, withError error: KlarnaPaymentError) {
        methodChannel.invokeMethod("onErrorOccurred", arguments: [
            "name": error.name,
            "message": error.message,
            "isFatal": error.isFatal
        ])
    }

    func klarnaResized(paymentView: KlarnaPaymentView, to newHeight: CGFloat) {
        // Option to relay resize events if necessary, although Flutter wraps the native view
    }

    private func sendError(name: String, message: String) {
        methodChannel.invokeMethod("onErrorOccurred", arguments: [
            "name": name,
            "message": message,
            "isFatal": true
        ])
    }
}
