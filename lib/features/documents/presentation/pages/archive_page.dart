import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../data/documents_repository.dart';
import '../../domain/document_models.dart';
import '../pages/documents_page.dart';

class ArchivePage extends StatefulWidget {
  const ArchivePage({super.key, required this.repository});

  final DocumentsRepository repository;

  @override
  State<ArchivePage> createState() => _ArchivePageState();
}

class _ArchivePageState extends State<ArchivePage> {
  late Future<List<DocumentListItem>> _archiveFuture;

  @override
  void initState() {
    super.initState();
    _archiveFuture = _loadArchivedDocuments();
  }

  Future<List<DocumentListItem>> _loadArchivedDocuments() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) return const <DocumentListItem>[];

    final email = firebaseUser.email ?? '';
    final profile = await widget.repository.fetchCurrentUser(email);
    final documents = await widget.repository.fetchDocuments(archived: true);

    return documents
      .where((document) => document.authorId == profile.id)
        .toList(growable: false);
  }

  Future<void> _refresh() async {
    setState(() => _archiveFuture = _loadArchivedDocuments());
    await _archiveFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Архів')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<DocumentListItem>>(
          future: _archiveFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return _ArchiveErrorState(onRetry: _refresh);
            }

            final documents = snapshot.data ?? const <DocumentListItem>[];
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
                    repository: widget.repository,
                    onChanged: _refresh,
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
                  'Архів порожній',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Архівовані документи з’являться тут',
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
                  label: const Text('Спробувати ще раз'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
