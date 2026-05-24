import 'package:flutter/foundation.dart';

/// Represents a document returned by the documents API.
@immutable
class DocumentListItem {
  /// Creates a document list item.
  const DocumentListItem({
    required this.id,
    required this.title,
    required this.authorId,
    required this.authorName,
    required this.status,
    required this.fileType,
    required this.googleDriveFileId,
    required this.webViewLink,
    required this.webContentLink,
    required this.createdAt,
    required this.updatedAt,
    required this.signatures,
    required this.comments,
    required this.approvalFlow,
    required this.metadata,
  });

  /// Unique document identifier.
  final String id;

  /// Document title.
  final String title;

  /// Identifier of the author.
  final String authorId;

  /// Display name of the author.
  final String authorName;

  /// Current status of the document.
  final DocumentStatus status;

  /// File type reported by the API.
  final String fileType;

  /// Google Drive file identifier.
  final String googleDriveFileId;

  /// Link for Google Drive web preview.
  final String webViewLink;

  /// Link for Google Drive web content.
  final String webContentLink;

  /// Time when the document was created.
  final DateTime? createdAt;

  /// Time when the document was last updated.
  final DateTime? updatedAt;

  /// Signatures attached to the document.
  final List<DocumentSignature> signatures;

  /// Comments attached to the document.
  final List<DocumentComment> comments;

  /// Approval flow information.
  final ApprovalFlow approvalFlow;

  /// Additional document metadata.
  final DocumentMetadata metadata;

  /// Creates a document list item from JSON.
  factory DocumentListItem.fromJson(Map<String, dynamic> json) {
    return DocumentListItem(
      id: _readString(json['id']),
      title: _readString(json['title']),
      authorId: _readString(json['authorId']),
      authorName: _readString(json['authorName']),
      status: DocumentStatus.fromJson(_readMap(json['status'])),
      fileType: _readString(json['fileType']),
      googleDriveFileId: _readString(json['googleDriveFileId']),
      webViewLink: _readString(json['webViewLink']),
      webContentLink: _readString(json['webContentLink']),
      createdAt: _readDateTime(json['createdAt']),
      updatedAt: _readDateTime(json['updatedAt']),
      signatures: _readList(json['signatures'])
          .map((value) => DocumentSignature.fromJson(_readMap(value)))
          .toList(growable: false),
      comments: _readList(json['comments'])
          .map((value) => DocumentComment.fromJson(_readMap(value)))
          .toList(growable: false),
      approvalFlow: ApprovalFlow.fromJson(_readMap(json['approvalFlow'])),
      metadata: DocumentMetadata.fromJson(_readMap(json['metadata'])),
    );
  }
}

/// Represents a document status.
@immutable
class DocumentStatus {
  /// Creates a document status.
  const DocumentStatus({required this.id, required this.name});

  /// Status identifier.
  final String id;

  /// Human-readable status name.
  final String name;

  /// Creates a document status from JSON.
  factory DocumentStatus.fromJson(Map<String, dynamic> json) {
    return DocumentStatus(
      id: _readString(json['id']),
      name: _readString(json['name']),
    );
  }
}

/// Represents a document signature.
@immutable
class DocumentSignature {
  /// Creates a document signature.
  const DocumentSignature({
    required this.id,
    required this.userId,
    required this.userName,
    required this.signatureType,
    required this.signedAt,
  });

  /// Signature identifier.
  final String id;

  /// User identifier.
  final String userId;

  /// Display name of the signer.
  final String userName;

  /// Signature type reported by the API.
  final String signatureType;

  /// Time when the signature was added.
  final DateTime? signedAt;

  /// Creates a document signature from JSON.
  factory DocumentSignature.fromJson(Map<String, dynamic> json) {
    return DocumentSignature(
      id: _readString(json['id']),
      userId: _readString(json['userId']),
      userName: _readString(json['userName']),
      signatureType: _readString(json['signatureType']),
      signedAt: _readDateTime(json['signedAt']),
    );
  }
}

/// Represents a document comment.
@immutable
class DocumentComment {
  /// Creates a document comment.
  const DocumentComment({
    required this.id,
    required this.userId,
    required this.userName,
    required this.comment,
    required this.createdAt,
    required this.editedAt,
  });

