import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../documents/domain/document_models.dart';
import '../../documents/data/documents_repository.dart';

class AuthNotifier extends StateNotifier<UserProfile?> {
  AuthNotifier() : super(null) {
    _init();
  }

  Future<void> _init() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final repo = HttpDocumentsRepository(
      accessTokenProvider: () => user.getIdToken(),
    );
    try {
      final profile = await repo.fetchCurrentUser(user.email ?? '');
      state = profile;
    } catch (_) {
      state = null;
    } finally {
      repo.dispose();
    }
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    state = null;
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, UserProfile?>(
  (ref) => AuthNotifier(),
);
