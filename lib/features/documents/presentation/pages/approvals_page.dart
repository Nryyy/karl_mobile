import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/documents_repository.dart';
import '../../domain/document_models.dart';
import '../widgets/google_drive_preview.dart';

/// Screen that shows documents sent to the current user for approval.
class ApprovalsPage extends StatefulWidget {
  /// Creates the approvals page.
  const ApprovalsPage({super.key, required this.repository});

  /// Repository used to load and act on documents.
  final DocumentsRepository repository;

  @override
  State<ApprovalsPage> createState() => _ApprovalsPageState();
}

class _ApprovalsPageState extends State<ApprovalsPage> {
  Future<List<DocumentListItem>>? _future;
  String? _backendUserId;
  String? _userEmail;
  String? _userName;

  @override
  void initState() {
    super.initState();
    _future = _loadData();
  }

  Future<List<DocumentListItem>> _loadData() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) return const <DocumentListItem>[];

    final email = firebaseUser.email ?? '';
    _userEmail = email;
    _userName =
        firebaseUser.displayName?.trim().isNotEmpty == true
            ? firebaseUser.displayName!
            : email.split('@').first;

    final profile = await widget.repository.fetchCurrentUser(email);
    _backendUserId = profile.id;
    return _fetchFiltered(profile.id);
  }

  Future<List<DocumentListItem>> _fetchFiltered(String userId) async {
    final docs = await widget.repository.fetchDocuments(archived: false);
    return docs.where(_isPendingForMe).toList(growable: false);
  }

  /// Returns true when the approval flow is active and there is a pending
  /// step assigned to this user that is the current active step.
  bool _isPendingForMe(DocumentListItem doc) {
    final flow = doc.approvalFlow;
    if (!flow.isActive) return false;
    if (flow.steps.isEmpty) return false;

    final myId = _backendUserId ?? '';
    if (myId.isEmpty) return false;

    // Find the step assigned to the current user.
    final myStep = flow.steps.where((s) => s.approverId == myId).firstOrNull;
    if (myStep == null) return false;

    // Step must be pending (not yet acted on).
    final statusId = myStep.status.id.toLowerCase();
    final statusName = myStep.status.name.toLowerCase();
    final isPending =
        statusId == 'pending' ||
        statusName.contains('pending') ||
        statusName.contains('очіку');
    if (!isPending) return false;

    // It must be the current active step.
    // currentStep from the API is 1-based stepOrder, so compare directly.
    return myStep.stepOrder == flow.currentStep ||
        myStep.stepOrder == flow.currentStep + 1;
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _backendUserId != null
          ? _fetchFiltered(_backendUserId!)
          : _loadData();
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Погодження'),
        actions: [
          IconButton(
            onPressed: _refresh,
            tooltip: 'Оновити',
            icon: const Icon(Icons.refresh_outlined),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<DocumentListItem>>(
          future: _future,
          builder: (context, snapshot) {
            if (_future == null ||
                (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData)) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              final message =
                  snapshot.error is DocumentsRepositoryException
                      ? snapshot.error.toString()
                      : 'Не вдалося завантажити документи.';
              return _ApprovalsErrorState(
                message: message,
                onRetry: _refresh,
              );
            }

            final docs = snapshot.data ?? const <DocumentListItem>[];

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
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                return _ApprovalCard(
                  document: docs[index],
                  onTap: () => _openDetail(docs[index]),
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _openDetail(DocumentListItem document) {
    GoRouter.of(context).go(
      '/approvals/${document.id}',
      extra: _ApprovalDetailArgs(
        document: document,
        repository: widget.repository,
        userName: _userName ?? '',
        userEmail: _userEmail ?? '',
        onActionDone: _refresh,
      ),
    );
  }
}

/// Arguments passed to the approval detail route.
class ApprovalDetailArgs {
  /// Creates approval detail arguments.
  const ApprovalDetailArgs({
    required this.document,
    required this.repository,
    required this.userName,
    required this.userEmail,
    required this.onActionDone,
  });

  /// The document to approve or reject.
  final DocumentListItem document;

  /// Repository used for sign/reject calls.
  final DocumentsRepository repository;

  /// Current user display name.
  final String userName;

  /// Current user email.
  final String userEmail;

  /// Callback invoked after a successful sign or reject.
  final Future<void> Function() onActionDone;
}

typedef _ApprovalDetailArgs = ApprovalDetailArgs;

/// Detail view for a document pending approval.
class ApprovalDetailPage extends StatefulWidget {
  /// Creates the approval detail page.
  const ApprovalDetailPage({super.key, required this.args});

  /// Arguments for this page.
  final ApprovalDetailArgs? args;

  @override
  State<ApprovalDetailPage> createState() => _ApprovalDetailPageState();
}

class _ApprovalDetailPageState extends State<ApprovalDetailPage> {
  bool _isSigning = false;
  bool _isRejecting = false;
  bool _isDialogOpen = false;

  DocumentListItem? get _document => widget.args?.document;

  Future<void> _handleSign() async {
    final args = widget.args;
    if (args == null) return;

    setState(() => _isDialogOpen = true);
    final confirmed = await _showSignDialog(context);
    setState(() => _isDialogOpen = false);
    if (confirmed != true || !mounted) return;

    setState(() => _isSigning = true);
    try {
      await args.repository.signDocument(
        documentId: args.document.id,
        userName: args.userName,
        userEmail: args.userEmail,
      );
      if (!mounted) return;
      _showMessage('Документ підписано успішно.');
      await args.onActionDone();
      if (mounted) context.pop();
    } on DocumentsRepositoryException catch (e) {
      if (!mounted) return;
      _showMessage(e.message);
    } catch (_) {
      if (!mounted) return;
      _showMessage('Не вдалося підписати документ.');
    } finally {
      if (mounted) setState(() => _isSigning = false);
    }
  }

  Future<void> _handleReject() async {
    final args = widget.args;
    if (args == null) return;

    setState(() => _isDialogOpen = true);
    final comment = await _showRejectDialog(context);
    setState(() => _isDialogOpen = false);
    if (comment == null || !mounted) return;

    setState(() => _isRejecting = true);
    try {
      await args.repository.rejectDocument(
        documentId: args.document.id,
        userName: args.userName,
        userEmail: args.userEmail,
        comment: comment.isEmpty ? null : comment,
      );
      if (!mounted) return;
      _showMessage('Документ відхилено.');
      await args.onActionDone();
      if (mounted) context.pop();
    } on DocumentsRepositoryException catch (e) {
      if (!mounted) return;
      _showMessage(e.message);
    } catch (_) {
      if (!mounted) return;
      _showMessage('Не вдалося відхилити документ.');
    } finally {
      if (mounted) setState(() => _isRejecting = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    if (_document == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Погодження')),
        body: const Center(child: Text('Документ не знайдено.')),
      );
    }

    final doc = _document!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(doc.title.isEmpty ? 'Документ' : doc.title),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _DocumentInfoCard(document: doc),
          const SizedBox(height: 16),
          _ApprovalFlowCard(document: doc),
          if (doc.webViewLink.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Перегляд документа',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 500,
                child: _isDialogOpen
                    ? const SizedBox.shrink()
                    : GoogleDrivePreview(webViewLink: doc.webViewLink),
              ),
            ),
          ],
          const SizedBox(height: 24),
          _SignActionBar(
            isSigning: _isSigning,
            isRejecting: _isRejecting,
            onSign: _handleSign,
            onReject: _handleReject,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

Future<bool?> _showSignDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Підписати документ'),
      content: const Text(
        'Ви підтверджуєте погодження цього документа? '
        'Дію скасувати неможливо.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Скасувати'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Підписати'),
        ),
      ],
    ),
  );
}

Future<String?> _showRejectDialog(BuildContext context) async {
  final controller = TextEditingController();
  final result = await showDialog<String>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Відхилити документ'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Вкажіть причину відхилення (необов\'язково):'),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Причина відхилення...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('Скасувати'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Відхилити'),
          ),
        ],
      );
    },
  );
  controller.dispose();
  return result;
}

