import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/document_models.dart';
import '../domain/document_visibility.dart';
import 'document_actions_provider.dart';

class DocumentsNotifier extends AsyncNotifier<List<DocumentListItem>> {
  @override
  Future<List<DocumentListItem>> build() async {
    return _load();
  }

  Future<List<DocumentListItem>> _load() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const <DocumentListItem>[];

    final repository = ref.read(documentsRepositoryProvider);
    try {
      final profile = await repository.fetchCurrentUser(user.email ?? '');
      final results = await Future.wait([
        repository.fetchDocuments(archived: false),
        repository.fetchDocumentsSentToMe(profile.id, archived: false),
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
      // Repository is managed by the provider now
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _load());
  }
}

final documentsProvider = AsyncNotifierProvider<DocumentsNotifier, List<DocumentListItem>>(DocumentsNotifier.new);

// Separate provider for sent-to-me documents
class SentToMeDocumentsNotifier extends AsyncNotifier<List<DocumentListItem>> {
  @override
  Future<List<DocumentListItem>> build() async {
    return _loadSentToMeDocuments();
  }

  Future<List<DocumentListItem>> _loadSentToMeDocuments() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const <DocumentListItem>[];

    final repository = ref.read(documentsRepositoryProvider);
    final currentUser = await ref.read(currentUserProvider.future);
    
    final documents = await repository.fetchDocumentsSentToMe(currentUser.id, archived: false);
    
    return documents.where((doc) {
      return doc.approvalFlow.isActive && 
             doc.approvalFlow.steps.isNotEmpty &&
             doc.approvalFlow.currentStep < doc.approvalFlow.steps.length &&
             doc.approvalFlow.steps[doc.approvalFlow.currentStep].approverId == currentUser.id;
    }).toList(growable: false);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _loadSentToMeDocuments());
  }
}

final sentToMeDocumentsProvider = AsyncNotifierProvider<SentToMeDocumentsNotifier, List<DocumentListItem>>(SentToMeDocumentsNotifier.new);

// Separate provider for users list
class UsersNotifier extends AsyncNotifier<List<UserProfile>> {
  @override
  Future<List<UserProfile>> build() async {
    return _loadUsers();
  }

  Future<List<UserProfile>> _loadUsers() async {
    final repository = ref.read(documentsRepositoryProvider);
    return repository.fetchUsers();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _loadUsers());
  }
}

final usersProvider = AsyncNotifierProvider<UsersNotifier, List<UserProfile>>(UsersNotifier.new);
