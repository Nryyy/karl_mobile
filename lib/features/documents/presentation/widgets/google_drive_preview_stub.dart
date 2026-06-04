import 'package:flutter/material.dart';

/// Displays a fallback message on non-web platforms.
class GoogleDrivePreview extends StatelessWidget {
  /// Creates a Google Drive preview placeholder for the given [webViewLink].
  const GoogleDrivePreview({required this.webViewLink, super.key});

  /// The Google Drive web view link for the document.
  final String webViewLink;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Document preview is available on web only.',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}