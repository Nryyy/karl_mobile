import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:karl_mobile/generated/app_localizations.dart';

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
      appBar: AppBar(title: Text(document.title)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${AppLocalizations.of(context)?.authorPrefix ?? 'Author:'} ${document.authorName}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '${AppLocalizations.of(context)?.statusPrefix ?? 'Status:'} ${document.status.name}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)?.chooseAction ?? 'Choose an action:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: signingAsync.isLoading
                        ? null
                        : () async {
                            try {
                              await ref
                                  .read(documentSigningProvider.notifier)
                                  .signDocument(
                                    documentId: document.id,
                                    userName: currentUser.fullName,
                                    userEmail: currentUser.email,
                                  );
                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      AppLocalizations.of(
                                            context,
                                          )?.documentSigned ??
                                          'Document signed',
                                    ),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '${AppLocalizations.of(context)?.unknownError ?? 'Error'}: $e',
                                    ),
                                  ),
                                );
                              }
                            }
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
                    onPressed: signingAsync.isLoading
                        ? null
                        : () async {
                            final result = await showDialog<String>(
                              context: context,
                              builder: (context) => const RejectDialog(),
                            );

                            if (result != null) {
                              try {
                                await ref
                                    .read(documentSigningProvider.notifier)
                                    .rejectDocument(
                                      documentId: document.id,
                                      userName: currentUser.fullName,
                                      userEmail: currentUser.email,
                                      comment: result,
                                    );
                                if (context.mounted) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        AppLocalizations.of(
                                              context,
                                            )?.documentRejected ??
                                            'Document rejected',
                                      ),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        '${AppLocalizations.of(context)?.unknownError ?? 'Error'}: $e',
                                      ),
                                    ),
                                  );
                                }
                              }
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
      title: Text(
        AppLocalizations.of(context)?.rejectDocumentTitle ?? 'Reject document',
      ),
      content: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText:
              AppLocalizations.of(context)?.commentLabel ??
              'Comment (optional)',
          border: const OutlineInputBorder(),
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
