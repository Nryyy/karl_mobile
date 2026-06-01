import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// QR validation data model for document verification
class QRValidationData {
  final String documentId;
  final String documentTitle;
  final String qrCode;
  final String generatedBy;
  final DateTime generatedAt;
  final DateTime? validatedAt;
  final String? validatedBy;
  final bool isValid;
  final String? validationNotes;

  QRValidationData({
    required this.documentId,
    required this.documentTitle,
    required this.qrCode,
    required this.generatedBy,
    required this.generatedAt,
    this.validatedAt,
    this.validatedBy,
    this.isValid = false,
    this.validationNotes,
  });

  Map<String, dynamic> toJson() {
    return {
      'documentId': documentId,
      'documentTitle': documentTitle,
      'qrCode': qrCode,
      'generatedBy': generatedBy,
      'generatedAt': generatedAt.toIso8601String(),
      'validatedAt': validatedAt?.toIso8601String(),
      'validatedBy': validatedBy,
      'isValid': isValid,
      'validationNotes': validationNotes,
    };
  }

  factory QRValidationData.fromJson(Map<String, dynamic> json) {
    return QRValidationData(
      documentId: json['documentId'] as String,
      documentTitle: json['documentTitle'] as String,
      qrCode: json['qrCode'] as String,
      generatedBy: json['generatedBy'] as String,
      generatedAt: DateTime.parse(json['generatedAt'] as String),
      validatedAt: json['validatedAt'] != null
          ? DateTime.parse(json['validatedAt'] as String)
          : null,
      validatedBy: json['validatedBy'] as String?,
      isValid: json['isValid'] as bool? ?? false,
      validationNotes: json['validationNotes'] as String?,
    );
  }
}

/// Firestore service for QR code validation and document verification
class FirestoreQRService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Collection reference for QR validations
  CollectionReference get _qrCollection =>
      _firestore.collection('qr_validations');

  /// Generate a unique QR code for document verification
  String _generateQRCode(String documentId, String userId) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '$documentId:$userId:$timestamp';
  }

  /// Create QR validation record for a document (CREATE)
  Future<String> createQRValidation({
    required String documentId,
    required String documentTitle,
    required String generatedBy,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final qrCode = _generateQRCode(documentId, user.uid);
      final validationData = QRValidationData(
        documentId: documentId,
        documentTitle: documentTitle,
        qrCode: qrCode,
        generatedBy: generatedBy,
        generatedAt: DateTime.now(),
      );

      final docRef = await _qrCollection.add(validationData.toJson());

      developer.log('QR validation created: ${docRef.id}', name: 'karl.qr');
      return docRef.id;
    } catch (e) {
      developer.log(
        'Failed to create QR validation: $e',
        name: 'karl.qr',
        error: e,
      );
      throw Exception('Failed to create QR validation: $e');
    }
  }

  /// Get QR validation by document ID (READ)
  Future<QRValidationData?> getQRValidationByDocumentId(
    String documentId,
  ) async {
    try {
      final query = await _qrCollection
          .where('documentId', isEqualTo: documentId)
          .orderBy('generatedAt', descending: true)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        return null;
      }

      final doc = query.docs.first;
      return QRValidationData.fromJson(doc.data() as Map<String, dynamic>);
    } catch (e) {
      developer.log(
        'Failed to get QR validation: $e',
        name: 'karl.qr',
        error: e,
      );
      throw Exception('Failed to get QR validation: $e');
    }
  }

  /// Validate QR code and update record (UPDATE)
  Future<void> validateQRCode({
    required String qrCode,
    required String validatedBy,
    String? validationNotes,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final query = await _qrCollection
          .where('qrCode', isEqualTo: qrCode)
          .where('isValid', isEqualTo: false)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        throw Exception('QR code not found or already validated');
      }

      final doc = query.docs.first;
      await doc.reference.update({
        'isValid': true,
        'validatedAt': DateTime.now().toIso8601String(),
        'validatedBy': validatedBy,
        'validationNotes': validationNotes,
      });

      developer.log('QR code validated: ${doc.id}', name: 'karl.qr');
    } catch (e) {
      developer.log(
        'Failed to validate QR code: $e',
        name: 'karl.qr',
        error: e,
      );
      throw Exception('Failed to validate QR code: $e');
    }
  }

  /// Real-time stream for QR validation updates (REAL-TIME)
  Stream<List<QRValidationData>> getQRValidationStream(String documentId) {
    return _qrCollection
        .where('documentId', isEqualTo: documentId)
        .orderBy('generatedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => QRValidationData.fromJson(
                  doc.data() as Map<String, dynamic>,
                ),
              )
              .toList(),
        );
  }

  /// Real-time stream for all user QR validations
  Stream<List<QRValidationData>> getUserQRValidationStream() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return _qrCollection
        .where('generatedBy', isEqualTo: user.uid)
        .orderBy('generatedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => QRValidationData.fromJson(
                  doc.data() as Map<String, dynamic>,
                ),
              )
              .toList(),
        );
  }
}
