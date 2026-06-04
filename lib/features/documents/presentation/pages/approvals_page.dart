import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:karl_mobile/generated/app_localizations.dart';

import '../../data/documents_repository.dart';
import '../../domain/document_models.dart';
import '../../providers/documents_provider.dart';
import '../../providers/document_actions_provider.dart';
import '../widgets/google_drive_preview.dart';

/// Screen that shows documents sent to the current user for approval.
class ApprovalsPage extends ConsumerWidget {
  /// Creates the approvals page.
  const ApprovalsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sentToMeAsync = ref.watch(sentToMeDocumentsProvider);
    final user = FirebaseAuth.instance.currentUser;
    final userEmail = user?.email ?? '';
    final userName = user?.displayName?.trim().isNotEmpty == true
        ? user!.displayName!
        : userEmail.split('@').first;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)?.approvals ?? 'Approvals'),
        actions: [
          IconButton(
            onPressed: () =>
                ref.read(sentToMeDocumentsProvider.notifier).refresh(),
            tooltip: AppLocalizations.of(context)?.refresh ?? 'Refresh',
            icon: const Icon(Icons.refresh_outlined),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(sentToMeDocumentsProvider.notifier).refresh(),
        child: sentToMeAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, st) {
            final message = err is DocumentsRepositoryException
                ? err.toString()
                : (AppLocalizations.of(context)?.unknownError ??
                      'Unknown error. Check logs.');
            return _ApprovalsErrorState(
              message: message,
              onRetry: () =>
                  ref.read(sentToMeDocumentsProvider.notifier).refresh(),
            );
          },
          data: (docs) {
            if (docs.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [_ApprovalsEmptyState()],
              );
            }

            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
              itemCount: docs.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                return _ApprovalCard(
                  document: docs[index],
                  onTap: () =>
                      _openDetail(context, docs[index], userName, userEmail),
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _openDetail(
    BuildContext context,
    DocumentListItem document,
    String userName,
    String userEmail,
  ) {
    GoRouter.of(context).go(
      '/approvals/${document.id}',
      extra: ApprovalDetailArgs(
        document: document,
        userName: userName,
        userEmail: userEmail,
        onActionDone: () {},
      ),
    );
  }
}

/// Arguments passed to the approval detail route.
class ApprovalDetailArgs {
  /// Creates approval detail arguments.
  const ApprovalDetailArgs({
    required this.document,
    required this.userName,
    required this.userEmail,
    required this.onActionDone,
  });

  /// Document to display.
  final DocumentListItem document;

  /// Display name of the current user.
  final String userName;

  /// Email of the current user.
  final String userEmail;

  /// Callback when sign/reject action completes.
  final VoidCallback onActionDone;
}

/// Card widget displaying a document pending approval.
class _ApprovalCard extends StatelessWidget {
  const _ApprovalCard({required this.document, required this.onTap});

  final DocumentListItem document;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      document.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _StatusChip(status: document.status),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                document.authorName,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatDate(document.createdAt),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
}

/// Status chip showing document status.
class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final DocumentStatus status;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isPending =
        status.name.toLowerCase().contains('pending') ||
        status.name.toLowerCase().contains('очіку');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isPending
            ? Colors.orange.withValues(alpha: 0.1)
            : colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.name,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: isPending ? Colors.orange : colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }
}

/// Empty state when no documents for approval.
class _ApprovalsEmptyState extends StatelessWidget {
  const _ApprovalsEmptyState();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)?.approvalsEmptyTitle ??
                'No documents for approval',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)?.approvalsEmptySubtitle ??
                'When someone sends you a document to sign, it will appear here.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Error state with retry option.
class _ApprovalsErrorState extends StatelessWidget {
  const _ApprovalsErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: colorScheme.error.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)?.unknownError ?? 'Failed to load',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: Text(AppLocalizations.of(context)?.tryAgain ?? 'Try again'),
          ),
        ],
      ),
    );
  }
}

/// Detail page for viewing and signing a document.
class ApprovalDetailPage extends ConsumerStatefulWidget {
  const ApprovalDetailPage({super.key, this.args});

  final ApprovalDetailArgs? args;

  @override
  ConsumerState<ApprovalDetailPage> createState() => _ApprovalDetailPageState();
}

