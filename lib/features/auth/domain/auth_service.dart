/// Contract for authentication flows used by the auth feature.
abstract class AuthService {
  /// Signs in the user with email and password.
  Future<String> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  /// Signs in the user with Google.
  Future<String> signInWithGoogle();

  /// Signs the current user out.
  Future<void> signOut();
}
