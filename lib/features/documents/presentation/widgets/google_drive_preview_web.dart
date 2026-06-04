import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';

/// Displays a Google Drive document preview using an embedded iframe.
class GoogleDrivePreview extends StatefulWidget {
  /// Creates a Google Drive preview for the given [webViewLink].
  const GoogleDrivePreview({required this.webViewLink, super.key});

  /// The Google Drive web view link for the document.
  final String webViewLink;

  @override
  State<GoogleDrivePreview> createState() => _GoogleDrivePreviewState();
}

class _GoogleDrivePreviewState extends State<GoogleDrivePreview> {
  late final String _viewId;

  @override
  void initState() {
    super.initState();
    _viewId = 'google-drive-preview-${widget.webViewLink.hashCode}';
    final previewUrl = _toPreviewUrl(widget.webViewLink);

    ui_web.platformViewRegistry.registerViewFactory(_viewId, (int id) {
      final iframe =
          html.document.createElement('iframe') as html.IFrameElement
            ..src = previewUrl
            ..style.border = 'none'
            ..style.width = '100%'
            ..style.height = '100%'
            ..allowFullscreen = true;
      return iframe;
    });
  }

  /// Converts a Google Drive web view link to an embeddable preview URL.
  String _toPreviewUrl(String link) {
    if (link.contains('/preview')) return link;
    if (link.contains('/view')) return link.replaceFirst('/view', '/preview');
    final fileIdMatch = RegExp(r'/d/([^/]+)').firstMatch(link);
    if (fileIdMatch != null) {
      return 'https://drive.google.com/file/d/${fileIdMatch.group(1)}/preview';
    }
    return link;
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(viewType: _viewId);
  }
}