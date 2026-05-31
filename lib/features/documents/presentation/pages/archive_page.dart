import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:karl_mobile/generated/app_localizations.dart';

import '../../data/documents_repository.dart';
import '../../domain/document_models.dart';
import '../pages/documents_page.dart';
import '../../providers/document_actions_provider.dart';

class ArchiveNotifier extends AsyncNotifier<List<DocumentListItem>> {
  late DocumentsRepository _repository;

  @override
  Future<List<DocumentListItem>> build() async {
    _repository = ref.read(documentsRepositoryProvider);
    return _loadArchivedDocuments();
  }

  Future<List<DocumentListItem>> _loadArchivedDocuments() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) return const <DocumentListItem>[];

    final email = firebaseUser.email ?? '';
    final profile = await _repository.fetchCurrentUser(email);
    final documents = await _repository.fetchDocuments(archived: true);

    return documents
        .where((document) => document.authorId == profile.id)
        .toList(growable: false);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _loadArchivedDocuments());
  }
}

final archiveProvider = AsyncNotifierProvider<ArchiveNotifier, List<DocumentListItem>>(ArchiveNotifier.new);


class ArchivePage extends ConsumerWidget {
  const ArchivePage({super.key, required this.repository});

  final DocumentsRepository repository;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Override the repository provider for this page
    return ProviderScope(
      overrides: [
        documentsRepositoryProvider.overrideWithValue(repository),
      ],
      child: const _ArchivePageContent(),
    );
  }
}

class _ArchivePageContent extends ConsumerWidget {
  const _ArchivePageContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final archiveAsync = ref.watch(archiveProvider);
    
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)?.archive ?? 'Archive')),
      body: RefreshIndicator(
        onRefresh: () => ref.read(archiveProvider.notifier).refresh(),
        child: archiveAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => _ArchiveErrorState(
            onRetry: () => ref.read(archiveProvider.notifier).refresh(),
          ),
          data: (documents) {
            if (documents.isEmpty) {
              return const _ArchiveEmptyState();
            }

            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: documents.length,
              itemBuilder: (context, index) {
                final document = documents[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SimpleDocumentCard(
                    document: document,
                    repository: ref.read(documentsRepositoryProvider),
                    onChanged: () => ref.read(archiveProvider.notifier).refresh(),
                    allowPermanentDelete: true,
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _ArchiveEmptyState extends StatelessWidget {
  const _ArchiveEmptyState();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 80),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.archive_outlined,
                  size: 72,
                  color: colorScheme.outline,
                ),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)?.archiveEmptyTitle ?? 'Archive is empty',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context)?.archiveEmptySubtitle ?? 'Archived documents will appear here',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ArchiveErrorState extends StatelessWidget {
  const _ArchiveErrorState({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 80),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 72,
                  color: colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Не вдалося завантажити архів',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_outlined),
                  label: Text(AppLocalizations.of(context)?.tryAgain ?? 'Try again'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
