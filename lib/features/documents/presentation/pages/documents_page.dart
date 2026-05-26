import 'dart:developer' as developer;

import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/data/firebase_auth_service.dart';
import '../../../auth/domain/auth_service.dart';
import '../../data/documents_repository.dart';
import '../../domain/document_models.dart';
import '../widgets/google_drive_preview.dart';

/// Main post-login page showing the document list.
class DocumentsPage extends StatefulWidget {
  /// Creates the documents page.
  const DocumentsPage({super.key, this.userName, required this.repository});

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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => GoRouter.of(context).go('/documents/new'),
        icon: const Icon(Icons.add),
        label: const Text('Новий документ'),
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

class DocumentDetailPage extends StatefulWidget {
  const DocumentDetailPage({required this.document, super.key});

  final DocumentListItem? document;

  @override
  State<DocumentDetailPage> createState() => _DocumentDetailPageState();
}

class _DocumentDetailPageState extends State<DocumentDetailPage> {
  bool _isUploading = false;

  Future<void> _handleUploadFile() async {
    final result = await FilePicker.platform.pickFiles(
      withData: true,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'xlsx', 'xls', 'png', 'jpg'],
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    if (file.bytes == null) {
      _showMessage('Не вдалося прочитати файл.');
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showMessage('Сесія авторизації недійсна. Увійдіть ще раз.');
      return;
    }

    final document = widget.document!;
    final repository = HttpDocumentsRepository(
      accessTokenProvider: () => user.getIdToken(),
    );

    setState(() => _isUploading = true);
    try {
      final response = await repository.uploadDocumentFile(
        documentId: document.id,
        fileBytes: file.bytes!,
        fileName: file.name,
      );
      if (!mounted) return;
      _showMessage(
        'Файл завантажено. Розмір: ${_formatFileSize(response.fileSize)}',
      );
    } on DocumentsRepositoryException catch (e) {
      if (!mounted) return;
      _showMessage(e.message);
    } catch (_) {
      if (!mounted) return;
      _showMessage('Не вдалося завантажити файл.');
    } finally {
      if (mounted) setState(() => _isUploading = false);
      repository.dispose();
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    if (widget.document == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Документ')),
        body: const Center(child: Text('Документ не знайдено.')),
      );
    }

    final item = widget.document!;

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
          if (item.webViewLink.isNotEmpty) ...[  
            const SizedBox(height: 20),
            Text(
              'Перегляд документа',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 500,
                child: GoogleDrivePreview(webViewLink: item.webViewLink),
              ),
            ),
          ],
          const SizedBox(height: 16),
          _UploadFileSection(
            isUploading: _isUploading,
            onUpload: _handleUploadFile,
          ),
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

  PlatformFile? _pickedFile;
  bool _isSaving = false;
  bool _isLoadingUsers = false;

  String? _selectedFileType;
  String? _organizationId;
  String? _backendAuthorId;
  bool _googleDriveError = false;
  List<UserProfile> _allUsers = [];
  final List<_ApprovalStepEntry> _approvalSteps = [];

  static const List<String> _fileTypes = [
    'pdf',
    'docx',
    'doc',
    'xlsx',
    'xls',
    'png',
    'jpg',
  ];

  late final HttpDocumentsRepository _repository;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _repository = HttpDocumentsRepository(
        accessTokenProvider: () => user.getIdToken(),
      );
      _loadInitialData(user.uid, user.email ?? '');
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _repository.dispose();
    for (final step in _approvalSteps) {
      step.dispose();
    }
    super.dispose();
  }

