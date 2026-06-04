import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:karl_mobile/generated/app_localizations.dart';

import '../../domain/document_models.dart';
import '../../data/documents_repository.dart';
import '../../providers/document_actions_provider.dart';

class SimpleDocumentCard extends ConsumerStatefulWidget {
  const SimpleDocumentCard({super.key, 
    required this.document,
    this.onChanged,
    this.allowPermanentDelete = false,
  });

  final DocumentListItem document;
  final VoidCallback? onChanged;
  final bool allowPermanentDelete;

  @override
  ConsumerState<SimpleDocumentCard> createState() => _SimpleDocumentCardState();
}

class _SimpleDocumentCardState extends ConsumerState<SimpleDocumentCard> {
  bool _isProcessing = false;

  bool get _isArchived {
    if (widget.allowPermanentDelete) {
      return true;
    }

    final name = widget.document.status.name.toLowerCase();
    return name.contains('архів') ||
        name.contains('archive') ||
        name.contains('archived');
  }

  void _refreshParent() {
    widget.onChanged?.call();
  }

  Future<void> _archive() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          AppLocalizations.of(context)?.archiveDocumentTitle ??
              'Archive document?',
        ),
        content: Text(
          AppLocalizations.of(context)?.archiveDocumentContent ??
              'The document will be moved to the archive.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              AppLocalizations.of(context)?.archiveCancel ?? 'Cancel',
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              AppLocalizations.of(context)?.archiveConfirm ?? 'Archive',
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isProcessing = true);
    try {
      await ref
          .read(documentActionsProvider.notifier)
          .archiveDocument(widget.document.id);
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)?.archiveDone ?? 'Document archived.',
            ),
            action: SnackBarAction(
              label: AppLocalizations.of(context)?.undoLabel ?? 'Undo',
              onPressed: () async {
                try {
                  await ref
                      .read(documentActionsProvider.notifier)
                      .restoreDocument(widget.document.id);
                  if (!mounted) return;
                  _refreshParent();
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        AppLocalizations.of(context)?.archiveCancelled ??
                            'Archive cancelled.',
                      ),
                    ),
                  );
                } on DocumentsRepositoryException catch (e) {
                  if (!mounted) return;
                  messenger.showSnackBar(SnackBar(content: Text(e.message)));
                } catch (_) {
                  if (!mounted) return;
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        AppLocalizations.of(context)?.restoreFailed ??
                            'Failed to restore document.',
                      ),
                    ),
                  );
                }
              },
            ),
          ),
        );
      _refreshParent();
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
            AppLocalizations.of(context)?.archiveFailed ??
                'Failed to archive document.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _delete() async {
    if (!_isArchived) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)?.deleteOnlyFromArchive ??
                'Deletion allowed only from the archive.',
          ),
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          AppLocalizations.of(context)?.deleteDocumentTitle ??
              'Delete document?',
        ),
        content: Text(
          AppLocalizations.of(context)?.deleteDocumentContent ??
              'This action cannot be undone. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppLocalizations.of(context)?.cancel ?? 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              AppLocalizations.of(context)?.deleteConfirm ?? 'Delete',
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isProcessing = true);
    try {
      await ref
          .read(documentActionsProvider.notifier)
          .deleteDocument(widget.document.id, permanent: true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)?.deleteDone ?? 'Document deleted.',
          ),
        ),
      );
      widget.onChanged?.call();
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
            AppLocalizations.of(context)?.deleteFailed ??
                'Failed to delete document.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final document = widget.document;
    final color = statusColor(document.status.name, context);
    final createdAt = formatDate(document.createdAt).split(' ').first;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => GoRouter.of(
          context,
        ).go('/documents/${document.id}', extra: document),
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
                        Hero(
                          tag: 'document-title-${document.id}',
                          child: Material(
                            type: MaterialType.transparency,
                            child: Text(
                              document.title.isEmpty
                                  ? (AppLocalizations.of(context)?.untitled ??
                                        'Untitled')
                                  : document.title,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          document.authorName.isEmpty
                              ? (AppLocalizations.of(context)?.unknownAuthor ??
                                    'Unknown author')
                              : document.authorName,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  _StatusBadge(
                    label: document.status.name.isEmpty
                        ? (AppLocalizations.of(context)?.notSpecified ??
                              'Not specified')
                        : document.status.name,
                    color: color,
                  ),
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    enabled: !_isProcessing,
                    onSelected: (v) async {
                      if (v == 'archive') await _archive();
                      if (v == 'delete') await _delete();
                    },
                    itemBuilder: (context) => <PopupMenuEntry<String>>[
                      if (!_isArchived)
                        PopupMenuItem<String>(
                          value: 'archive',
                          child: Text(
                            AppLocalizations.of(context)?.archive ?? 'Archive',
                          ),
                        ),
                      if (_isArchived)
                        PopupMenuItem<String>(
                          value: 'delete',
                          child: Text(
                            AppLocalizations.of(context)?.deleteConfirm ??
                                'Delete',
                          ),
                        ),
                    ],
                    icon: const Icon(Icons.more_vert),
                  ),
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
                        ? 'file'
                        : document.fileType,
                  ),
                  _MetaPill(icon: Icons.event_outlined, label: createdAt),
                  if (document.metadata.category.isNotEmpty)
                    _MetaPill(
                      icon: Icons.folder_outlined,
                      label: document.metadata.category,
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

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
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
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: colorScheme.primary),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

String formatFileSize(int bytes) {
  if (bytes < 1024) return '$bytes Б';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} КБ';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} МБ';
}

String formatDate(DateTime? dateTime) {
  if (dateTime == null) {
    return 'Не вказано';
  }

  final local = dateTime.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final year = local.year;
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$day.$month.$year $hour:$minute';
}

Color statusColor(String statusName, BuildContext context) {
  final normalized = statusName.toLowerCase();
  final colorScheme = Theme.of(context).colorScheme;

  if (normalized.contains('approve') ||
      normalized.contains('signed') ||
      normalized.contains('done')) {
    return colorScheme.primary;
  }

  if (normalized.contains('reject') ||
      normalized.contains('cancel') ||
      normalized.contains('error')) {
    return colorScheme.error;
  }

  if (normalized.contains('draft') ||
      normalized.contains('new') ||
      normalized.contains('review')) {
    return colorScheme.tertiary;
  }

  return colorScheme.outline;
}
