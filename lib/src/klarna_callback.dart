/// Callback interface for Klarna payment view events.
abstract class KlarnaPaymentViewCallback {
  /// Called when the payment view has been initialized successfully.
  void onInitialized();

  /// Called when the payment view content has been loaded.
  void onLoaded();

  /// Called when payment review should be displayed.
  /// [showForm] indicates whether to show the form.
  void onLoadPaymentReview(bool showForm);

  /// Called when authorization is complete.
  /// [approved] indicates if the payment was approved.
  /// [authToken] is the authorization token to use for creating an order (if approved).
  /// [finalizeRequired] indicates if finalize() needs to be called.
  void onAuthorized({
    required bool approved,
    String? authToken,
    bool? finalizeRequired,
  });

  /// Called when reauthorization is complete.
  /// [approved] indicates if the reauthorization was approved.
  /// [authToken] is the new authorization token (if approved).
  void onReauthorized({required bool approved, String? authToken});

  /// Called when finalization is complete.
  /// [approved] indicates if the finalization was approved.
  /// [authToken] is the final authorization token (if approved).
  void onFinalized({required bool approved, String? authToken});

  /// Called when an error occurs.
  /// [name] is the error name/code.
  /// [message] is the error message.
  /// [isFatal] indicates if this is a fatal error.
  void onErrorOccurred({
    required String name,
    required String message,
    required bool isFatal,
  });
}

/// A mixin that provides default implementations for [KlarnaPaymentViewCallback].
/// Override only the methods you need.
mixin KlarnaPaymentViewCallbackMixin implements KlarnaPaymentViewCallback {
  @override
  void onInitialized() {}

  @override
  void onLoaded() {}

  @override
  void onLoadPaymentReview(bool showForm) {}

  @override
  void onAuthorized({
    required bool approved,
    String? authToken,
    bool? finalizeRequired,
  }) {}

  @override
  void onReauthorized({required bool approved, String? authToken}) {}

  @override
  void onFinalized({required bool approved, String? authToken}) {}

  @override
  void onErrorOccurred({
    required String name,
    required String message,
    required bool isFatal,
  }) {}
}
