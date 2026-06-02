import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:karl_mobile/generated/app_localizations.dart';

import '../../providers/documents_provider.dart';
import '../../../auth/data/firebase_auth_service.dart';
import '../../../auth/domain/auth_service.dart';
import '../../data/documents_repository.dart';
import '../../domain/document_models.dart';
import '../../../../core/services/image_picker_service.dart';
import '../../../../core/services/firebase_storage_service.dart';
import '../../../../core/utils/document_utils.dart';
import '../../../../widgets/image_display_widget.dart';
import '../widgets/document_card_widget.dart';

export 'document_detail_page.dart' show DocumentDetailPage;
export 'document_editor_page.dart' show DocumentEditorPage;

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
