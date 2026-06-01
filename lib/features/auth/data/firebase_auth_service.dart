import 'dart:convert';
import 'dart:developer' as developer;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

import '../../../core/config/api_config.dart';
import '../domain/auth_failure.dart';
import '../domain/auth_service.dart';

/// Firebase-backed authentication service.
class FirebaseAuthService implements AuthService {
  FirebaseAuthService({
    FirebaseAuth? auth,
    GoogleSignIn? googleSignIn,
  })  : _authFactory = (() => auth ?? FirebaseAuth.instance),
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
  Future<String> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await credential.user?.updateDisplayName(fullName.trim());
      await credential.user?.reload();

      final idToken = await credential.user?.getIdToken();
      if (idToken != null) {
        await _registerUserInBackend(
          email: email.trim(),
          fullName: fullName.trim(),
          idToken: idToken,
        );
      }

      final name = fullName.trim().isNotEmpty ? fullName.trim() : email.split('@').first;
      return name;
    } on FirebaseAuthException catch (error) {
      throw AuthFailure(_messageForSignUpError(error));
    } on AuthFailure {
      rethrow;
    } on Exception {
      throw const AuthFailure('Не вдалося зареєструватися. Спробуйте ще раз.');
    }
  }

  Future<void> _registerUserInBackend({
    required String email,
    required String fullName,
    required String idToken,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/Users');
      await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({'email': email, 'fullName': fullName}),
      ).timeout(ApiConfig.requestTimeout);
    } on Exception catch (error) {
      developer.log(
        'Failed to register user in backend.',
        name: 'karl.auth',
        error: error,
      );
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

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (error) {
      throw AuthFailure(_messageForPasswordResetError(error));
    } on Exception {
      throw const AuthFailure('Не вдалося надіслати лист для скидання пароля. Спробуйте ще раз.');
    }
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

  String _messageForSignUpError(FirebaseAuthException error) {
    return switch (error.code) {
      'email-already-in-use' => 'Обліковий запис з таким email вже існує.',
      'invalid-email' => 'Некоректний формат email.',
      'weak-password' => 'Пароль занадто простий. Використайте мінімум 6 символів.',
      'operation-not-allowed' => 'Реєстрація через email вимкнена.',
      _ => 'Не вдалося зареєструватися. Спробуйте ще раз.',
    };
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

  String _messageForPasswordResetError(FirebaseAuthException error) {
    return switch (error.code) {
      'user-not-found' => 'Користувача з таким email не знайдено.',
      'invalid-email' => 'Некоректний формат email.',
      'user-disabled' => 'Обліковий запис заблоковано.',
      'operation-not-allowed' => 'Скидання пароля вимкнено.',
      'too-many-requests' => 'Забагато запитів. Спробуйте пізніше.',
      _ => 'Не вдалося надіслати лист для скидання пароля. Спробуйте ще раз.',
    };
  }
}
