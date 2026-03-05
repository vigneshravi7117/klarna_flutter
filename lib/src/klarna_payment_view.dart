import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'klarna_models.dart';

/// A Flutter widget that displays a native Klarna payment view.
///
/// This widget wraps the native [KlarnaPaymentView] from the Klarna SDK and
/// provides methods to interact with it.
///
/// ## Usage
///
/// ```dart
/// KlarnaPaymentView(
///   category: 'klarna',
///   returnUrl: 'your-app-scheme://klarna-return',
///   onInitialized: () {
///     // Load the payment view
///   },
///   onLoaded: () {
///     // Payment view is ready
///   },
///   onAuthorized: (result) {
///     if (result.approved && result.authToken != null) {
///       // Send authToken to your server to create order
///     }
///   },
///   onError: (error) {
///     // Handle error
///   },
/// )
/// ```
class KlarnaPaymentView extends StatefulWidget {
  /// The payment method category. Should be "klarna".
  final String category;

  /// The return URL scheme for your app.
  /// This should match the intent-filter in your AndroidManifest.xml.
  final String? returnUrl;

  /// Called when the payment view has been created on the platform side.
  /// You should wait for this before calling methods like [initialize].
  final void Function(KlarnaPaymentViewState state)? onCreated;

  /// Called when the payment view has been initialized.
  final VoidCallback? onInitialized;

  /// Called when the payment view content has been loaded.
  final VoidCallback? onLoaded;

  /// Called when payment review should be displayed.
  final void Function(bool showForm)? onLoadPaymentReview;

  /// Called when authorization is complete.
  final void Function(KlarnaAuthorizationResult result)? onAuthorized;

  /// Called when reauthorization is complete.
  final void Function(KlarnaReauthorizationResult result)? onReauthorized;

  /// Called when finalization is complete.
  final void Function(KlarnaFinalizationResult result)? onFinalized;

  /// Called when an error occurs.
  final void Function(KlarnaError error)? onError;

  /// The set of gesture recognizers that this widget will use.
  final Set<Factory<OneSequenceGestureRecognizer>>? gestureRecognizers;

  const KlarnaPaymentView({
    super.key,
    this.category = 'klarna',
    this.returnUrl,
    this.onCreated,
    this.onInitialized,
    this.onLoaded,
    this.onLoadPaymentReview,
    this.onAuthorized,
    this.onReauthorized,
    this.onFinalized,
    this.onError,
    this.gestureRecognizers,
  });

  @override
  State<KlarnaPaymentView> createState() => KlarnaPaymentViewState();
}

/// State for [KlarnaPaymentView].
///
/// Use this state to control the payment view programmatically.
class KlarnaPaymentViewState extends State<KlarnaPaymentView> {
  MethodChannel? _channel;
  bool _isInitialized = false;

  /// Whether the payment view has been initialized with a client token.
  bool get isInitialized => _isInitialized;

