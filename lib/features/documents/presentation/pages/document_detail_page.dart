import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:karl_mobile/generated/app_localizations.dart';
import 'dart:convert';

import '../../../ai_chat/ai_chat_service.dart';
import '../../../ai_chat/models/ai_chat_request.dart';
import '../../../../core/config/api_config.dart';

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
  bool _showPreview = false;
  bool _showAiAnalysis = false;
  bool _showQrCode = false;

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
          const SizedBox(height: 16),
          if (item.webViewLink.isNotEmpty) ...[
            _LazySectionCard(
              title:
                  AppLocalizations.of(context)?.viewDocumentLabel ??
                  'Document preview',
              icon: Icons.visibility_outlined,
              buttonLabel: _showPreview
                  ? 'Hide preview'
                  : 'Open',
              onPressed: () => setState(() => _showPreview = !_showPreview),
              child: _showPreview
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        height: 360,
                        child: GoogleDrivePreview(webViewLink: item.webViewLink),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            const SizedBox(height: 16),
          ],
          _UploadFileSection(
            isUploading: _isUploading,
            onUpload: _handleUploadFile,
          ),
          const SizedBox(height: 16),
          _LazySectionCard(
            title: 'AI-аналіз документа',
            icon: Icons.auto_awesome,
            buttonLabel: _showAiAnalysis ? 'Сховати' : 'Запустити аналіз',
            onPressed: () => setState(() => _showAiAnalysis = !_showAiAnalysis),
            child: _showAiAnalysis
                ? _AiAnalysisCard(document: item)
                : const SizedBox.shrink(),
          ),
          const SizedBox(height: 16),
          _LazySectionCard(
            title: AppLocalizations.of(context)?.qrValidationTitle ?? 'QR validation code',
            icon: Icons.qr_code_scanner,
            buttonLabel: _showQrCode ? 'Сховати QR' : 'Показати QR',
            onPressed: () => setState(() => _showQrCode = !_showQrCode),
            child: _showQrCode
                ? QRCodeWidget(
                    document: item,
                    currentUserName:
                        FirebaseAuth.instance.currentUser?.displayName ?? 'User',
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _LazySectionCard extends StatelessWidget {
  const _LazySectionCard({
    required this.title,
    required this.icon,
    required this.buttonLabel,
    required this.onPressed,
    required this.child,
  });

  final String title;
  final IconData icon;
  final String buttonLabel;
  final VoidCallback onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: colorScheme.primary, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: onPressed,
                  child: Text(buttonLabel),
                ),
              ],
            ),
            if (child is! SizedBox) ...[
              const SizedBox(height: 12),
              child,
            ],
          ],
        ),
      ),
    );
  }
}

class _AiAnalysisCard extends StatefulWidget {
  const _AiAnalysisCard({required this.document});

  final DocumentListItem document;

  @override
  State<_AiAnalysisCard> createState() => _AiAnalysisCardState();
}

class _AiAnalysisCardState extends State<_AiAnalysisCard> {
  String? _result;
  bool _loading = false;
  String? _error;

