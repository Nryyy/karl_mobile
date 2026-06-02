import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:karl_mobile/generated/app_localizations.dart';

import '../../data/documents_repository.dart';
import '../../domain/document_models.dart';
import '../widgets/google_drive_preview.dart';
import '../widgets/document_card_widget.dart';
import '../../../../widgets/qr_code_widget.dart';

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
      _showMessage('$uploadedLabel. ${formatFileSize(response.fileSize)}');
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
