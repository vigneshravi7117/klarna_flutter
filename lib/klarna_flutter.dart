/// Klarna Flutter Plugin
///
/// A Flutter plugin for integrating Klarna payments into your app.
/// This plugin wraps the native Klarna Mobile SDK for Android and iOS.
///
/// ## Getting Started
///
/// 1. Create a payment session on your server using Klarna's API
/// 2. Pass the `client_token` to initialize the [KlarnaPaymentView]
/// 3. Handle the authorization callback and create an order on your server
///
/// ## Example
///
/// ```dart
/// import 'package:klarna_flutter/klarna_flutter.dart';
///
/// // In your widget
/// final _paymentViewKey = GlobalKey<KlarnaPaymentViewState>();
///
/// KlarnaPaymentView(
///   key: _paymentViewKey,
///   category: 'klarna',
///   returnUrl: 'your-app-scheme://klarna-return',
///   onInitialized: () {
///     // Load the payment widget (optional)
///     _paymentViewKey.currentState?.load();
///   },
///   onAuthorized: (result) {
///     if (result.approved && result.authToken != null) {
///       // Send authToken to your server to create order
///     }
///   },
///   onError: (error) {
///     print('Klarna error: ${error.message}');
///   },
/// )
///
/// // Initialize with client token from your server
/// _paymentViewKey.currentState?.initialize(clientToken);
/// ```
library klarna_flutter;

// Export models
export 'src/klarna_models.dart';

// Export callback interface
export 'src/klarna_callback.dart';

// Export the payment view widget
export 'src/klarna_payment_view.dart';

// Keep platform interface exports for platform-specific implementations
export 'klarna_flutter_platform_interface.dart';
export 'klarna_flutter_method_channel.dart';

import 'klarna_flutter_platform_interface.dart';

/// Main class for Klarna Flutter plugin.
///
/// Use [KlarnaPaymentView] widget for the payment UI.
/// This class provides utility methods.
class KlarnaFlutter {
  /// Get the platform version (for debugging).
  Future<String?> getPlatformVersion() {
    return KlarnaFlutterPlatform.instance.getPlatformVersion();
  }
}
