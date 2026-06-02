import 'dart:developer' as developer;

import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:karl_mobile/generated/app_localizations.dart';

import '../../data/documents_repository.dart';
import '../../domain/document_models.dart';
import '../../providers/document_actions_provider.dart';
import '../../providers/documents_provider.dart';
import '../widgets/document_card_widget.dart';

class DocumentEditorPage extends ConsumerStatefulWidget {
  const DocumentEditorPage({super.key});

  @override
  ConsumerState<DocumentEditorPage> createState() => _DocumentEditorPageState();
}

class _DocumentEditorPageState extends ConsumerState<DocumentEditorPage> {
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

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _loadInitialData(user.uid, user.email ?? '');
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    for (final step in _approvalSteps) {
      step.dispose();
    }
    super.dispose();
  }

  Future<void> _loadInitialData(String uid, String email) async {
    setState(() => _isLoadingUsers = true);
    try {
      UserProfile? profile;
      try {
        profile = await ref.read(currentUserProvider.future);
      } catch (e) {
        developer.log(
          'Failed to load current user profile',
          name: 'karl.editor',
          error: e,
        );
        profile = null;
      }

      if (profile != null) {
        _organizationId = profile.organizationId;
        _backendAuthorId = profile.id;

        await ref
            .read(usersProvider.notifier)
            .refresh(organizationId: profile.organizationId);

        final usersAsync = ref.read(usersProvider.future);
        final users = await usersAsync.catchError((Object e) {
          developer.log('Failed to load users', name: 'karl.editor', error: e);
          return <UserProfile>[];
        });

        if (!mounted) return;
        final currentBackendId = profile.id;
        setState(() {
          _allUsers = users
              .where((u) => u.id != currentBackendId)
              .toList(growable: false);
        });
      }
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
      _showMessage(AppLocalizations.of(context)?.enterDocumentTitle ?? 'Enter document title.');
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showMessage(AppLocalizations.of(context)?.sessionExpired ?? 'Session expired. Please sign in again.');
      return;
    }

    final steps = <CreateApprovalStep>[];
    for (var i = 0; i < _approvalSteps.length; i++) {
      final entry = _approvalSteps[i];
      if (entry.selectedUser == null) {
        _showMessage(AppLocalizations.of(context)?.selectApproverForStep(i + 1) ?? 'Select approver for step ${i + 1}.');
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
      final authorName = user.displayName?.trim().isNotEmpty == true
          ? user.displayName!
          : (user.email?.split('@').first ?? 'користувач');

      final effectiveFileType =
          _selectedFileType ?? _pickedFile?.name.split('.').last.toLowerCase();

      final isEditable = const {
        'doc',
        'docx',
        'xlsx',
        'xls',
      }.contains(effectiveFileType?.toLowerCase());
      final statusId = isEditable ? 'draft' : 'pending';
      final statusName = isEditable ? 'Draft' : 'Pending';

      final documentId = await ref
          .read(documentActionsProvider.notifier)
          .createDocument(
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
          await ref
              .read(documentActionsProvider.notifier)
              .uploadDocumentFile(
                documentId: documentId,
                fileBytes: _pickedFile!.bytes!,
                fileName: _pickedFile!.name,
              );
          if (!mounted) return;
          _showMessage(AppLocalizations.of(context)?.documentCreatedAndUploaded ?? 'Document created and file uploaded.');
          GoRouter.of(context).go('/documents');
        } on DocumentsRepositoryException catch (e) {
          if (!mounted) return;
          final isGDrive = e.message.toLowerCase().contains('google drive');
          if (isGDrive) {
            setState(() => _googleDriveError = true);
            _showMessage(AppLocalizations.of(context)?.documentCreatedFileNotUploaded ?? 'Document created, but file not uploaded.');
          } else {
            _showMessage(e.message);
            GoRouter.of(context).go('/documents');
          }
        }
      } else {
        if (!mounted) return;
        _showMessage(AppLocalizations.of(context)?.documentCreated ?? 'Document created.');
        GoRouter.of(context).go('/documents');
      }
    } on DocumentsRepositoryException catch (e) {
      if (!mounted) return;
      _showMessage(e.message);
    } catch (_) {
      if (!mounted) return;
      _showMessage(AppLocalizations.of(context)?.documentSaveFailed ?? 'Failed to save document.');
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
    final colorScheme = theme.colorScheme;
    final hasFile = _pickedFile != null;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: colorScheme.surfaceContainerLowest,
        elevation: 0,
        title: Text(
          AppLocalizations.of(context)?.newDocument ?? 'New document',
        ),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          _SectionCard(
            children: [
              _FieldLabel(AppLocalizations.of(context)?.documentTitleLabel ?? 'Document title', required: true),
              const SizedBox(height: 6),
              TextField(
                controller: _titleController,
                style: theme.textTheme.bodyLarge,
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)?.documentTitleHint ?? 'Enter document title',
                  filled: true,
                  fillColor: colorScheme.surfaceContainerLowest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: colorScheme.outline),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: colorScheme.outline),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: colorScheme.primary,
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
              _FieldLabel(AppLocalizations.of(context)?.fileTypeLabel ?? 'File type'),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _selectedFileType,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: colorScheme.surfaceContainerLowest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: colorScheme.outline),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: colorScheme.outline),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: colorScheme.primary,
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
                hint: Text(
                  AppLocalizations.of(context)?.chooseFileType ??
                      'Choose file type',
                ),
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
                      color: colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.attach_file_rounded,
                      color: colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    AppLocalizations.of(context)?.documentFileLabel ?? 'Document file',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
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
                        ? colorScheme.tertiary.withValues(alpha: 0.05)
                        : colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: hasFile
                          ? colorScheme.tertiary.withValues(alpha: 0.4)
                          : colorScheme.outline,
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
                                color: colorScheme.tertiary.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.description_rounded,
                                color: colorScheme.tertiary,
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
                                      color: colorScheme.onSurface,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    formatFileSize(_pickedFile!.size),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: () =>
                                  setState(() => _pickedFile = null),
                              icon: Icon(
                                Icons.close_rounded,
                                size: 18,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              visualDensity: VisualDensity.compact,
                              tooltip: AppLocalizations.of(context)?.removeFile ?? 'Remove file',
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            Icon(
                              Icons.cloud_upload_outlined,
                              size: 40,
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.38,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              AppLocalizations.of(context)?.tapToSelectFile ?? 'Tap to select a file',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'PDF, DOCX, XLSX, PNG, JPG',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
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
                          color: colorScheme.tertiary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.route_rounded,
                          color: colorScheme.tertiary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        AppLocalizations.of(context)?.approvalRouteLabel ?? 'Approval route',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  if (_isLoadingUsers)
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colorScheme.primary,
                      ),
                    )
                  else
                    TextButton.icon(
                      onPressed: _addApprovalStep,
                      style: TextButton.styleFrom(
                        foregroundColor: colorScheme.primary,
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                      ),
                      icon: const Icon(Icons.add_circle_outline, size: 16),
                      label: Text(
                        AppLocalizations.of(context)?.addStep ?? 'Add step',
                        style: const TextStyle(fontSize: 13),
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
                    color: colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: colorScheme.outline,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 16,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        AppLocalizations.of(context)?.noApprovalRoute ?? 'No approval route',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
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
                color: colorScheme.tertiary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.tertiary.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.cloud_off_rounded,
                    color: colorScheme.tertiary,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Google Drive не підключено',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Документ збережено без файлу. Зверніться до адміністратора для підключення Google Drive.',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 10),
                        TextButton.icon(
                          onPressed: () =>
                              GoRouter.of(context).go('/documents'),
                          style: TextButton.styleFrom(
                            foregroundColor: colorScheme.tertiary,
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                          ),
                          icon: const Icon(
                            Icons.arrow_forward_rounded,
                            size: 16,
                          ),
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSaving
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colorScheme.onPrimary,
                          ),
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Збереження...',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onPrimary,
                          ),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.save_outlined, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Зберегти документ',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onPrimary,
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
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
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
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurfaceVariant,
            letterSpacing: 0.2,
          ),
        ),
        if (required)
          Text(
            ' *',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: colorScheme.error,
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
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
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
              value: selectedUser,
              hint: Text(
                AppLocalizations.of(context)?.chooseApprover ??
                    'Choose approver',
              ),
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