  /// Comment identifier.
  final String id;

  /// User identifier.
  final String userId;

  /// Display name of the commenter.
  final String userName;

  /// Comment content.
  final String comment;

  /// Time when the comment was created.
  final DateTime? createdAt;

  /// Time when the comment was last edited.
  final DateTime? editedAt;

  /// Creates a document comment from JSON.
  factory DocumentComment.fromJson(Map<String, dynamic> json) {
    return DocumentComment(
      id: _readString(json['id']),
      userId: _readString(json['userId']),
      userName: _readString(json['userName']),
      comment: _readString(json['comment']),
      createdAt: _readDateTime(json['createdAt']),
      editedAt: _readDateTime(json['editedAt']),
    );
  }
}

/// Represents the approval flow of a document.
@immutable
class ApprovalFlow {
  /// Creates an approval flow.
  const ApprovalFlow({
    required this.isActive,
    required this.steps,
    required this.currentStep,
  });

  /// Whether the flow is currently active.
  final bool isActive;

  /// Approval steps.
  final List<ApprovalStep> steps;

  /// Current step index.
  final int currentStep;

  /// Creates an approval flow from JSON.
  factory ApprovalFlow.fromJson(Map<String, dynamic> json) {
    return ApprovalFlow(
      isActive: _readBool(json['isActive']),
      steps: _readList(json['steps'])
          .map((value) => ApprovalStep.fromJson(_readMap(value)))
          .toList(growable: false),
      currentStep: _readInt(json['currentStep']),
    );
  }
}

/// Represents a single approval step.
@immutable
class ApprovalStep {
  /// Creates an approval step.
  const ApprovalStep({
    required this.stepOrder,
    required this.approverId,
    required this.approverName,
    required this.approverEmail,
    required this.status,
    required this.actionAt,
    required this.comment,
  });

  /// Step order.
  final int stepOrder;

  /// Approver identifier.
  final String approverId;

  /// Approver display name.
  final String approverName;

  /// Approver email.
  final String approverEmail;

  /// Step status.
  final DocumentStatus status;

  /// Action timestamp.
  final DateTime? actionAt;

  /// Optional step comment.
  final String comment;

  /// Creates an approval step from JSON.
  factory ApprovalStep.fromJson(Map<String, dynamic> json) {
    return ApprovalStep(
      stepOrder: _readInt(json['stepOrder']),
      approverId: _readString(json['approverId']),
      approverName: _readString(json['approverName']),
      approverEmail: _readString(json['approverEmail']),
      status: DocumentStatus.fromJson(_readMap(json['status'])),
      actionAt: _readDateTime(json['actionAt']),
      comment: _readString(json['comment']),
    );
  }
}

/// Represents additional metadata for a document.
@immutable
class DocumentMetadata {
  /// Creates document metadata.
  const DocumentMetadata({
    required this.version,
    required this.tags,
    required this.category,
    required this.fileSize,
    required this.pageCount,
  });

  /// Document version.
  final int version;

  /// Document tags.
  final List<String> tags;

  /// Document category.
  final String category;

  /// File size in bytes.
  final int fileSize;

  /// Page count.
  final int pageCount;

  /// Creates document metadata from JSON.
  factory DocumentMetadata.fromJson(Map<String, dynamic> json) {
    return DocumentMetadata(
      version: _readInt(json['version']),
      tags: _readList(json['tags'])
          .map(_readString)
          .where((value) => value.isNotEmpty)
          .toList(growable: false),
      category: _readString(json['category']),
      fileSize: _readInt(json['fileSize']),
      pageCount: _readInt(json['pageCount']),
    );
  }
}

Map<String, dynamic> _readMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }
  return <String, dynamic>{};
}

List<dynamic> _readList(dynamic value) {
  if (value is List) {
    return value;
  }
  return const <dynamic>[];
}

String _readString(dynamic value) => value?.toString() ?? '';

bool _readBool(dynamic value) => value is bool ? value : false;

int _readInt(dynamic value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value) ?? 0;
  }
  return 0;
}

DateTime? _readDateTime(dynamic value) {
  if (value is DateTime) {
    return value;
  }
  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value);
  }
  return null;
}