class _ApprovalCard extends StatelessWidget {
  const _ApprovalCard({
    required this.document,
    required this.onTap,
  });

  final DocumentListItem document;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final flow = document.approvalFlow;
    final currentStep =
        flow.steps.isNotEmpty && flow.currentStep < flow.steps.length
            ? flow.steps[flow.currentStep]
            : null;
    final createdAt = _formatDate(document.createdAt).split(' ').first;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          document.title.isEmpty
                              ? 'Без назви'
                              : document.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'від ${document.authorName.isEmpty ? "невідомого" : document.authorName}',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  _PendingBadge(),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _MetaPill(
                    icon: Icons.description_outlined,
                    label: document.fileType.isEmpty
                        ? 'файл'
                        : document.fileType,
                  ),
                  _MetaPill(icon: Icons.event_outlined, label: createdAt),
                  if (currentStep != null)
                    _MetaPill(
                      icon: Icons.pending_actions_outlined,
                      label:
                          'Крок ${(flow.currentStep + 1)} з ${flow.steps.length}',
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PendingBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'Очікує',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppColors.warning,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelSmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _DocumentInfoCard extends StatelessWidget {
  const _DocumentInfoCard({required this.document});

  final DocumentListItem document;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 12,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            document.title.isEmpty ? 'Без назви' : document.title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          _InfoRow(
            icon: Icons.person_outline,
            label: 'Автор',
            value: document.authorName.isEmpty
                ? 'Невідомий'
                : document.authorName,
          ),
          const SizedBox(height: 6),
          _InfoRow(
            icon: Icons.description_outlined,
            label: 'Тип',
            value: document.fileType.isEmpty ? '—' : document.fileType,
          ),
          const SizedBox(height: 6),
          _InfoRow(
            icon: Icons.calendar_today_outlined,
            label: 'Створено',
            value: _formatDate(document.createdAt),
          ),
          const SizedBox(height: 6),
          _InfoRow(
            icon: Icons.flag_outlined,
            label: 'Статус',
            value: document.status.name.isEmpty ? '—' : document.status.name,
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textPrimary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _ApprovalFlowCard extends StatelessWidget {
  const _ApprovalFlowCard({required this.document});

  final DocumentListItem document;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final flow = document.approvalFlow;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 12,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.route_rounded,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Маршрут погодження',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (flow.steps.isEmpty)
            Text(
              'Кроки відсутні.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            )
          else
            ...flow.steps.asMap().entries.map((entry) {
              final index = entry.key;
              final step = entry.value;
              final isCurrent = index == flow.currentStep;
              return _ApprovalStepTile(
                step: step,
                isCurrent: isCurrent,
                isLast: index == flow.steps.length - 1,
              );
            }),
        ],
      ),
    );
  }
}

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
    final statusName = step.status.name.toLowerCase();
    final isApproved =
        statusName.contains('approve') ||
        statusName.contains('sign') ||
        statusName.contains('затвер');
    final isRejected =
        statusName.contains('reject') || statusName.contains('відхил');

