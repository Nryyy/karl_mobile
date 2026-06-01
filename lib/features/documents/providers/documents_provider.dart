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
            return !(name.contains('архів') ||
                name.contains('archive') ||
                name.contains('archived'));
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

final documentsProvider =
    AsyncNotifierProvider<DocumentsNotifier, List<DocumentListItem>>(
      DocumentsNotifier.new,
    );

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

    final documents = await repository.fetchDocumentsSentToMe(
      currentUser.id,
      archived: false,
    );

    // Filter documents where current user has a pending approval step
    return documents
        .where((doc) => _isPendingForUser(doc, currentUser.id))
        .toList(growable: false);
  }

  /// Returns true when the approval flow is active and there is a pending
  /// step assigned to this user that is the current active step.
  bool _isPendingForUser(DocumentListItem doc, String userId) {
    final flow = doc.approvalFlow;
    if (!flow.isActive) return false;
    if (flow.steps.isEmpty) return false;
    if (userId.isEmpty) return false;

    // Find the step assigned to the current user
    final myStep = flow.steps.where((s) => s.approverId == userId).firstOrNull;
    if (myStep == null) return false;

    // Step must be pending (not yet acted on)
    final statusId = myStep.status.id.toLowerCase();
    final statusName = myStep.status.name.toLowerCase();
    final isPending =
        statusId == 'pending' ||
        statusName.contains('pending') ||
        statusName.contains('очіку');
    if (!isPending) return false;

    // It must be the current active step
    // currentStep from the API is 1-based stepOrder, so compare directly
    return myStep.stepOrder == flow.currentStep ||
        myStep.stepOrder == flow.currentStep + 1;
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _loadSentToMeDocuments());
  }
}

final sentToMeDocumentsProvider =
    AsyncNotifierProvider<SentToMeDocumentsNotifier, List<DocumentListItem>>(
      SentToMeDocumentsNotifier.new,
    );

// Separate provider for users list
class UsersNotifier extends AsyncNotifier<List<UserProfile>> {
  String? _organizationId;

  @override
  Future<List<UserProfile>> build() async {
    return _loadUsers();
  }

  Future<List<UserProfile>> _loadUsers() async {
    final repository = ref.read(documentsRepositoryProvider);
    return repository.fetchUsers(organizationId: _organizationId);
  }

  Future<void> refresh({String? organizationId}) async {
    _organizationId = organizationId;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _loadUsers());
  }
}

final usersProvider = AsyncNotifierProvider<UsersNotifier, List<UserProfile>>(
  UsersNotifier.new,
);