class _ApprovalDetailPageState extends ConsumerState<ApprovalDetailPage> {
  bool _isProcessing = false;
  bool _actionDone = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final args = widget.args;
    final userName = args?.userName ?? '';
    final userEmail = args?.userEmail ?? '';
    final document = args?.document;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)?.approvals ?? 'Approvals'),
        actions: [
          if (_isProcessing)
            const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          const SizedBox(width: 16),
        ],
      ),
      body: document == null
          ? const Center(child: Text('Document not found'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Document info card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          document.title,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${AppLocalizations.of(context)?.authorPrefix ?? 'Author:'} ${document.authorName}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${AppLocalizations.of(context)?.statusPrefix ?? 'Status:'} ${document.status.name}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Approval flow
                Text(
                  AppLocalizations.of(context)?.chooseAction ?? 'Approval Flow',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                ...document.approvalFlow.steps.asMap().entries.map((entry) {
                  final index = entry.key;
                  final step = entry.value;
                  final isCurrent = index == document.approvalFlow.currentStep;
                  return _ApprovalStepTile(
                    step: step,
                    isCurrent: isCurrent,
                    isLast: index == document.approvalFlow.steps.length - 1,
                  );
                }),

                const SizedBox(height: 32),

                // Action buttons
                if (_isPendingForCurrentUser && !_actionDone)
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isProcessing
                              ? null
                              : () => _sign(userName, userEmail, document.id),
                          icon: const Icon(Icons.check_circle),
                          label: Text(
                            AppLocalizations.of(context)?.signDocument ??
                                'Sign',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isProcessing
                              ? null
                              : () => _reject(userName, userEmail, document.id),
                          icon: const Icon(Icons.cancel),
                          label: Text(
                            AppLocalizations.of(context)?.rejectDocument ??
                                'Reject',
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),

                // Google Drive preview
                if (document.webViewLink.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      height: 500,
                      child: GoogleDrivePreview(webViewLink: document.webViewLink),
                    ),
                  ),
                ],
              ],
            ),
    );
  }

  bool get _isPendingForCurrentUser {
    final document = widget.args?.document;
    if (document == null) return false;
    final flow = document.approvalFlow;
    if (!flow.isActive || flow.steps.isEmpty) return false;

    final userEmail = widget.args?.userEmail ?? '';
    if (userEmail.isEmpty) return false;

    final myStep = flow.steps
        .where((s) => s.approverEmail.toLowerCase() == userEmail.toLowerCase())
        .firstOrNull;
    if (myStep == null) return false;

    final statusId = myStep.status.id.toLowerCase();
    final statusName = myStep.status.name.toLowerCase();
    final isPending =
        statusId == 'pending' ||
        statusName.contains('pending') ||
        statusName.contains('очіку');
    if (!isPending) return false;

    return myStep.stepOrder == flow.currentStep ||
        myStep.stepOrder == flow.currentStep + 1;
  }

  Future<void> _sign(
    String userName,
    String userEmail,
    String documentId,
  ) async {
    setState(() => _isProcessing = true);
    try {
      await ref
          .read(documentSigningProvider.notifier)
          .signDocument(
            documentId: documentId,
            userName: userName,
            userEmail: userEmail,
          );
      if (!mounted) return;
      setState(() => _actionDone = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)?.documentSigned ??
                'Document signed successfully',
          ),
        ),
      );
      context.pop();
    } on DocumentsRepositoryException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)?.unknownError ??
                'Failed to sign document',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _reject(
    String userName,
    String userEmail,
    String documentId,
  ) async {
    final comment = await _showCommentDialog();
    if (comment == null) return;

    setState(() => _isProcessing = true);
    try {
      await ref
          .read(documentSigningProvider.notifier)
          .rejectDocument(
            documentId: documentId,
            userName: userName,
            userEmail: userEmail,
            comment: comment.isNotEmpty ? comment : null,
          );
      if (!mounted) return;
      setState(() => _actionDone = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)?.documentRejected ??
                'Document rejected',
          ),
        ),
      );
      context.pop();
    } on DocumentsRepositoryException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)?.unknownError ??
                'Failed to reject document',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<String?> _showCommentDialog() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          AppLocalizations.of(context)?.rejectDocument ?? 'Reject Document',
        ),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText:
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
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(
              AppLocalizations.of(context)?.rejectDocument ?? 'Reject',
            ),
          ),
        ],
      ),
    );
    return result;
  }
}

/// Widget showing a single approval step.
class _ApprovalStepTile extends StatelessWidget {
  const _ApprovalStepTile({
    required this.step,
    required this.isCurrent,
    required this.isLast,
  });

  final ApprovalStep step;
  final bool isCurrent;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isCompleted =
        !isCurrent && step.status.name.toLowerCase() != 'pending';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted
                    ? Colors.green
                    : isCurrent
                    ? colorScheme.primary
                    : colorScheme.surfaceContainerHighest,
              ),
              child: Icon(
                isCompleted ? Icons.check : Icons.person,
                size: 16,
                color: isCompleted || isCurrent
                    ? Colors.white
                    : colorScheme.onSurfaceVariant,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: isCompleted
                    ? Colors.green
                    : colorScheme.surfaceContainerHighest,
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                step.approverName,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: isCurrent ? FontWeight.w600 : null,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                step.status.name,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isCurrent
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                ),
              ),
              if (!isLast) const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }
}