  Future<void> _loadInitialData(String uid, String email) async {
    setState(() => _isLoadingUsers = true);
    try {
      final usersFuture = _repository.fetchUsers().catchError((Object e) {
        developer.log('Failed to load users', name: 'karl.editor', error: e);
        return <UserProfile>[];
      });
      final profileFuture = _repository
          .fetchCurrentUser(email)
          .then<UserProfile?>((p) => p)
          .catchError((Object e) {
        developer.log(
          'Failed to load current user profile',
          name: 'karl.editor',
          error: e,
        );
        return null;
      });
      final results = await Future.wait([profileFuture, usersFuture]);
      if (!mounted) return;
      final profile = results[0] as UserProfile?;
      final users = results[1] as List<UserProfile>;
      setState(() {
        if (profile != null) {
          _organizationId = profile.organizationId;
          _backendAuthorId = profile.id;
        }
        final currentBackendId = profile?.id ?? uid;
        _allUsers = users
            .where((u) => u.id != currentBackendId)
            .toList(growable: false);
      });
    } finally {
      if (mounted) setState(() => _isLoadingUsers = false);
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      withData: true,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'xlsx', 'xls', 'png', 'jpg'],
    );
    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      setState(() {
        _pickedFile = file;
        final ext = file.name.split('.').last.toLowerCase();
        if (_selectedFileType == null && _fileTypes.contains(ext)) {
          _selectedFileType = ext;
        }
        if (_titleController.text.trim().isEmpty) {
          final nameWithoutExt = file.name.contains('.')
              ? file.name.substring(0, file.name.lastIndexOf('.'))
              : file.name;
          _titleController.text = nameWithoutExt;
        }
      });
    }
  }

  void _addApprovalStep() {
    setState(() {
      _approvalSteps.add(_ApprovalStepEntry());
    });
  }

  void _removeApprovalStep(int index) {
    setState(() {
      _approvalSteps[index].dispose();
      _approvalSteps.removeAt(index);
    });
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      _showMessage('Введіть назву документа.');
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showMessage('Сесія авторизації недійсна. Увійдіть ще раз.');
      return;
    }

    final steps = <CreateApprovalStep>[];
    for (var i = 0; i < _approvalSteps.length; i++) {
      final entry = _approvalSteps[i];
      if (entry.selectedUser == null) {
        _showMessage('Оберіть погоджувача для кроку ${i + 1}.');
        return;
      }
      steps.add(
        CreateApprovalStep(
          stepOrder: i + 1,
          approverId: entry.selectedUser!.id,
          approverName: entry.selectedUser!.fullName,
          approverEmail: entry.selectedUser!.email,
        ),
      );
    }

    setState(() => _isSaving = true);

    try {
      final authorName =
          user.displayName?.trim().isNotEmpty == true
              ? user.displayName!
              : (user.email?.split('@').first ?? 'користувач');

      final effectiveFileType =
          _selectedFileType ??
          _pickedFile?.name.split('.').last.toLowerCase();

      final isEditable = const {'doc', 'docx', 'xlsx', 'xls'}
          .contains(effectiveFileType?.toLowerCase());
      final statusId = isEditable ? 'draft' : 'pending';
      final statusName = isEditable ? 'Draft' : 'Pending';

      final documentId = await _repository.createDocument(
        title: title,
        authorId: _backendAuthorId ?? user.uid,
        authorName: authorName,
        statusId: statusId,
        statusName: statusName,
        fileType: effectiveFileType,
        organizationId: _organizationId,
        approvalSteps: steps.isEmpty ? null : steps,
      );

      if (_pickedFile != null && _pickedFile!.bytes != null) {
        try {
          await _repository.uploadDocumentFile(
            documentId: documentId,
            fileBytes: _pickedFile!.bytes!,
            fileName: _pickedFile!.name,
          );
          if (!mounted) return;
          _showMessage('Документ створено та файл завантажено.');
          GoRouter.of(context).go('/documents');
        } on DocumentsRepositoryException catch (e) {
          if (!mounted) return;
          final isGDrive = e.message.toLowerCase().contains('google drive');
          if (isGDrive) {
            setState(() => _googleDriveError = true);
            _showMessage('Документ створено, але файл не завантажено.');
          } else {
            _showMessage(e.message);
            GoRouter.of(context).go('/documents');
          }
        }
      } else {
        if (!mounted) return;
        _showMessage('Документ створено.');
        GoRouter.of(context).go('/documents');
      }
    } on DocumentsRepositoryException catch (e) {
      if (!mounted) return;
      _showMessage(e.message);
    } catch (_) {
      if (!mounted) return;
      _showMessage('Не вдалося зберегти документ.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasFile = _pickedFile != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Новий документ'),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          _SectionCard(
            children: [
              _FieldLabel('Назва документа', required: true),
              const SizedBox(height: 6),
              TextField(
                controller: _titleController,
                style: theme.textTheme.bodyLarge,
                decoration: InputDecoration(
                  hintText: 'Введіть назву документа',
                  filled: true,
                  fillColor: AppColors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _FieldLabel('Тип файлу'),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _selectedFileType,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
                hint: const Text('Оберіть тип файлу'),
                items: _fileTypes
                    .map(
                      (t) => DropdownMenuItem(
                        value: t,
                        child: Text(t.toUpperCase()),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _selectedFileType = v),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SectionCard(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.attach_file_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Файл документа',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              GestureDetector(
                onTap: _pickFile,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    vertical: 24,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: hasFile
                        ? AppColors.accent.withValues(alpha: 0.05)
                        : AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: hasFile
                          ? AppColors.accent.withValues(alpha: 0.4)
                          : AppColors.border,
                      width: hasFile ? 1.5 : 1,
                      strokeAlign: BorderSide.strokeAlignInside,
                    ),
                  ),
                  child: hasFile
                      ? Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.description_rounded,
                                color: AppColors.accent,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _pickedFile!.name,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _formatFileSize(
                                      _pickedFile!.size,
                                    ),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: () =>
                                  setState(() => _pickedFile = null),
                              icon: const Icon(
                                Icons.close_rounded,
                                size: 18,
                                color: AppColors.textSecondary,
                              ),
                              visualDensity: VisualDensity.compact,
                              tooltip: 'Видалити файл',
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            const Icon(
                              Icons.cloud_upload_outlined,
                              size: 40,
                              color: AppColors.disabled,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Натисніть, щоб вибрати файл',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'PDF, DOCX, XLSX, PNG, JPG',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SectionCard(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.route_rounded,
                          color: AppColors.warning,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Маршрут погодження',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  if (_isLoadingUsers)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    )
                  else
                    TextButton.icon(
                      onPressed: _addApprovalStep,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                      ),
                      icon: const Icon(Icons.add_circle_outline, size: 16),
                      label: const Text(
                        'Додати крок',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                ],
              ),
              if (_approvalSteps.isEmpty) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.border,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        size: 16,
                        color: AppColors.textTertiary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Без маршруту погодження',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                const SizedBox(height: 12),
                ...List.generate(_approvalSteps.length, (i) {
                  final step = _approvalSteps[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _ApprovalStepRow(
                      stepNumber: i + 1,
                      selectedUser: step.selectedUser,
                      users: _allUsers,
                      onRemove: () => _removeApprovalStep(i),
                      onUserChanged: (u) =>
                          setState(() => step.selectedUser = u),
                    ),
                  );
                }),
              ],
            ],
          ),
          if (_googleDriveError) ...[  
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.cloud_off_rounded,
                    color: AppColors.warning,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Google Drive не підключено',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Документ збережено без файлу. Зверніться до адміністратора для підключення Google Drive.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextButton.icon(
                          onPressed: () => GoRouter.of(context).go('/documents'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.warning,
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                          ),
                          icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                          label: const Text(
                            'Перейти до документів',
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 28),
          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: _isSaving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: AppColors.disabled,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSaving
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Збереження...',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.save_outlined, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Зберегти документ',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
        children: children,
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text, {this.required = false});

  final String text;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            letterSpacing: 0.2,
          ),
        ),
        if (required)
          const Text(
            ' *',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.error,
            ),
          ),
      ],
    );
  }
}

