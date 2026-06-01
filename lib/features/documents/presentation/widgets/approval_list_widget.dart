import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:karl_mobile/generated/app_localizations.dart';

import '../../domain/document_models.dart';

/// Simple approval list widget using ConsumerWidget
class ApprovalListWidget extends ConsumerWidget {
  const ApprovalListWidget({
    super.key,
    required this.documents,
    required this.currentUser,
    required this.onRefresh,
  });

  final List<DocumentListItem> documents;
  final UserProfile currentUser;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: documents.length,
        itemBuilder: (context, index) {
          final document = documents[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                child: Text(
                  document.title.isNotEmpty
                      ? document.title[0].toUpperCase()
                      : '?',
                ),
              ),
              title: Text(document.title),
              subtitle: Text(
                '${AppLocalizations.of(context)?.fromLabel ?? 'From'} ${document.authorName}',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // Navigate to approval detail
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ApprovalDetailWidget(
                      document: document,
                      currentUser: currentUser,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

/// Simple approval detail widget using ConsumerWidget
class ApprovalDetailWidget extends ConsumerWidget {
  const ApprovalDetailWidget({
    super.key,
    required this.document,
    required this.currentUser,
  });

  final DocumentListItem document;
  final UserProfile currentUser;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text(document.title)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Автор: ${document.authorName}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Статус: ${document.status.name}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            const Text(
              'Оберіть дію:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () async {
                      // Handle sign action
                      if (!context.mounted) return;
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            AppLocalizations.of(context)?.documentSigned ??
                                'Document signed',
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.check),
                    label: Text(
                      AppLocalizations.of(context)?.signDocument ?? 'Sign',
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final result = await showDialog<String>(
                        context: context,
                        builder: (context) => const RejectDialog(),
                      );

                      if (result != null && context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              AppLocalizations.of(context)?.documentRejected ??
                                  'Document rejected',
                            ),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.close),
                    label: Text(
                      AppLocalizations.of(context)?.rejectDocument ?? 'Reject',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Simple reject dialog using ConsumerWidget
class RejectDialog extends ConsumerWidget {
  const RejectDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();

    return AlertDialog(
      title: Text(
        AppLocalizations.of(context)?.rejectDocumentTitle ?? 'Reject document',
      ),
      content: TextField(
        controller: controller,
        decoration: const InputDecoration(
          labelText: 'Коментар (необов\'язково)',
          border: OutlineInputBorder(),
        ),
        maxLines: 3,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppLocalizations.of(context)?.cancel ?? 'Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, controller.text),
          child: Text(AppLocalizations.of(context)?.rejectDocument ?? 'Reject'),
        ),
      ],
    );
  }
}
