/// Describes an authentication error in a user-friendly form.
class AuthFailure implements Exception {
  /// Creates an authentication failure with a message for the user.
  const AuthFailure(this.message);

  /// User-facing failure message.
  final String message;

  @override
  String toString() => 'AuthFailure: $message';
}
