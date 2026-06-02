import 'dart:developer' as developer;
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:karl_mobile/generated/app_localizations.dart';

import '../../providers/documents_provider.dart';
import '../../providers/document_actions_provider.dart';
import '../../../auth/data/firebase_auth_service.dart';
import '../../../auth/domain/auth_service.dart';
import '../../data/documents_repository.dart';
import '../../domain/document_models.dart';
import '../widgets/google_drive_preview.dart';
import '../../../../core/services/image_picker_service.dart';
import '../../../../core/services/firebase_storage_service.dart';
import '../../../../core/utils/document_utils.dart';
import '../../../../widgets/image_display_widget.dart';
import '../../../../widgets/qr_code_widget.dart';

/// Main post-login page showing the document list.
class DocumentsPage extends ConsumerStatefulWidget {
  /// Creates the documents page.
  const DocumentsPage({super.key, this.userName, required this.repository});

  /// Display name of the authenticated user.
  final String? userName;

  /// Repository used to load documents.
  final DocumentsRepository repository;

  @override
  ConsumerState<DocumentsPage> createState() => _DocumentsPageState();
}

class _DocumentsPageState extends ConsumerState<DocumentsPage> {
  final AuthService _authService = FirebaseAuthService();
  final ImagePickerService _imagePickerService = ImagePickerService();
  final FirebaseStorageService _storageService = FirebaseStorageService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedStatusFilter = 'all';
  bool _isSigningOut = false;
  List<File> _selectedImages = [];
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_handleSearchChanged);
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
    await ref.read(documentsProvider.notifier).refresh();
  }

  Future<void> _handleSignOut() async {
    setState(() => _isSigningOut = true);

    try {
      await _authService.signOut();
      if (!mounted) return;
      context.goNamed('login');
    } catch (_) {
      if (!mounted) return;
      _showMessage(
        AppLocalizations.of(context)?.signOut ?? 'Could not sign out.',
      );
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
        title: Text(AppLocalizations.of(context)?.documents ?? 'Documents'),
        actions: [
          IconButton(
            onPressed: _refreshDocuments,
            tooltip: AppLocalizations.of(context)?.refresh ?? 'Refresh',
            icon: const Icon(Icons.refresh_outlined),
          ),
          IconButton(
            onPressed: _isSigningOut ? null : _handleSignOut,
            tooltip: AppLocalizations.of(context)?.signOut ?? 'Sign out',
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
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: "camera",
            onPressed: _showImagePickerBottomSheet,
            child: const Icon(Icons.camera_alt),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.extended(
            heroTag: "new_document",
            onPressed: () => GoRouter.of(context).go('/documents/new'),
            icon: const Icon(Icons.add),
            label: Text(AppLocalizations.of(context)?.upload ?? 'New document'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshDocuments,
        child: ref
            .watch(documentsProvider)
            .when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, st) => ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: [
                  _ErrorState(
                    message: err is DocumentsRepositoryException
                        ? err.toString()
                        : (AppLocalizations.of(context)?.firebaseInitError ??
                              'Failed to load documents.'),
                    onRetry: _refreshDocuments,
                  ),
                ],
              ),
              data: (documents) {
                final filteredDocuments = documents
                    .where(
                      (document) =>
                          _matchesSearch(document) &&
                          _matchesStatusFilter(document),
                    )
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
                    if (_selectedImages.isNotEmpty) ...[
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).colorScheme.outline.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  AppLocalizations.of(context)?.selectedPhotos(_selectedImages.length) ?? 'Selected photos (${_selectedImages.length})',
                                  style: Theme.of(context).textTheme.titleSmall
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                                Row(
                                  children: [
                                    if (_isUploadingImage)
                                      const Padding(
                                        padding: EdgeInsets.only(right: 8),
                                        child: SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      ),
                                    TextButton.icon(
                                      onPressed: _isUploadingImage
                                          ? null
                                          : _uploadImagesToFirebase,
                                      icon: const Icon(
                                        Icons.cloud_upload,
                                        size: 16,
                                      ),
                                      label: Text(AppLocalizations.of(context)?.uploadToFirebase ?? 'Upload to Firebase'),
                                    ),
                                    IconButton(
                                      onPressed: () => setState(
                                        () => _selectedImages.clear(),
                                      ),
                                      icon: const Icon(
                                        Icons.clear_all,
                                        size: 20,
                                      ),
                                      tooltip: AppLocalizations.of(context)?.clearAll ?? 'Clear all',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ImageGridWidget(
                              images: _selectedImages,
                              crossAxisCount: 3,
                              showDeleteButton: true,
                              onDelete: (index) => _removeImage(index),
                              onTap: (index) {
                                // Show image preview
                                showDialog(
                                  context: context,
                                  builder: (context) => Dialog(
                                    child: Container(
                                      constraints: BoxConstraints(
                                        maxWidth:
                                            MediaQuery.of(context).size.width *
                                            0.9,
                                        maxHeight:
                                            MediaQuery.of(context).size.height *
                                            0.8,
                                      ),
                                      child: ImageDisplayWidget(
                                        imageFile: _selectedImages[index],
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
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
                          child: SimpleDocumentCard(
                            document: document,
                            onChanged: _refreshDocuments,
                          ),
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
        return matchesStatus(document.status.name, <String>[
          'очіку',
          'pending',
        ]);
      case 'process':
        return matchesStatus(document.status.name, <String>[
          'проц',
          'progress',
          'review',
        ]);
      case 'approved':
        return matchesStatus(document.status.name, <String>[
          'затвер',
          'approve',
          'signed',
          'done',
        ]);
      case 'rejected':
        return matchesStatus(document.status.name, <String>[
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

  Future<void> _pickImageFromCamera() async {
    try {
      final image = await _imagePickerService.pickImageFromCamera();
      if (image != null) {
        setState(() {
          _selectedImages.add(image);
        });
        _showMessage(AppLocalizations.of(context)?.photoCameraAdded ?? 'Photo from camera added');
      }
    } catch (e) {
      _showMessage(AppLocalizations.of(context)?.photoCameraError(e) ?? 'Error picking photo from camera: $e');
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final image = await _imagePickerService.pickImageFromGallery();
      if (image != null) {
        setState(() {
          _selectedImages.add(image);
        });
        _showMessage(AppLocalizations.of(context)?.photoGalleryAdded ?? 'Photo from gallery added');
      }
    } catch (e) {
      _showMessage(AppLocalizations.of(context)?.photoGalleryError(e) ?? 'Error picking photo from gallery: $e');
    }
  }

  Future<void> _pickMultipleImagesFromGallery() async {
    try {
      final images = await _imagePickerService.pickMultipleImagesFromGallery();
      if (images.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(images);
        });
        _showMessage(AppLocalizations.of(context)?.photosAddedCount(images.length) ?? '${images.length} photos from gallery added');
      }
    } catch (e) {
      _showMessage(AppLocalizations.of(context)?.photoGalleryError(e) ?? 'Error picking photo from gallery: $e');
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _uploadImagesToFirebase() async {
    if (_selectedImages.isEmpty) {
      _showMessage(AppLocalizations.of(context)?.noPhotosToUpload ?? 'No photos to upload');
      return;
    }

    setState(() {
      _isUploadingImage = true;
    });

    try {
      final List<String> uploadedUrls = [];

      for (int i = 0; i < _selectedImages.length; i++) {
        final image = _selectedImages[i];
        final url = await _storageService.uploadImage(
          imageFile: image,
          folder: 'document_images',
          customFileName:
              'doc_image_${DateTime.now().millisecondsSinceEpoch}_$i.jpg',
        );
        uploadedUrls.add(url);
      }

      setState(() {
        _selectedImages.clear();
      });

      _showMessage(
        AppLocalizations.of(context)?.photosUploadedSuccess(uploadedUrls.length) ?? 'Successfully uploaded ${uploadedUrls.length} photos to Firebase Storage',
      );
    } catch (e) {
      _showMessage(AppLocalizations.of(context)?.photosUploadError(e) ?? 'Error uploading photos: $e');
    } finally {
      setState(() {
        _isUploadingImage = false;
      });
    }
  }

  void _showImagePickerBottomSheet() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: Text(AppLocalizations.of(context)?.takePhoto ?? 'Take photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromCamera();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: Text(AppLocalizations.of(context)?.choosePhotoFromGallery ?? 'Choose photo from gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromGallery();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: Text(AppLocalizations.of(context)?.chooseMultiplePhotos ?? 'Choose multiple photos'),
                onTap: () {
                  Navigator.pop(context);
                  _pickMultipleImagesFromGallery();
                },
              ),
            ],
          ),
        );
      },
    );
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
        Text(
          AppLocalizations.of(context)?.myDocuments ?? 'My Documents',
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: 6),
        Text(
          AppLocalizations.of(context)?.searchHint ??
              'Search, filters and list of documents',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: searchController,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search),
            hintText:
                AppLocalizations.of(context)?.searchHint ??
                'Search documents...',
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _FilterChip(
              label: AppLocalizations.of(context)?.statusAll ?? 'All',
              selected: selectedStatusFilter == 'all',
              onSelected: () => onSelectStatusFilter('all'),
            ),
            _FilterChip(
              label: AppLocalizations.of(context)?.statusWaiting ?? 'Waiting',
              selected: selectedStatusFilter == 'waiting',
              onSelected: () => onSelectStatusFilter('waiting'),
            ),
            _FilterChip(
              label:
                  AppLocalizations.of(context)?.statusInProgress ??
                  'In progress',
              selected: selectedStatusFilter == 'process',
              onSelected: () => onSelectStatusFilter('process'),
            ),
            _FilterChip(
              label: AppLocalizations.of(context)?.statusApproved ?? 'Approved',
              selected: selectedStatusFilter == 'approved',
              onSelected: () => onSelectStatusFilter('approved'),
            ),
            _FilterChip(
              label: AppLocalizations.of(context)?.statusRejected ?? 'Rejected',
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

class SimpleDocumentCard extends ConsumerStatefulWidget {
  const SimpleDocumentCard({
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
    final statusColor = _statusColor(document.status.name, context);
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
                    color: statusColor,
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
      _showMessage(
        AppLocalizations.of(context)?.unknownError ?? 'Unable to read file.',
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showMessage(AppLocalizations.of(context)?.sessionExpired ?? 'Session expired. Please sign in again.');
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
      final uploadedLabel =
          AppLocalizations.of(context)?.fileUploaded ?? 'File uploaded';
      _showMessage('$uploadedLabel. ${_formatFileSize(response.fileSize)}');
    } on DocumentsRepositoryException catch (e) {
      if (!mounted) return;
      _showMessage(e.message);
    } catch (_) {
      if (!mounted) return;
      _showMessage(AppLocalizations.of(context)?.fileUploadFailed ?? 'Failed to upload file.');
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
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)?.document ?? 'Document'),
        ),
        body: Center(
          child: Text(
            AppLocalizations.of(context)?.documentNotFound ??
                'Document not found.',
          ),
        ),
      );
    }

    final item = widget.document!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          item.title.isEmpty
              ? (AppLocalizations.of(context)?.document ?? 'Document')
              : item.title,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Hero(
            tag: 'document-title-${item.id}',
            child: Material(
              type: MaterialType.transparency,
              child: Text(
                item.title.isEmpty
                    ? (AppLocalizations.of(context)?.untitled ?? 'Untitled')
                    : item.title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SimpleDocumentCard(document: item),
          if (item.webViewLink.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              AppLocalizations.of(context)?.viewDocumentLabel ?? 'Document preview',
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
          const SizedBox(height: 16),
          QRCodeWidget(
            document: item,
            currentUserName:
                FirebaseAuth.instance.currentUser?.displayName ?? 'User',
          ),
        ],
      ),
    );
  }
}

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
      // Load current user profile
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

        // Load users using provider
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
                initialValue: _selectedFileType,
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
                                    _formatFileSize(_pickedFile!.size),
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
              initialValue: selectedUser,
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

class _UploadFileSection extends StatelessWidget {
  const _UploadFileSection({required this.isUploading, required this.onUpload});

  final bool isUploading;
  final VoidCallback onUpload;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                  Icons.upload_file_rounded,
                  color: colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                AppLocalizations.of(context)?.uploadFile ?? 'Upload file',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: isUploading
                ? Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colorScheme.primary,
                      ),
                    ),
                  )
                : OutlinedButton.icon(
                    onPressed: onUpload,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colorScheme.primary,
                      side: BorderSide(color: colorScheme.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.attach_file_rounded, size: 18),
                    label: Text(
                      AppLocalizations.of(context)?.selectAndUpload ??
                          'Select and upload file',
                      style: const TextStyle(fontWeight: FontWeight.w500),
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
            Icon(
              Icons.inbox_outlined,
              size: 72,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              isSearchActive
                  ? (AppLocalizations.of(context)?.nothingFound ??
                        'Nothing found')
                  : (AppLocalizations.of(context)?.noDocuments ??
                        'No documents found'),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              isSearchActive
                  ? (AppLocalizations.of(context)?.tryDifferentQuery ??
                        'Try a different query or clear filters.')
                  : (AppLocalizations.of(context)?.noDocumentsDescription ??
                        'API did not return any documents yet.'),
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
            Icon(
              Icons.error_outline,
              size: 72,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)?.failedToLoadDocuments ??
                  'Failed to load documents.',
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
              label: Text(
                AppLocalizations.of(context)?.tryAgain ?? 'Try again',
              ),
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

Color _statusColor(String statusName, BuildContext context) {
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
