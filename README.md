# Klarna Flutter

A complete Flutter plugin for integrating Klarna payments natively into your mobile apps. This plugin serves as a bridge to the official Klarna Mobile SDKs for both iOS and Android.

## Features

- Native Klarna Mobile SDK integration for iOS and Android
- Full payment flow: `initialize`, `load`, `authorize`, `reauthorize`, and `finalize`
- Synchronous and asynchronous event handling callbacks
- Seamless deep link / return URL routing for third-party authentication (e.g., Banking Apps)

---

## 🚀 Getting Started

### Prerequisites

Before integrating Klarna, ensure you have:
1. **Klarna Merchant Account**: Sign up at the [Klarna Merchant Portal](https://www.klarna.com/international/business/).
2. **API Credentials**: Sandbox or Production API credentials.
3. **Backend Integration**: Your backend server must be capable of generating Klarna Payment Sessions and Orders.

### Installation

Add `klarna_flutter` to your `pubspec.yaml`:

```yaml
dependencies:
  klarna_flutter:
    path: ../klarna_flutter # Replace with pub.dev constraint when deployed
```

---

## ⚙️ Native Setup Instructions

To properly support 3rd-party banking app authentications natively triggered by Klarna, you must configure your app's return URLs (Deep Links) for both Android and iOS.

---

### 🟢 Android Setup

#### 1. Configure Activity Launch Mode & Intent Filters

Klarna must return to your active application session after an external browser or banking app completes authentication.

In your `android/app/src/main/AndroidManifest.xml`:
1. Change your `MainActivity`'s `android:launchMode` to `"singleTask"`.
2. Delete the `android:taskAffinity=""` attribute from the `MainActivity` if it exists.
3. Add the intent-filter for your custom return URL scheme.

```xml
<activity
    android:name=".MainActivity"
    android:launchMode="singleTask"
    ... >
    <!-- Existing intent filters -->
    
    <!-- Klarna Deep Link Return URL -->
    <intent-filter>
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <!-- Define your custom scheme here -->
        <data android:scheme="your-custom-scheme" android:host="klarna-return" />
    </intent-filter>
</activity>
```

#### 2. Extend FlutterFragmentActivity

The Klarna Android SDK requires a `FragmentActivity` context to present 3D Secure modal dialogs and external browser tabs. 

Update your `MainActivity`.kt or .java to inherit from `FlutterFragmentActivity`:

```kotlin
package com.yourcompany.app

import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity: FlutterFragmentActivity() {
}
```

---

### 🍎 iOS Setup

#### 1. Define URL Scheme in Info.plist

Add your custom URL scheme to `ios/Runner/Info.plist` so the OS can route the authentication callback to your app:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>your-custom-scheme</string>
        </array>
    </dict>
</array>
```

#### 2. Pass OpenURL events in AppDelegate

Open `ios/Runner/AppDelegate.swift` and ensure Flutter handles the `openURL` events. Under the hood, this plugin listens via `NSNotification` for Klarna returns:

```swift
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // Ensure this is present or handled by Flutter framework natively. 
  // Custom plugins (like klarna_flutter) will intercept this gracefully.
  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey : Any] = [:]
  ) -> Bool {
    return super.application(app, open: url, options: options)
  }
}
```

---

## 💻 Flutter Usage

### 1. Payment Initialization Flow

First, hit your backend to generate a Klarna Payment Session and retrieve the `client_token`. 
Then, provide a full-screen or sized view for `KlarnaPaymentView`.

```dart
import 'package:klarna_flutter/klarna_flutter.dart';

class KlarnaCheckoutScreen extends StatefulWidget {
  final String clientToken;

  const KlarnaCheckoutScreen({Key? key, required this.clientToken}) : super(key: key);

  @override
  State<KlarnaCheckoutScreen> createState() => _KlarnaCheckoutScreenState();
}

class _KlarnaCheckoutScreenState extends State<KlarnaCheckoutScreen> {
  final _paymentViewKey = GlobalKey<KlarnaPaymentViewState>();
  bool _isLoading = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Klarna Checkout')),
      body: Stack(
        children: [
          KlarnaPaymentView(
            key: _paymentViewKey,
            category: 'klarna',
            returnUrl: 'your-custom-scheme://klarna-return',
            
            // 1. Wait for platform view creation before initializing
            onCreated: (state) {
              state.initialize(widget.clientToken);
            },
            
            // 2. Load the view once successfully initialized
            onInitialized: () {
              _paymentViewKey.currentState?.load();
            },
            
            // 3. View is ready for the user
            onLoaded: () {
              setState(() => _isLoading = false);
            },
            
            // 4. Handle authorization results
            onAuthorized: (result) {
              if (result.approved && result.authToken != null) {
                // Submit the authToken to your backend to finalize the order!
                _submitOrderToBackend(result.authToken!);
              } else {
                // Payment was dismissed or denied
              }
            },
            
            onError: (error) {
              print('Klarna Error: ${error.message}');
            },
          ),
          
          if (_isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: () {
              // Trigger authorization flow manually
              _paymentViewKey.currentState?.authorize();
            },
            child: const Text('Pay with Klarna'),
          ),
        ),
      ),
    );
  }

  void _submitOrderToBackend(String authToken) {
    // Implement your server-side order creation here
    // POST /your-api/orders { klarna_auth_token: authToken }
  }
}
```

### 2. Available Callbacks

| Property | Type | Occurs When |
|-----------|------|-------------|
| `onCreated` | `Function(KlarnaPaymentViewState)` | The native view has rendered across the platform channel. Call `.initialize()` here. |
| `onInitialized` | `VoidCallback?` | Processing the `clientToken` was successful. Call `.load()`. |
| `onLoaded` | `VoidCallback?` | Klarna's UI has fully loaded and can be presented. |
| `onAuthorized` | `Function(KlarnaAuthorizationResult)?` | User authorized the payment, yielding an `authToken`. |
| `onError` | `Function(KlarnaError)?` | Something went wrong. Includes error `name` and `message`. |

---

## 🛠 Flow Diagram 

```text
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Backend   │     │  Flutter    │     │ Klarna SDK  │
└─────┬───────┘     └─────┬───────┘     └─────┬───────┘
      │  [Create Session] │                   │
      │◄──────────────────│                   │
      │   client_token    │                   │
      │──────────────────►│                   │
                          │   initialize()    │
                          │──────────────────►│
                          │   onInitialized   │
                          │◄──────────────────│
                          │   load()          │
                          │──────────────────►│
                          │   onLoaded        │
                          │◄──────────────────│
                          │   authorize()     │
                          │──────────────────►│
                          │   onAuthorized    │
      │  [Create Order]   │◄──────────────────│
      │◄──────────────────│    (authToken)    │
      │  finalize order   │                   │
      │──────────────────►│                   │
```

---

### Resources

- [Klarna In-App Documentation](https://docs.klarna.com/in-app/)
- [Klarna Payment Methods integration](https://docs.klarna.com/klarna-payments/)
- [Standard Error Codes](https://docs.klarna.com/in-app/error-handling/)

