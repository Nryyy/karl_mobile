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
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: [
                  Text('Не вдалося завантажити архів.'),
                ],
              );
            }

            final documents = snapshot.data ?? const <DocumentListItem>[];
            if (documents.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: const [Center(child: Text('Архів порожній'))],
              );
            }

            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
              itemCount: documents.length,
              itemBuilder: (context, index) {
                final document = documents[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
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
