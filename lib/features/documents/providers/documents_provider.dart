import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/documents_repository.dart';
import '../domain/document_models.dart';
import '../domain/document_visibility.dart';

class DocumentsNotifier extends AsyncNotifier<List<DocumentListItem>> {
  @override
  Future<List<DocumentListItem>> build() async {
    return _load();
  }

  Future<List<DocumentListItem>> _load() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const <DocumentListItem>[];

    final repo = HttpDocumentsRepository(accessTokenProvider: () => user.getIdToken());
    try {
      final profile = await repo.fetchCurrentUser(user.email ?? '');
      final results = await Future.wait([
        repo.fetchDocuments(archived: false),
        repo.fetchDocumentsSentToMe(profile.id, archived: false),
      ]);

      final merged = mergeVisibleDocuments(
        currentUserId: profile.id,
        allDocuments: results[0],
        sentToMe: results[1],
      );

      final filtered = merged
          .where((d) {
            final name = d.status.name.toLowerCase();
            return !(name.contains('архів') || name.contains('archive') || name.contains('archived'));
          })
          .toList(growable: false);

      return filtered;
    } finally {
      repo.dispose();
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _load());
  }
}

final documentsProvider = AsyncNotifierProvider<DocumentsNotifier, List<DocumentListItem>>(DocumentsNotifier.new);
