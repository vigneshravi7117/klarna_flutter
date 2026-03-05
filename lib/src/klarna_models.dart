/// Models for Klarna Flutter plugin

/// Represents the result of a Klarna authorization.
class KlarnaAuthorizationResult {
  /// Whether the authorization was approved.
  final bool approved;

  /// The authorization token if approved.
  /// Use this token to create an order on your server.
  final String? authToken;

  /// Whether finalization is required.
  /// If true, you need to call finalize() to complete the payment.
  final bool? finalizeRequired;

  const KlarnaAuthorizationResult({
    required this.approved,
    this.authToken,
    this.finalizeRequired,
  });

  factory KlarnaAuthorizationResult.fromMap(Map<String, dynamic> map) {
    return KlarnaAuthorizationResult(
      approved: map['approved'] as bool? ?? false,
      authToken: map['authToken'] as String?,
      finalizeRequired: map['finalizeRequired'] as bool?,
    );
  }

  @override
  String toString() {
    return 'KlarnaAuthorizationResult(approved: $approved, authToken: $authToken, finalizeRequired: $finalizeRequired)';
  }
}

/// Represents the result of a Klarna reauthorization.
class KlarnaReauthorizationResult {
  /// Whether the reauthorization was approved.
  final bool approved;

  /// The authorization token if approved.
  final String? authToken;

  const KlarnaReauthorizationResult({required this.approved, this.authToken});

  factory KlarnaReauthorizationResult.fromMap(Map<String, dynamic> map) {
    return KlarnaReauthorizationResult(
      approved: map['approved'] as bool? ?? false,
      authToken: map['authToken'] as String?,
    );
  }

  @override
  String toString() {
    return 'KlarnaReauthorizationResult(approved: $approved, authToken: $authToken)';
  }
}

/// Represents the result of a Klarna finalization.
class KlarnaFinalizationResult {
  /// Whether the finalization was approved.
  final bool approved;

  /// The authorization token if approved.
  final String? authToken;

  const KlarnaFinalizationResult({required this.approved, this.authToken});

  factory KlarnaFinalizationResult.fromMap(Map<String, dynamic> map) {
    return KlarnaFinalizationResult(
      approved: map['approved'] as bool? ?? false,
      authToken: map['authToken'] as String?,
    );
  }

  @override
  String toString() {
    return 'KlarnaFinalizationResult(approved: $approved, authToken: $authToken)';
  }
}

/// Represents an error that occurred in the Klarna SDK.
class KlarnaError {
  /// The name/code of the error.
  final String name;

  /// The error message.
  final String message;

  /// Whether this is a fatal error.
  final bool isFatal;

  const KlarnaError({
    required this.name,
    required this.message,
    required this.isFatal,
  });

  factory KlarnaError.fromMap(Map<String, dynamic> map) {
    return KlarnaError(
      name: map['name'] as String? ?? 'UNKNOWN_ERROR',
      message: map['message'] as String? ?? 'An unknown error occurred',
      isFatal: map['isFatal'] as bool? ?? false,
    );
  }

  @override
  String toString() {
    return 'KlarnaError(name: $name, message: $message, isFatal: $isFatal)';
  }
}

/// Represents a payment method category returned from Klarna session.
class KlarnaPaymentMethodCategory {
  /// The identifier for this payment category (e.g., "klarna").
  final String identifier;

  /// The display name for this payment method.
  final String name;

  /// URL for the descriptive asset image.
  final String? descriptiveAssetUrl;

  /// URL for the standard asset image.
  final String? standardAssetUrl;

  const KlarnaPaymentMethodCategory({
    required this.identifier,
    required this.name,
    this.descriptiveAssetUrl,
    this.standardAssetUrl,
  });

  factory KlarnaPaymentMethodCategory.fromMap(Map<String, dynamic> map) {
    final assetUrls = map['asset_urls'] as Map<String, dynamic>?;
    return KlarnaPaymentMethodCategory(
      identifier: map['identifier'] as String? ?? '',
      name: map['name'] as String? ?? '',
      descriptiveAssetUrl: assetUrls?['descriptive'] as String?,
      standardAssetUrl: assetUrls?['standard'] as String?,
    );
  }

  @override
  String toString() {
    return 'KlarnaPaymentMethodCategory(identifier: $identifier, name: $name)';
  }
}

/// Logging levels for Klarna SDK.
enum KlarnaLoggingLevel {
  /// No logging.
  off,

  /// Log error messages only.
  error,

  /// Log all messages (debug and error).
  verbose,
}