class _ApprovalStepEntry {
  UserProfile? selectedUser;

  void dispose() {}
}

class _ApprovalStepRow extends StatelessWidget {
  const _ApprovalStepRow({
    required this.stepNumber,
    required this.selectedUser,
    required this.users,
    required this.onRemove,
    required this.onUserChanged,
  });

  final int stepNumber;
  final UserProfile? selectedUser;
  final List<UserProfile> users;
  final VoidCallback onRemove;
  final ValueChanged<UserProfile?> onUserChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$stepNumber',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<UserProfile>(
              initialValue: selectedUser,
              hint: const Text('Оберіть погоджувача'),
              isExpanded: true,
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
              items: users
                  .map(
                    (u) => DropdownMenuItem(
                      value: u,
                      child: Text(
                        u.fullName.isNotEmpty ? u.fullName : u.email,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: onUserChanged,
            ),
          ),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.close, size: 18),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

class _UploadFileSection extends StatelessWidget {
  const _UploadFileSection({
    required this.isUploading,
    required this.onUpload,
  });

  final bool isUploading;
  final VoidCallback onUpload;

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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.upload_file_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Завантажити файл',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: isUploading
                ? const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    ),
                  )
                : OutlinedButton.icon(
                    onPressed: onUpload,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.attach_file_rounded, size: 18),
                    label: const Text(
                      'Вибрати та завантажити файл',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
          ),
        ],
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

String _formatFileSize(int bytes) {
  if (bytes < 1024) return '$bytes Б';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} КБ';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} МБ';
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
