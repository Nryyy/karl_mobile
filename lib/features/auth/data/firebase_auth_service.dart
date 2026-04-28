import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../domain/auth_failure.dart';
import '../domain/auth_service.dart';

/// Firebase-backed authentication service.
class FirebaseAuthService implements AuthService {
  FirebaseAuthService({FirebaseAuth? auth, GoogleSignIn? googleSignIn})
    : _authFactory = (() => auth ?? FirebaseAuth.instance),
      _googleSignInFactory = (() => googleSignIn ?? GoogleSignIn.instance);

  final FirebaseAuth Function() _authFactory;
  final GoogleSignIn Function() _googleSignInFactory;

  FirebaseAuth? _auth;
  GoogleSignIn? _googleSignIn;

  FirebaseAuth get _firebaseAuth => _auth ??= _authFactory();

  GoogleSignIn get _googleSignInClient =>
      _googleSignIn ??= _googleSignInFactory();

  @override
  Future<String> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return _displayNameForUser(userCredential.user, fallbackEmail: email);
    } on FirebaseAuthException catch (error) {
      throw AuthFailure(_messageForAuthError(error));
    } on Exception {
      throw const AuthFailure('Не вдалося увійти. Спробуйте ще раз.');
    }
  }

  @override
  Future<String> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        final provider = GoogleAuthProvider();
        final userCredential = await _firebaseAuth.signInWithPopup(provider);
        final fallbackEmail = userCredential.user?.email ?? 'user@example.com';
        return _displayNameForUser(
          userCredential.user,
          fallbackEmail: fallbackEmail,
        );
      }

      await _googleSignInClient.initialize();
      final googleUser = await _googleSignInClient.authenticate();

      final googleAuth = googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );
      final userCredential = await _firebaseAuth.signInWithCredential(
        credential,
      );
      return _displayNameForUser(
        userCredential.user,
        fallbackEmail: googleUser.email,
      );
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) {
        throw const AuthFailure('Вхід через Google скасовано.');
      }

      if (error.code == GoogleSignInExceptionCode.clientConfigurationError ||
          error.code == GoogleSignInExceptionCode.providerConfigurationError) {
        throw const AuthFailure('Google Sign-In не налаштовано.');
      }

      throw AuthFailure(error.description ?? 'Не вдалося увійти через Google.');
    } on FirebaseAuthException catch (error) {
      throw AuthFailure(_messageForAuthError(error));
    } on AuthFailure {
      rethrow;
    } on Exception {
      throw const AuthFailure('Не вдалося увійти через Google.');
    }
  }

  @override
  Future<void> signOut() async {
    if (kIsWeb) {
      await _firebaseAuth.signOut();
      return;
    }

    await Future.wait<void>([
      _firebaseAuth.signOut(),
      _googleSignInClient.signOut(),
    ]);
  }

  String _displayNameForUser(User? user, {required String fallbackEmail}) {
    final displayName = user?.displayName?.trim();
    if (displayName != null && displayName.isNotEmpty) {
      return displayName;
    }

    final email = user?.email ?? fallbackEmail;
    final localPart = email.split('@').first;
    if (localPart.isEmpty) {
      return 'користувач';
    }

    return localPart
        .replaceAll(RegExp(r'[._-]+'), ' ')
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map((part) => part[0].toUpperCase() + part.substring(1))
        .join(' ');
  }

  String _messageForAuthError(FirebaseAuthException error) {
    return switch (error.code) {
      'user-not-found' => 'Користувача з таким email не знайдено.',
      'wrong-password' => 'Невірний пароль.',
      'invalid-email' => 'Некоректний формат email.',
      'user-disabled' => 'Обліковий запис заблоковано.',
      'invalid-credential' => 'Невірні облікові дані.',
      'account-exists-with-different-credential' =>
        'Цей email уже використовується іншим методом входу.',
      'popup-closed-by-user' => 'Вхід через Google скасовано.',
      'popup-blocked' =>
        'Браузер заблокував pop-up. Дозвольте pop-up для цього сайту.',
      'unauthorized-domain' =>
        'Поточний домен не додано до Authorized domains у Firebase.',
      'operation-not-allowed' =>
        'Google провайдер вимкнений у Firebase Authentication.',
      _ => 'Не вдалося виконати вхід. Спробуйте ще раз.',
    };
  }
}
