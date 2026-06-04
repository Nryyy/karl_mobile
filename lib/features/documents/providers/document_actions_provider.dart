import 'dart:developer' as developer;
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/documents_repository.dart';
import '../domain/document_models.dart';

// Provider for DocumentsRepository
final documentsRepositoryProvider = Provider<DocumentsRepository>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    throw StateError('User not authenticated');
  }
  return HttpDocumentsRepository(accessTokenProvider: () => user.getIdToken());
});

// Provider for current user profile
final currentUserProvider = FutureProvider<UserProfile>((ref) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    throw StateError('User not authenticated');
  }

  final repository = ref.read(documentsRepositoryProvider);
  return repository.fetchCurrentUser(user.email ?? '');
});

// Provider for document creation actions
class DocumentActionsNotifier extends AsyncNotifier<void> {
  late DocumentsRepository _repository;

  @override
  Future<void> build() async {
    _repository = ref.read(documentsRepositoryProvider);
  }

  Future<String> createDocument({
    required String title,
    required String authorId,
    required String authorName,
    String? statusId,
    String? statusName,
    String? fileType,
    String? organizationId,
    List<CreateApprovalStep>? approvalSteps,
  }) async {
    state = const AsyncValue.loading();

    try {
      final documentId = await _repository.createDocument(
        title: title,
        authorId: authorId,
        authorName: authorName,
        statusId: statusId,
        statusName: statusName,
        fileType: fileType,
        organizationId: organizationId,
        approvalSteps: approvalSteps,
      );

      state = const AsyncValue.data(null);
      developer.log(
        'Document created successfully: $documentId',
        name: 'karl.documents',
      );

      return documentId;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      developer.log(
        'Failed to create document: $e',
        name: 'karl.documents',
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  Future<void> deleteDocument(
    String documentId, {
    bool permanent = false,
  }) async {
    state = const AsyncValue.loading();

    try {
      await _repository.deleteDocument(documentId, permanent: permanent);
      state = const AsyncValue.data(null);
      developer.log(
        'Document deleted successfully: $documentId',
        name: 'karl.documents',
      );
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      developer.log(
        'Failed to delete document: $e',
        name: 'karl.documents',
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  Future<void> archiveDocument(String documentId) async {
    state = const AsyncValue.loading();

    try {
      await _repository.archiveDocument(documentId);
      state = const AsyncValue.data(null);
      developer.log(
        'Document archived successfully: $documentId',
        name: 'karl.documents',
      );
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      developer.log(
        'Failed to archive document: $e',
        name: 'karl.documents',
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  Future<void> restoreDocument(String documentId) async {
    state = const AsyncValue.loading();

    try {
      await _repository.restoreDocument(documentId);
      state = const AsyncValue.data(null);
      developer.log(
        'Document restored successfully: $documentId',
        name: 'karl.documents',
      );
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      developer.log(
        'Failed to restore document: $e',
        name: 'karl.documents',
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  Future<UploadDocumentFileResponse> uploadDocumentFile({
    required String documentId,
    required Uint8List fileBytes,
    required String fileName,
  }) async {
    state = const AsyncValue.loading();

    try {
      final response = await _repository.uploadDocumentFile(
        documentId: documentId,
        fileBytes: fileBytes,
        fileName: fileName,
      );
      state = const AsyncValue.data(null);
      developer.log(
        'Document file uploaded successfully: $documentId',
        name: 'karl.documents',
      );
      return response;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      developer.log(
        'Failed to upload document file: $e',
        name: 'karl.documents',
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }
}

final documentActionsProvider =
    AsyncNotifierProvider<DocumentActionsNotifier, void>(
      DocumentActionsNotifier.new,
    );

// Provider for document signing actions
class DocumentSigningNotifier extends AsyncNotifier<void> {
  late DocumentsRepository _repository;

  @override
  Future<void> build() async {
    _repository = ref.read(documentsRepositoryProvider);
  }

  Future<void> signDocument({
    required String documentId,
    required String userName,
    required String userEmail,
  }) async {
    try {
      await _repository.signDocument(
        documentId: documentId,
        userName: userName,
        userEmail: userEmail,
      );
      developer.log(
        'Document signed successfully: $documentId',
        name: 'karl.documents',
      );
    } catch (e, stack) {
      developer.log(
        'Failed to sign document: $e',
        name: 'karl.documents',
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  Future<void> rejectDocument({
    required String documentId,
    required String userName,
    required String userEmail,
    String? comment,
  }) async {
    try {
      await _repository.rejectDocument(
        documentId: documentId,
        userName: userName,
        userEmail: userEmail,
        comment: comment,
      );
      developer.log(
        'Document rejected successfully: $documentId',
        name: 'karl.documents',
      );
    } catch (e, stack) {
      developer.log(
        'Failed to reject document: $e',
        name: 'karl.documents',
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }
}

final documentSigningProvider =
    AsyncNotifierProvider<DocumentSigningNotifier, void>(
      DocumentSigningNotifier.new,
    );
