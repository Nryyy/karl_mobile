import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/document_models.dart';
import '../../providers/document_actions_provider.dart';

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
    final signingAsync = ref.watch(documentSigningProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(document.title),
      ),
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
                    onPressed: signingAsync.isLoading ? null : () async {
                      try {
                        await ref.read(documentSigningProvider.notifier).signDocument(
                          documentId: document.id,
                          userName: currentUser.fullName,
                          userEmail: currentUser.email,
                        );
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Документ підписано')),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Помилка: $e')),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.check),
                    label: const Text('Підписати'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: signingAsync.isLoading ? null : () async {
                      final result = await showDialog<String>(
                        context: context,
                        builder: (context) => const RejectDialog(),
                      );
                      
                      if (result != null) {
                        try {
                          await ref.read(documentSigningProvider.notifier).rejectDocument(
                            documentId: document.id,
                            userName: currentUser.fullName,
                            userEmail: currentUser.email,
                            comment: result,
                          );
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Документ відхилено')),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Помилка: $e')),
                            );
                          }
                        }
                      }
                    },
                    icon: const Icon(Icons.close),
                    label: const Text('Відхилити'),
                  ),
                ),
              ],
            ),
            if (signingAsync.isLoading) ...[
              const SizedBox(height: 16),
              const LinearProgressIndicator(),
            ],
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
      title: const Text('Відхилити документ'),
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
          child: const Text('Скасувати'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, controller.text),
          child: const Text('Відхилити'),
        ),
      ],
    );
  }
}