  Future<void> _analyse() async {
    setState(() { _loading = true; _error = null; _result = null; });
    try {
      final token = await FirebaseAuth.instance.currentUser?.getIdToken();
      final doc = widget.document;

        final approvalSteps = doc.approvalFlow.steps.isEmpty
            ? 'немає'
            : doc.approvalFlow.steps.map((s) =>
                '${s.stepOrder}. ${s.approverName} (${s.approverEmail}) — ${s.status.name}'
              ).join('\n');

      final prompt = '''
Проаналізуй цей документ і надай короткий звіт у вигляді ПРОСТОГО ТЕКСТУ (без JSON, без фігурних дужок, без лапок):

Назва: ${doc.title}
Автор: ${doc.authorName}
Статус: ${doc.status.name}
Дата створення: ${doc.createdAt?.toLocal().toString().split(' ').first ?? 'невідомо'}
Тип файлу: ${doc.fileType.isEmpty ? 'невідомо' : doc.fileType}
Кроки погодження:\n$approvalSteps

Надай ТЕКСТОМ (не JSON):
📋 Короткий опис: (1-2 речення про що документ)
📊 Стан погодження: (поточний стан)
➡️ Наступний крок: (що потрібно зробити)
⚠️ Ризики: (важливі моменти або "відсутні")

Пиши звичайним текстом українською мовою.''';

      final service = AiChatService(baseUrl: ApiConfig.baseUrl);
      final response = await service.send(
        AiChatRequest(
          systemPrompt: 'Ти помічник для аналізу документів в системі документообігу. Відповідай українською мовою.',
          input: prompt,
        ),
        bearerToken: token,
      );
      if (mounted) setState(() { _result = _parseAiResponse(response.content); _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  String _parseAiResponse(String raw) {
    final trimmed = raw.trim();

    // First try to decode JSON-like structures safely
    try {
      final decoded = jsonDecode(trimmed);
      dynamic node = decoded;
      if (node is List && node.isNotEmpty) node = node.first;
      if (node is Map) {
        // Common shapes: {"content": {...}} or {"response":"..."}
        final inner = node['content'] ?? node;
        if (inner is String) return inner.trim();
        if (inner is Map) {
          if (inner.containsKey('response') && inner['response'] is String) {
            return inner['response'].toString().trim();
          }
          // Try to extract known keys from map
          final buf = StringBuffer();
          final labels = {
            'короткий_опис': '📋 Короткий опис',
            'короткийопис': '📋 Короткий опис',
            'description': '📋 Короткий опис',
            'поточний_стан': '📊 Стан погодження',
            'станпогодження': '📊 Стан погодження',
            'status': '📊 Стан погодження',
            'наступний_крок': '➡️ Наступний крок',
            'next_step': '➡️ Наступний крок',
            'ризики': '⚠️ Ризики',
            'risks': '⚠️ Ризики',
          };
          inner.forEach((k, v) {
            final nk = k.toString().toLowerCase().replaceAll(RegExp(r'[\s_-]'), '');
            final label = labels[nk];
            if (label != null && v != null) {
              buf.writeln('$label:');
              buf.writeln(v.toString());
              buf.writeln();
            }
          });
          if (buf.isNotEmpty) return buf.toString().trim();
        }
      }
    } catch (_) {
      // ignore and try regex-based fallbacks below
    }

    // Regex: extract all "key": "value" or key: "value" pairs (quoted or unquoted keys)
    final pairRegex = RegExp(r'''["']?([\w\u0400-\u04FF_\- ]+)["']?\s*:\s*["']([^"']+)["']''', multiLine: true);
    final matches = pairRegex.allMatches(trimmed).toList();

    if (matches.isNotEmpty) {
      // Map normalized key -> value
      String norm(String s) => s.toLowerCase().replaceAll(RegExp(r'[\s_\-]'), '');
      final extracted = <String, String>{};
      for (final m in matches) {
        final k = norm(m.group(1) ?? '');
        final v = (m.group(2) ?? '').trim();
        if (k.isNotEmpty && v.isNotEmpty) extracted[k] = v;
      }

      final fields = [
        {'label': '📋 Короткий опис',    'keys': ['description', 'короткийопис', 'shortdescription']},
        {'label': '📊 Стан погодження',  'keys': ['approvalstatus', 'статус', 'status', 'поточнийстан', 'станпогодження']},
        {'label': '➡️ Наступний крок',   'keys': ['nextstep', 'наступнийкрок']},
        {'label': '⚠️ Ризики',           'keys': ['risks', 'ризики']},
      ];

      final buf = StringBuffer();
      for (final f in fields) {
        String? val;
        for (final k in (f['keys'] as List<String>)) {
          if (extracted.containsKey(k)) { val = extracted[k]; break; }
        }
        if (val != null && val.isNotEmpty) {
          buf.writeln('${f['label']}:');
          buf.writeln(val);
          buf.writeln();
        }
      }

      if (buf.isNotEmpty) return buf.toString().trim();
      // fallback: print all extracted
      for (final e in extracted.entries) {
        buf.writeln('${e.key}: ${e.value}');
      }
      return buf.toString().trim();
    }

    // Additional regex fallback: try to find a response value inside malformed JSON
    try {
      final respRe = RegExp(r'''response['"]?\s*[:=]\s*['"]([\s\S]*?)['"]''', caseSensitive: false);
      final m = respRe.firstMatch(trimmed);
      if (m != null) return m.group(1)!.trim();

      final contentRe = RegExp(r'content\s*:\s*\{([\s\S]*?)\}', caseSensitive: false);
      final mc = contentRe.firstMatch(trimmed);
      if (mc != null) {
        var inside = mc.group(1)!.trim();
        inside = inside.replaceAll(RegExp(r'''["'\\]'''), '');
        return inside.trim();
      }
    } catch (_) {}

    return trimmed;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.auto_awesome, color: colorScheme.primary, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'AI-аналіз документа',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (_result != null && !_loading)
                  IconButton(
                    icon: const Icon(Icons.refresh_outlined, size: 18),
                    tooltip: 'Оновити аналіз',
                    onPressed: _analyse,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 10),
                      Text('AI аналізує документ…'),
                    ],
                  ),
                ),
              )
            else if (_error != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Не вдалося отримати аналіз',
                    style: TextStyle(color: colorScheme.error, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _analyse,
                      icon: const Icon(Icons.refresh_outlined, size: 16),
                      label: const Text('Спробувати знову'),
                    ),
                  ),
                ],
              )
            else if (_result != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                child: Text(
                  _result!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonalIcon(
                  onPressed: _analyse,
                  icon: const Icon(Icons.auto_awesome, size: 16),
                  label: const Text('Аналізувати документ'),
                ),
              ),
          ],
        ),
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