  @override
  Widget build(BuildContext context) {
    const viewType = 'klarna_flutter/payment_view';

    final creationParams = <String, dynamic>{
      'category': widget.category,
      if (widget.returnUrl != null) 'returnUrl': widget.returnUrl,
    };

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return AndroidView(
          viewType: viewType,
          creationParams: creationParams,
          creationParamsCodec: const StandardMessageCodec(),
          onPlatformViewCreated: _onPlatformViewCreated,
          gestureRecognizers: widget.gestureRecognizers,
        );
      case TargetPlatform.iOS:
        return UiKitView(
          viewType: viewType,
          creationParams: creationParams,
          creationParamsCodec: const StandardMessageCodec(),
          onPlatformViewCreated: _onPlatformViewCreated,
          gestureRecognizers: widget.gestureRecognizers,
        );
      default:
        return const Center(
          child: Text('Klarna Payment View is not supported on this platform'),
        );
    }
  }

  void _onPlatformViewCreated(int viewId) {
    _channel = MethodChannel('klarna_flutter/payment_view_$viewId');
    _channel!.setMethodCallHandler(_handleMethodCall);
    widget.onCreated?.call(this);
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onInitialized':
        _isInitialized = true;
        widget.onInitialized?.call();
        break;
      case 'onLoaded':
        widget.onLoaded?.call();
        break;
      case 'onLoadPaymentReview':
        final args = call.arguments as Map<Object?, Object?>;
        final showForm = args['showForm'] as bool? ?? false;
        widget.onLoadPaymentReview?.call(showForm);
        break;
      case 'onAuthorized':
        final args = Map<String, dynamic>.from(call.arguments as Map);
        final result = KlarnaAuthorizationResult.fromMap(args);
        widget.onAuthorized?.call(result);
        break;
      case 'onReauthorized':
        final args = Map<String, dynamic>.from(call.arguments as Map);
        final result = KlarnaReauthorizationResult.fromMap(args);
        widget.onReauthorized?.call(result);
        break;
      case 'onFinalized':
        final args = Map<String, dynamic>.from(call.arguments as Map);
        final result = KlarnaFinalizationResult.fromMap(args);
        widget.onFinalized?.call(result);
        break;
      case 'onErrorOccurred':
        final args = Map<String, dynamic>.from(call.arguments as Map);
        final error = KlarnaError.fromMap(args);
        widget.onError?.call(error);
        break;
    }
  }

  /// Initialize the payment session with the client token.
  ///
  /// [clientToken] is the token received from creating a Klarna payment session
  /// on your server.
  ///
  /// After successful initialization, [onInitialized] will be called.
  Future<void> initialize(String clientToken) async {
    if (_channel == null) {
      throw StateError(
        'KlarnaPaymentView has not been created yet. '
        'Wait for the widget to build before calling initialize.',
      );
    }
    await _channel!.invokeMethod('initialize', {'clientToken': clientToken});
  }

  /// Load the payment view content.
  ///
  /// [sessionData] is an optional JSON string with order data to update the session.
  ///
  /// After successful loading, [onLoaded] will be called.
  Future<void> load({String? sessionData}) async {
    if (_channel == null) {
      throw StateError('KlarnaPaymentView has not been initialized');
    }
    await _channel!.invokeMethod('load', {'sessionData': sessionData});
  }

  /// Authorize the payment session.
  ///
  /// [sessionData] is an optional JSON string with order data to update the session.
  /// [autoFinalize] if set to false, you may need to call [finalize] afterwards.
  ///
  /// After authorization, [onAuthorized] will be called with the result.
  Future<void> authorize({
    String? sessionData,
    bool autoFinalize = true,
  }) async {
    if (_channel == null) {
      throw StateError('KlarnaPaymentView has not been initialized');
    }
    await _channel!.invokeMethod('authorize', {
      'sessionData': sessionData,
      'autoFinalize': autoFinalize,
    });
  }

  /// Reauthorize the payment session.
  ///
  /// Use this if you need to update the session after authorization
  /// (e.g., if the cart changed).
  ///
  /// [sessionData] is an optional JSON string with order data to update the session.
  ///
  /// After reauthorization, [onReauthorized] will be called with the result.
  Future<void> reauthorize({String? sessionData}) async {
    if (_channel == null) {
      throw StateError('KlarnaPaymentView has not been initialized');
    }
    await _channel!.invokeMethod('reauthorize', {'sessionData': sessionData});
  }

  /// Finalize the payment session.
  ///
  /// This is only needed if [autoFinalize] was set to false in [authorize]
  /// and [KlarnaAuthorizationResult.finalizeRequired] is true.
  ///
  /// [sessionData] is an optional JSON string with order data to update the session.
  ///
  /// After finalization, [onFinalized] will be called with the result.
  Future<void> finalize({String? sessionData}) async {
    if (_channel == null) {
      throw StateError('KlarnaPaymentView has not been initialized');
    }
    await _channel!.invokeMethod('finalize', {'sessionData': sessionData});
  }
}
