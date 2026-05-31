import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:karl_mobile/generated/app_localizations.dart';
import '../../domain/document_models.dart';

/// Simple document card with Hero animation
class DocumentCard extends StatelessWidget {
  const DocumentCard({
    super.key,
    required this.document,
    required this.onTap,
  });

  final DocumentListItem document;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Hero avatar
              Hero(
                tag: 'document-avatar-${document.id}',
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _getDocumentColor(context),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getDocumentIcon(),
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              
              // Document info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hero title
                    Hero(
                      tag: 'document-title-${document.id}',
                      child: Material(
                        type: MaterialType.transparency,
                        child: Text(
                          document.title.isEmpty ? (AppLocalizations.of(context)?.untitled ?? 'Untitled') : document.title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    
                    Text(
                      '${AppLocalizations.of(context)?.authorPrefix ?? 'Author:'} ${document.authorName.isEmpty ? (AppLocalizations.of(context)?.unknownAuthor ?? 'Unknown author') : document.authorName}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    
                    const SizedBox(height: 4),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(context).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _getStatusColor(context).withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        document.status.name,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: _getStatusColor(context),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  Color _getDocumentColor(BuildContext context) {
    final extension = document.fileType.toLowerCase();
    switch (extension) {
      case 'pdf':
        return Colors.red;
      case 'doc':
      case 'docx':
        return Colors.blue;
      case 'xls':
      case 'xlsx':
        return Colors.green;
      case 'ppt':
      case 'pptx':
        return Colors.orange;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  IconData _getDocumentIcon() {
    final extension = document.fileType.toLowerCase();
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getStatusColor(BuildContext context) {
    final status = document.status.name.toLowerCase();
    if (status.contains('очікує') || status.contains('pending')) {
      return Colors.orange;
    } else if (status.contains('підписано') || status.contains('signed')) {
      return Colors.green;
    } else if (status.contains('відхилено') || status.contains('rejected')) {
      return Colors.red;
    } else {
      return Theme.of(context).colorScheme.primary;
    }
  }
}

/// Enhanced document list with animations
class EnhancedDocumentList extends ConsumerWidget {
  const EnhancedDocumentList({
    super.key,
    required this.documents,
    required this.onDocumentTap,
    this.onRefresh,
  });

  final List<DocumentListItem> documents;
  final Function(DocumentListItem) onDocumentTap;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        // Stats cards with animation
        Container(
          height: 120,
          padding: const EdgeInsets.all(16),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatCard('Всього', '${documents.length}', Icons.description),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard('Очікують', '${_getPendingCount()}', Icons.pending),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard('Підписано', '${_getSignedCount()}', Icons.check_circle),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Document list
        Expanded(
          child: documents.isEmpty
              ? _buildEmptyState(context)
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: documents.length,
                  itemBuilder: (context, index) {
                    return TweenAnimationBuilder<double>(
                      duration: Duration(milliseconds: 300 + (index * 100)),
                      tween: Tween(begin: 0.0, end: 1.0),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, child) {
                        return Transform.translate(
                          offset: Offset(0, 20 * (1 - value)),
                          child: Opacity(
                            opacity: value,
                            child: DocumentCard(
                              document: documents[index],
                              onTap: () => onDocumentTap(documents[index]),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  value,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 600),
        tween: Tween(begin: 0.0, end: 1.0),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: Opacity(
              opacity: value,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TweenAnimationBuilder<double>(
                    duration: const Duration(seconds: 2),
                    tween: Tween(begin: 0.8, end: 1.2),
                    builder: (context, scale, child) {
                      return Transform.scale(
                        scale: scale,
                        child: Icon(
                          Icons.folder_open_outlined,
                          size: 80,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Немає документів',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Документи з\'являться тут після створення',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  int _getPendingCount() {
    return documents.where((doc) {
      final status = doc.status.name.toLowerCase();
      return status.contains('очікує') || status.contains('pending');
    }).length;
  }

  int _getSignedCount() {
    return documents.where((doc) {
      final status = doc.status.name.toLowerCase();
      return status.contains('підписано') || status.contains('signed');
    }).length;
  }
}

/// Animated loading widget
class DocumentLoadingWidget extends StatelessWidget {
  const DocumentLoadingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(AppLocalizations.of(context)?.loadingDocuments ?? 'Loading documents...'),
        ],
      ),
    );
  }
}

/// Animated error widget
class DocumentErrorWidget extends StatelessWidget {
  const DocumentErrorWidget({
    super.key,
    required this.error,
    required this.onRetry,
  });

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 400),
        tween: Tween(begin: 0.0, end: 1.0),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: Opacity(
              opacity: value,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Помилка завантаження',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh),
                    label: Text(AppLocalizations.of(context)?.tryAgain ?? 'Try again'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
