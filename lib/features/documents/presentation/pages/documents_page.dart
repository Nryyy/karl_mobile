import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/data/firebase_auth_service.dart';
import '../../../auth/domain/auth_service.dart';
import '../../data/documents_repository.dart';
import '../../domain/document_models.dart';

/// Main post-login page showing the document list.
class DocumentsPage extends StatefulWidget {
  /// Creates the documents page.
  DocumentsPage({super.key, this.userName, DocumentsRepository? repository})
    : repository = repository ?? MockDocumentsRepository();

  /// Display name of the authenticated user.
  final String? userName;

  /// Repository used to load documents.
  final DocumentsRepository repository;

  @override
  State<DocumentsPage> createState() => _DocumentsPageState();
}

class _DocumentsPageState extends State<DocumentsPage> {
  final AuthService _authService = FirebaseAuthService();
  final TextEditingController _searchController = TextEditingController();

  late Future<List<DocumentListItem>> _documentsFuture;
  String _searchQuery = '';
  String _selectedStatusFilter = 'all';
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

  void _selectStatusFilter(String filter) {
    if (_selectedStatusFilter == filter) {
      return;
    }

    setState(() {
      _selectedStatusFilter = filter;
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
      if (!mounted) return;
      context.goNamed('login');
    } catch (_) {
      if (!mounted) return;
      _showMessage('Не вдалося вийти з акаунта.');
    } finally {
      if (mounted) setState(() => _isSigningOut = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
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
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              final message = snapshot.error is DocumentsRepositoryException
                  ? snapshot.error.toString()
                  : 'Не вдалося завантажити документи.';

              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: [
                  _ErrorState(message: message, onRetry: _refreshDocuments),
                ],
              );
            }

            final documents = snapshot.data ?? const <DocumentListItem>[];
            final filteredDocuments = documents
                .where((document) {
                  return _matchesSearch(document) &&
                      _matchesStatusFilter(document);
                })
                .toList(growable: false);

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
              children: [
                _DocumentsSimpleHeader(
                  searchController: _searchController,
                  selectedStatusFilter: _selectedStatusFilter,
                  onSelectStatusFilter: _selectStatusFilter,
                ),
                const SizedBox(height: 12),
                if (filteredDocuments.isEmpty)
                  _EmptyState(
                    isSearchActive:
                        _searchQuery.isNotEmpty ||
                        _selectedStatusFilter != 'all',
                  )
                else
                  ...filteredDocuments.map(
                    (document) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _SimpleDocumentCard(document: document),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  bool _matchesSearch(DocumentListItem document) {
    if (_searchQuery.isEmpty) {
      return true;
    }

    final query = _searchQuery.toLowerCase();
    final searchValues = <String>[
      document.title,
      document.authorName,
      document.fileType,
      document.status.name,
      document.metadata.category,
      ...document.metadata.tags,
    ];

    return searchValues.any((value) => value.toLowerCase().contains(query));
  }

  bool _matchesStatusFilter(DocumentListItem document) {
    switch (_selectedStatusFilter) {
      case 'waiting':
        return _matchesStatus(document.status.name, <String>[
          'очіку',
          'pending',
        ]);
      case 'process':
        return _matchesStatus(document.status.name, <String>[
          'проц',
          'progress',
          'review',
        ]);
      case 'approved':
        return _matchesStatus(document.status.name, <String>[
          'затвер',
          'approve',
          'signed',
          'done',
        ]);
      case 'rejected':
        return _matchesStatus(document.status.name, <String>[
          'відхил',
          'reject',
          'cancel',
          'error',
        ]);
      case 'all':
      default:
        return true;
    }
  }

  bool _matchesStatus(String statusName, List<String> keywords) {
    final normalized = statusName.toLowerCase();
    return keywords.any(normalized.contains);
  }
}

class _DocumentsSimpleHeader extends StatelessWidget {
  const _DocumentsSimpleHeader({
    required this.searchController,
    required this.selectedStatusFilter,
    required this.onSelectStatusFilter,
  });

  final TextEditingController searchController;
  final String selectedStatusFilter;
  final ValueChanged<String> onSelectStatusFilter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Мої документи', style: theme.textTheme.titleLarge),
        const SizedBox(height: 6),
        Text(
          'Пошук, фільтри та список документів',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: searchController,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            hintText: 'Пошук за назвою, автором або типом',
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _FilterChip(
              label: 'Всі',
              selected: selectedStatusFilter == 'all',
              onSelected: () => onSelectStatusFilter('all'),
            ),
            _FilterChip(
              label: 'Очікують',
              selected: selectedStatusFilter == 'waiting',
              onSelected: () => onSelectStatusFilter('waiting'),
            ),
            _FilterChip(
              label: 'В процесі',
              selected: selectedStatusFilter == 'process',
              onSelected: () => onSelectStatusFilter('process'),
            ),
            _FilterChip(
              label: 'Затверджено',
              selected: selectedStatusFilter == 'approved',
              onSelected: () => onSelectStatusFilter('approved'),
            ),
            _FilterChip(
              label: 'Відхилено',
              selected: selectedStatusFilter == 'rejected',
              onSelected: () => onSelectStatusFilter('rejected'),
            ),
          ],
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
    );
  }
}

class _SimpleDocumentCard extends StatelessWidget {
  const _SimpleDocumentCard({required this.document});

  final DocumentListItem document;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(document.status.name);
    final createdAt = _formatDate(document.createdAt).split(' ').first;

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
                        Text(
                          document.title.isEmpty ? 'Без назви' : document.title,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          document.authorName.isEmpty
                              ? 'Невідомий автор'
                              : document.authorName,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  _StatusBadge(
                    label: document.status.name.isEmpty
                        ? 'Не вказано'
                        : document.status.name,
                    color: statusColor,
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
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
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
          Text(label, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}

class DocumentDetailPage extends StatelessWidget {
  const DocumentDetailPage({required this.document, super.key});

  final DocumentListItem? document;

  @override
  Widget build(BuildContext context) {
    if (document == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Документ')),
        body: const Center(child: Text('Документ не знайдено.')),
      );
    }

    final item = document!;

    return Scaffold(
      appBar: AppBar(title: Text(item.title.isEmpty ? 'Документ' : item.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            item.title.isEmpty ? 'Без назви' : item.title,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          _SimpleDocumentCard(document: item),
        ],
      ),
    );
  }
}

class DocumentEditorPage extends StatefulWidget {
  const DocumentEditorPage({super.key});

  @override
  State<DocumentEditorPage> createState() => _DocumentEditorPageState();
}

class _DocumentEditorPageState extends State<DocumentEditorPage> {
  final TextEditingController _titleController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _save() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Документ (мок) збережено')));
    GoRouter.of(context).go('/documents');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Новий документ')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Назва'),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save),
              label: const Text('Зберегти'),
            ),
          ],
        ),
      ),
    );
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
                  ? 'Спробуйте інший запит або очистіть фільтри.'
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