    final Color dotColor;
    final IconData dotIcon;
    if (isApproved) {
      dotColor = AppColors.success;
      dotIcon = Icons.check_circle_rounded;
    } else if (isRejected) {
      dotColor = AppColors.error;
      dotIcon = Icons.cancel_rounded;
    } else if (isCurrent) {
      dotColor = AppColors.warning;
      dotIcon = Icons.pending_rounded;
    } else {
      dotColor = AppColors.disabled;
      dotIcon = Icons.radio_button_unchecked;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Icon(dotIcon, size: 20, color: dotColor),
            if (!isLast)
              Container(
                width: 2,
                height: 28,
                color: AppColors.border,
              ),
          ],
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.approverName.isEmpty ? step.approverEmail : step.approverName,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: isCurrent ? FontWeight.w700 : FontWeight.normal,
                    color: isCurrent
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                ),
                Text(
                  'Крок ${step.stepOrder}  •  ${step.status.name}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: dotColor,
                  ),
                ),
                if (step.comment.isNotEmpty)
                  Text(
                    step.comment,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SignActionBar extends StatelessWidget {
  const _SignActionBar({
    required this.isSigning,
    required this.isRejecting,
    required this.onSign,
    required this.onReject,
  });

  final bool isSigning;
  final bool isRejecting;
  final Future<void> Function() onSign;
  final Future<void> Function() onReject;

  @override
  Widget build(BuildContext context) {
    final busy = isSigning || isRejecting;

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 52,
            child: OutlinedButton.icon(
              onPressed: busy ? null : () => onReject(),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: BorderSide(
                  color: busy ? AppColors.disabled : AppColors.error,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: isRejecting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.error,
                      ),
                    )
                  : const Icon(Icons.close_rounded, size: 18),
              label: const Text(
                'Відхилити',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SizedBox(
            height: 52,
            child: FilledButton.icon(
              onPressed: busy ? null : () => onSign(),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.success,
                disabledBackgroundColor: AppColors.disabled,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: isSigning
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check_rounded, size: 18),
              label: const Text(
                'Підписати',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ApprovalsEmptyState extends StatelessWidget {
  const _ApprovalsEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.task_alt_outlined,
              size: 72,
              color: AppColors.disabled,
            ),
            const SizedBox(height: 16),
            Text(
              'Немає документів для погодження',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Коли вам надішлють документ на підпис, він з\'явиться тут.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ApprovalsErrorState extends StatelessWidget {
  const _ApprovalsErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 72,
                color: AppColors.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Не вдалося завантажити',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium,
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
      ],
    );
  }
}

String _formatDate(DateTime? dateTime) {
  if (dateTime == null) return 'Не вказано';
  final local = dateTime.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final year = local.year;
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$day.$month.$year $hour:$minute';
}
