import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/services/firestore_qr_service.dart';
import '../generated/app_localizations.dart';
import '../features/documents/domain/document_models.dart';

/// Widget for generating and displaying QR codes for document validation
class QRCodeWidget extends ConsumerStatefulWidget {
  final DocumentListItem document;
  final String currentUserName;

  const QRCodeWidget({
    super.key,
    required this.document,
    required this.currentUserName,
  });

  @override
  ConsumerState<QRCodeWidget> createState() => _QRCodeWidgetState();
}

class _QRCodeWidgetState extends ConsumerState<QRCodeWidget> {
  final FirestoreQRService _qrService = FirestoreQRService();
  bool _isGenerating = false;
  bool _isSharing = false;
  QRValidationData? _qrValidationData;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadExistingQR();
      }
    });
  }

  Future<void> _loadExistingQR() async {
    try {
      final existingQR = await _qrService
          .getQRValidationByDocumentId(widget.document.id)
          .timeout(const Duration(seconds: 5));
      if (mounted) {
        setState(() {
          _qrValidationData = existingQR;
        });
      }
    } catch (e) {
      // silently ignore errors during load
    }
  }

  Future<void> _generateQRCode() async {
    setState(() => _isGenerating = true);

    try {
      await _qrService.createQRValidation(
        documentId: widget.document.id,
        documentTitle: widget.document.title,
        generatedBy: widget.currentUserName,
      );

      final qrData = await _qrService.getQRValidationByDocumentId(
        widget.document.id,
      );
      if (mounted) {
        setState(() {
          _qrValidationData = qrData;
          _isGenerating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGenerating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)?.qrCodeGenerationError(e.toString()) ?? 'QR code generation error: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _shareQRCode() async {
    setState(() => _isSharing = true);

    try {
      await Clipboard.setData(
        ClipboardData(text: _qrValidationData?.qrCode ?? ''),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)?.qrCodeCopied ?? 'QR code copied to clipboard'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)?.errorGeneric(e.toString()) ?? 'Error: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.qr_code_scanner,
                  color: colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  AppLocalizations.of(context)?.qrValidationTitle ?? 'QR validation code',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                if (_qrValidationData != null && _qrValidationData!.isValid)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          'Валідовано',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            if (_qrValidationData == null) ...[
              Text(
                AppLocalizations.of(context)?.qrValidationDescription ?? 'Generate a QR code to validate the document. This code can be used to verify the authenticity of the document.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _isGenerating ? null : _generateQRCode,
                  icon: _isGenerating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.qr_code_2),
                  label: Text(
                    _isGenerating ? 'Генерація...' : 'Згенерувати QR код',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: colorScheme.outline.withValues(alpha: 0.2),
                        ),
                      ),
                      child: _qrValidationData != null
                          ? Center(
                              child: QrImageView(
                                data: _qrValidationData!.qrCode,
                                version: QrVersions.auto,
                                size: 180.0,
                                backgroundColor: Colors.white,
                                eyeStyle: const QrEyeStyle(
                                  eyeShape: QrEyeShape.square,
                                  color: Colors.black,
                                ),
                                dataModuleStyle: const QrDataModuleStyle(
                                  dataModuleShape: QrDataModuleShape.square,
                                  color: Colors.black,
                                ),
                              ),
                            )
                          : Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.qr_code_2,
                                    size: 48,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    AppLocalizations.of(context)?.qrCodeLabel ?? 'QR code',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Створено:',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        _formatDateTime(_qrValidationData!.generatedAt),
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (_qrValidationData!.validatedAt != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Валідовано:',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          _formatDateTime(_qrValidationData!.validatedAt!),
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      SizedBox(
                        width: 120,
                        height: 36,
                        child: OutlinedButton.icon(
                          onPressed: _isSharing ? null : _shareQRCode,
                          icon: _isSharing
                              ? const SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.share, size: 16),
                          label: Text(
                            'Поділитись',
                            style: GoogleFonts.inter(fontSize: 12),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

/// Real-time QR validation status widget
class QRValidationStatusWidget extends ConsumerWidget {
  final String documentId;

  const QRValidationStatusWidget({super.key, required this.documentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final qrService = FirestoreQRService();

    return StreamBuilder<List<QRValidationData>>(
      stream: qrService.getQRValidationStream(documentId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }

        if (snapshot.hasError) {
          return Text(AppLocalizations.of(context)?.errorGeneric(snapshot.error?.toString() ?? '') ?? 'Error: ${snapshot.error}');
        }

        final validations = snapshot.data ?? [];
        if (validations.isEmpty) {
          return Text(AppLocalizations.of(context)?.noQrCodes ?? 'No QR codes');
        }

        final latestValidation = validations.first;

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: latestValidation.isValid
                ? Colors.green.withValues(alpha: 0.1)
                : Colors.orange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: latestValidation.isValid ? Colors.green : Colors.orange,
            ),
          ),
          child: Row(
            children: [
              Icon(
                latestValidation.isValid ? Icons.check_circle : Icons.pending,
                color: latestValidation.isValid ? Colors.green : Colors.orange,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  latestValidation.isValid
                      ? 'Документ валідовано ${_formatTime(latestValidation.validatedAt!)}'
                      : 'Очікує валідації',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: latestValidation.isValid
                        ? Colors.green
                        : Colors.orange,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'щойно';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} хв тому';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} год тому';
    } else {
      return '${difference.inDays} днів тому';
    }
  }
}
