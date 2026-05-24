import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/data/firebase_auth_service.dart';
import '../../../auth/domain/auth_service.dart';
import '../../data/documents_repository.dart';
import '../../domain/document_models.dart';

/// Main post-login page showing the document circulation dashboard.
class DocumentsPage extends StatefulWidget {
  /// Creates the documents dashboard.
  DocumentsPage({super.key, this.userName, DocumentsRepository? repository})
    : repository =
          repository ??
          HttpDocumentsRepository(
            accessTokenProvider: _defaultAccessTokenProvider,
          );

  /// Display name of the authenticated user.
  final String? userName;

  /// Repository used to load the document list.
  final DocumentsRepository repository;

  @override
  State<DocumentsPage> createState() => _DocumentsPageState();
}

class _DocumentsPageState extends State<DocumentsPage> {
  final AuthService _authService = FirebaseAuthService();
  final TextEditingController _searchController = TextEditingController();

  late Future<List<DocumentListItem>> _documentsFuture;
  String _searchQuery = '';
  bool _isSigningOut = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_handleSearchChanged);
    _documentsFuture = widget.repository.fetchDocuments();
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_handleSearchChanged)
      ..dispose();

    if (widget.repository is HttpDocumentsRepository) {
      (widget.repository as HttpDocumentsRepository).dispose();
    }

    super.dispose();
  }

  void _handleSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.trim();
    });
  }

  Future<void> _refreshDocuments() async {
    setState(() {
      _documentsFuture = widget.repository.fetchDocuments();
    });
    await _documentsFuture;
  }

  Future<void> _handleSignOut() async {
    setState(() => _isSigningOut = true);

    try {
      await _authService.signOut();
      if (!mounted) {
        return;
      }
      context.goNamed('login');
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showMessage('Не вдалося вийти з акаунта.');
    } finally {
      if (mounted) {
        setState(() => _isSigningOut = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final userName = _resolveUserName();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Документообіг'),
        actions: [
          IconButton(
            onPressed: _refreshDocuments,
            tooltip: 'Оновити документи',
            icon: const Icon(Icons.refresh_outlined),
          ),
          IconButton(
            onPressed: _isSigningOut ? null : _handleSignOut,
            tooltip: 'Вийти',
            icon: _isSigningOut
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: Padding(
                      padding: EdgeInsets.all(2),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : const Icon(Icons.logout_outlined),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshDocuments,
        child: FutureBuilder<List<DocumentListItem>>(
          future: _documentsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return _buildScrollableState(child: const _LoadingState());
            }

            if (snapshot.hasError) {
              final message = snapshot.error is DocumentsRepositoryException
                  ? snapshot.error.toString()
                  : 'Не вдалося завантажити документи.';
              return _buildScrollableState(
                child: _ErrorState(
                  message: message,
                  onRetry: _refreshDocuments,
                ),
              );
            }

            final documents = snapshot.data ?? const <DocumentListItem>[];
            final filteredDocuments = _filterDocuments(documents);

            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: _DashboardHeader(
                    userName: userName,
                    totalDocuments: documents.length,
                    activeApprovalFlows: documents
                        .where((document) => document.approvalFlow.isActive)
                        .length,
                    filteredDocuments: filteredDocuments.length,
                    isRefreshing:
                        snapshot.connectionState == ConnectionState.waiting,
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        hintText:
                            'Пошук за назвою, автором, статусом або тегом',
                      ),
                    ),
                  ),
                ),
                if (filteredDocuments.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyState(isSearchActive: _searchQuery.isNotEmpty),
                  )
                else ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                      child: _DocumentStatsRow(
                        totalDocuments: documents.length,
                        filteredDocuments: filteredDocuments.length,
                        activeApprovalFlows: documents
                            .where((document) => document.approvalFlow.isActive)
                            .length,
                        colorScheme: colorScheme,
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    sliver: SliverList.separated(
                      itemCount: filteredDocuments.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return _DocumentCard(
                          document: filteredDocuments[index],
                        );
                      },
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildScrollableState({required Widget child}) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [SliverFillRemaining(hasScrollBody: false, child: child)],
    );
  }

  String _resolveUserName() {
    final explicitName = widget.userName?.trim();
    if (explicitName != null && explicitName.isNotEmpty) {
      return explicitName;
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    final displayName = currentUser?.displayName?.trim();
    if (displayName != null && displayName.isNotEmpty) {
      return displayName;
    }

    final email = currentUser?.email?.trim();
    if (email != null && email.isNotEmpty) {
      final localPart = email.split('@').first;
      if (localPart.isNotEmpty) {
        return localPart
            .replaceAll(RegExp(r'[._-]+'), ' ')
            .split(' ')
            .where((part) => part.isNotEmpty)
            .map((part) => part[0].toUpperCase() + part.substring(1))
            .join(' ');
      }
    }

    return 'користувач';
  }

  List<DocumentListItem> _filterDocuments(List<DocumentListItem> documents) {
    if (_searchQuery.isEmpty) {
      return documents;
    }

    final query = _searchQuery.toLowerCase();
    return documents
        .where((document) {
          final searchValues = <String>[
            document.title,
            document.authorName,
            document.fileType,
            document.status.name,
            document.metadata.category,
            ...document.metadata.tags,
          ];

          return searchValues.any(
            (value) => value.toLowerCase().contains(query),
          );
        })
        .toList(growable: false);
  }
}

Future<String?> _defaultAccessTokenProvider() async {
  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser == null) {
    return null;
  }

  return currentUser.getIdToken();
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({
    required this.userName,
    required this.totalDocuments,
    required this.activeApprovalFlows,
    required this.filteredDocuments,
    required this.isRefreshing,
  });

  final String userName;
  final int totalDocuments;
  final int activeApprovalFlows;
  final int filteredDocuments;
  final bool isRefreshing;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.primaryLight],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: Color(0x22000000),
              blurRadius: 24,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.folder_copy_outlined,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Вітаємо, $userName',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Ось актуальні документи, етапи погодження та службові матеріали.',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _StatChip(label: 'Усього', value: totalDocuments.toString()),
                  _StatChip(
                    label: 'Після фільтра',
                    value: filteredDocuments.toString(),
                  ),
                  _StatChip(
                    label: 'Активні узгодження',
                    value: activeApprovalFlows.toString(),
                  ),
                  if (isRefreshing)
                    const _StatChip(label: 'Синхронізація', value: 'оновлення'),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Категорії: документи, договори, заявки, звіти',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onPrimary.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Text(
        '$label: $value',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _DocumentStatsRow extends StatelessWidget {
  const _DocumentStatsRow({
    required this.totalDocuments,
    required this.filteredDocuments,
    required this.activeApprovalFlows,
    required this.colorScheme,
  });

  final int totalDocuments;
  final int filteredDocuments;
  final int activeApprovalFlows;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _MiniStatCard(
          label: 'Всього документів',
          value: totalDocuments.toString(),
          icon: Icons.description_outlined,
          accentColor: colorScheme.primary,
        ),
        _MiniStatCard(
          label: 'Відфільтровано',
          value: filteredDocuments.toString(),
          icon: Icons.filter_alt_outlined,
          accentColor: AppColors.accent,
        ),
        _MiniStatCard(
          label: 'Активні потоки',
          value: activeApprovalFlows.toString(),
          icon: Icons.hub_outlined,
          accentColor: AppColors.warning,
        ),
      ],
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  const _MiniStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.accentColor,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 160),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: accentColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(label, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DocumentCard extends StatelessWidget {
  const _DocumentCard({required this.document});

  final DocumentListItem document;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(document.status.name);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        leading: CircleAvatar(
          backgroundColor: statusColor.withValues(alpha: 0.12),
          child: Icon(Icons.description_outlined, color: statusColor),
        ),
        title: Text(
          document.title.isEmpty ? 'Без назви' : document.title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${document.authorName.isEmpty ? 'Невідомий автор' : document.authorName} · ${document.status.name.isEmpty ? 'Статус не вказано' : document.status.name}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _DocumentChip(
                    label: document.fileType.isEmpty
                        ? 'file'
                        : document.fileType,
                    color: AppColors.primary,
                  ),
                  if (document.metadata.category.isNotEmpty)
                    _DocumentChip(
                      label: document.metadata.category,
                      color: AppColors.secondary,
                    ),
                  if (document.metadata.pageCount > 0)
                    _DocumentChip(
                      label: '${document.metadata.pageCount} стор.',
                      color: AppColors.info,
                    ),
                  if (document.metadata.version > 0)
                    _DocumentChip(
                      label: 'v${document.metadata.version}',
                      color: AppColors.accent,
                    ),
                ],
              ),
            ],
          ),
        ),
        children: [_DocumentDetails(document: document)],
      ),
    );
  }
}

