import 'dart:developer' as developer;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/firebase_auth_service.dart';
import '../domain/auth_failure.dart';
import '../domain/auth_service.dart';

// Provider for AuthService
final authServiceProvider = Provider<AuthService>((ref) {
  return FirebaseAuthService();
});

// Provider for login state management
class LoginNotifier extends StateNotifier<AsyncValue<void>> {
  final AuthService _authService;

  LoginNotifier(this._authService) : super(const AsyncValue.data(null));

  Future<void> signInWithEmailAndPassword(String email, String password) async {
    state = const AsyncValue.loading();
    
    try {
      await _authService.signInWithEmailAndPassword(email: email, password: password);
      state = const AsyncValue.data(null);
      developer.log('Email sign-in successful', name: 'karl.auth');
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      developer.log('Email sign-in failed: $e', name: 'karl.auth', error: e, stackTrace: stack);
    }
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();
    
    try {
      await _authService.signInWithGoogle();
      state = const AsyncValue.data(null);
      developer.log('Google sign-in successful', name: 'karl.auth');
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      developer.log('Google sign-in failed: $e', name: 'karl.auth', error: e, stackTrace: stack);
    }
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    
    try {
      await _authService.signOut();
      state = const AsyncValue.data(null);
      developer.log('Sign out successful', name: 'karl.auth');
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      developer.log('Sign out failed: $e', name: 'karl.auth', error: e, stackTrace: stack);
    }
  }
}

final loginProvider = StateNotifierProvider<LoginNotifier, AsyncValue<void>>((ref) {
  final authService = ref.watch(authServiceProvider);
  return LoginNotifier(authService);
});

// Provider for loading state
final isLoadingProvider = Provider<bool>((ref) {
  return ref.watch(loginProvider).maybeWhen(
    loading: () => true,
    orElse: () => false,
  );
});

// Provider for auth errors
final authErrorProvider = Provider<AuthFailure?>((ref) {
  return ref.watch(loginProvider).maybeWhen(
    error: (error, stack) {
      if (error is AuthFailure) return error;
      return AuthFailure.unknown(error.toString());
    },
    orElse: () => null,
  );
});
