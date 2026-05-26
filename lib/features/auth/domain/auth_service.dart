/// Contract for authentication flows used by the auth feature.
abstract class AuthService {
  /// Signs in the user with email and password.
  Future<String> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  /// Signs in the user with Google.
  Future<String> signInWithGoogle();

  /// Registers a new user with email, password and full name.
  ///
  /// Returns the display name on success.
  Future<String> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String fullName,
  });

  /// Signs the current user out.
  Future<void> signOut();
}