class _DocumentDetails extends StatelessWidget {
  const _DocumentDetails({required this.document});

  final DocumentListItem document;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _DetailTile(
              label: 'Створено',
              value: _formatDate(document.createdAt),
              icon: Icons.event_available_outlined,
            ),
            _DetailTile(
              label: 'Оновлено',
              value: _formatDate(document.updatedAt),
              icon: Icons.update_outlined,
            ),
            _DetailTile(
              label: 'Розмір файлу',
              value: _formatFileSize(document.metadata.fileSize),
              icon: Icons.storage_outlined,
            ),
            _DetailTile(
              label: 'Google Drive ID',
              value: document.googleDriveFileId.isEmpty
                  ? 'Не вказано'
                  : document.googleDriveFileId,
              icon: Icons.link_outlined,
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (document.approvalFlow.isActive) ...[
          Text(
            'Погодження',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          _FlowSummary(document: document),
          const SizedBox(height: 16),
        ],
        if (document.signatures.isNotEmpty) ...[
          Text(
            'Підписи',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          ...document.signatures.map(
            (signature) => _PersonRecordTile(
              icon: Icons.verified_outlined,
              title: signature.userName.isEmpty
                  ? 'Без імені'
                  : signature.userName,
              subtitle:
                  '${signature.signatureType.isEmpty ? 'Тип не вказано' : signature.signatureType} · ${_formatDate(signature.signedAt)}',
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (document.comments.isNotEmpty) ...[
          Text(
            'Коментарі',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          ...document.comments.map(
            (comment) => _PersonRecordTile(
              icon: Icons.mode_comment_outlined,
              title: comment.userName.isEmpty ? 'Без імені' : comment.userName,
              subtitle: comment.comment.isEmpty
                  ? _formatDate(comment.createdAt)
                  : '${comment.comment} · ${_formatDate(comment.createdAt)}',
            ),
          ),
          const SizedBox(height: 16),
        ],
        Text(
          'Посилання та службові дані',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        _SelectableTextRow(label: 'Web preview', value: document.webViewLink),
        const SizedBox(height: 8),
        _SelectableTextRow(
          label: 'Web content',
          value: document.webContentLink,
        ),
        const SizedBox(height: 8),
        _SelectableTextRow(label: 'Автор ID', value: document.authorId),
      ],
    );
  }
}

class _FlowSummary extends StatelessWidget {
  const _FlowSummary({required this.document});

  final DocumentListItem document;

  @override
  Widget build(BuildContext context) {
    if (document.approvalFlow.steps.isEmpty) {
      return Text(
        'Етапи погодження не додані.',
        style: Theme.of(context).textTheme.bodyMedium,
      );
    }

    final currentStep = document.approvalFlow.currentStep;

    return Column(
      children: document.approvalFlow.steps
          .map((step) {
            final isCurrent = step.stepOrder == currentStep;
            final statusColor = _statusColor(step.status.name);

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isCurrent
                    ? AppColors.primary.withValues(alpha: 0.08)
                    : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: statusColor.withValues(alpha: 0.14),
                    child: Text(
                      step.stepOrder.toString(),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          step.approverName.isEmpty
                              ? 'Без імені'
                              : step.approverName,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${step.status.name.isEmpty ? 'Статус не вказано' : step.status.name} · ${step.approverEmail.isEmpty ? 'email відсутній' : step.approverEmail}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        if (step.comment.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            step.comment,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (isCurrent)
                    const Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Icon(
                        Icons.play_arrow_rounded,
                        color: AppColors.primary,
                      ),
                    ),
                ],
              ),
            );
          })
          .toList(growable: false),
    );
  }
}

class _DocumentChip extends StatelessWidget {
  const _DocumentChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      visualDensity: VisualDensity.compact,
      side: BorderSide(color: color.withValues(alpha: 0.24)),
      backgroundColor: color.withValues(alpha: 0.08),
      labelStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: color,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _DetailTile extends StatelessWidget {
  const _DetailTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 160),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: Theme.of(context).textTheme.labelSmall),
                  const SizedBox(height: 4),
                  Text(
                    value.isEmpty ? 'Не вказано' : value,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PersonRecordTile extends StatelessWidget {
  const _PersonRecordTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectableTextRow extends StatelessWidget {
  const _SelectableTextRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 4),
          SelectableText(
            value.isEmpty ? 'Не вказано' : value,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.isSearchActive});

  final bool isSearchActive;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.inbox_outlined,
              size: 72,
              color: AppColors.disabled,
            ),
            const SizedBox(height: 16),
            Text(
              isSearchActive ? 'Нічого не знайдено' : 'Документи відсутні',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              isSearchActive
                  ? 'Спробуйте інший запит або очистіть пошук.'
                  : 'API поки не повернув жодного документа.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 72, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              'Не вдалося завантажити документи',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
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
    );
  }
}

String _formatDate(DateTime? dateTime) {
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

String _formatFileSize(int fileSize) {
  if (fileSize <= 0) {
    return 'Не вказано';
  }

  const kb = 1024;
  const mb = kb * 1024;
  if (fileSize >= mb) {
    return '${(fileSize / mb).toStringAsFixed(1)} MB';
  }
  if (fileSize >= kb) {
    return '${(fileSize / kb).toStringAsFixed(1)} KB';
  }
  return '$fileSize B';
}

Color _statusColor(String statusName) {
  final normalized = statusName.toLowerCase();

  if (normalized.contains('approve') ||
      normalized.contains('signed') ||
      normalized.contains('done')) {
    return AppColors.success;
  }

  if (normalized.contains('reject') ||
      normalized.contains('cancel') ||
      normalized.contains('error')) {
    return AppColors.error;
  }

  if (normalized.contains('draft') ||
      normalized.contains('new') ||
      normalized.contains('review')) {
    return AppColors.warning;
  }

  return AppColors.primary;
}
