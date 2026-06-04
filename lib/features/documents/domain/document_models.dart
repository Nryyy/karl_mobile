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

  /// Converts to JSON map.
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'authorId': authorId,
    'authorName': authorName,
    'status': status.toJson(),
    'fileType': fileType,
    'googleDriveFileId': googleDriveFileId,
    'webViewLink': webViewLink,
    'webContentLink': webContentLink,
    'createdAt': createdAt?.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
    'signatures': signatures.map((s) => s.toJson()).toList(),
    'comments': comments.map((c) => c.toJson()).toList(),
    'approvalFlow': approvalFlow.toJson(),
    'metadata': metadata.toJson(),
  };
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

  /// Converts to JSON map.
  Map<String, dynamic> toJson() => {'id': id, 'name': name};

  @override
  bool operator ==(Object other) => other is DocumentStatus && other.id == id;

  @override
  int get hashCode => id.hashCode;
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

  /// Converts to JSON map.
  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'userName': userName,
    'signatureType': signatureType,
    'signedAt': signedAt?.toIso8601String(),
  };
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

  /// Converts to JSON map.
  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'userName': userName,
    'comment': comment,
    'createdAt': createdAt?.toIso8601String(),
    'editedAt': editedAt?.toIso8601String(),
  };
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

  /// Converts to JSON map.
  Map<String, dynamic> toJson() => {
    'isActive': isActive,
    'steps': steps.map((s) => s.toJson()).toList(),
    'currentStep': currentStep,
  };
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

  /// Converts to JSON map.
  Map<String, dynamic> toJson() => {
    'stepOrder': stepOrder,
    'approverId': approverId,
    'approverName': approverName,
    'approverEmail': approverEmail,
    'status': status.toJson(),
    'actionAt': actionAt?.toIso8601String(),
    'comment': comment,
  };
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

  /// Converts to JSON map.
  Map<String, dynamic> toJson() => {
    'version': version,
    'tags': tags,
    'category': category,
    'fileSize': fileSize,
    'pageCount': pageCount,
  };
}

/// Represents a user profile returned by the users API.
@immutable
class UserProfile {
  /// Creates a user profile.
  const UserProfile({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    required this.organizationId,
    required this.organizationName,
  });

  /// User identifier.
  final String id;

  /// User email.
  final String email;

  /// Display name.
  final String fullName;

  /// User role.
  final String role;

  /// Organization identifier.
  final String organizationId;

  /// Organization name.
  final String organizationName;

  /// Creates a user profile from JSON.
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: _readString(json['id']),
      email: _readString(json['email']),
      fullName: _readString(json['fullName']),
      role: _readString(json['role']),
      organizationId: _readString(json['organizationId']),
      organizationName: _readString(json['organizationName']),
    );
  }

  /// Converts to JSON map.
  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'fullName': fullName,
    'role': role,
    'organizationId': organizationId,
    'organizationName': organizationName,
  };

  @override
  bool operator ==(Object other) => other is UserProfile && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// Represents a single approval step for document creation.
@immutable
class CreateApprovalStep {
  /// Creates a create approval step.
  const CreateApprovalStep({
    required this.stepOrder,
    required this.approverId,
    required this.approverName,
    required this.approverEmail,
  });

  /// Step order (1-based).
  final int stepOrder;

  /// Approver user identifier.
  final String approverId;

  /// Approver display name.
  final String approverName;

  /// Approver email.
  final String approverEmail;

  /// Converts to JSON map.
  Map<String, dynamic> toJson() => {
    'stepOrder': stepOrder,
    'approverId': approverId,
    'approverName': approverName,
    'approverEmail': approverEmail,
  };
}

/// Response returned after uploading a document file.
@immutable
class UploadDocumentFileResponse {
  /// Creates an upload document file response.
  const UploadDocumentFileResponse({
    required this.documentId,
    required this.googleDriveFileId,
    required this.webViewLink,
    required this.webContentLink,
    required this.fileSize,
  });

  /// Identifier of the document.
  final String documentId;

  /// Google Drive file identifier.
  final String googleDriveFileId;

  /// Link for Google Drive web preview.
  final String webViewLink;

  /// Link for Google Drive web content.
  final String webContentLink;

  /// File size in bytes.
  final int fileSize;

  /// Creates an upload response from JSON.
  factory UploadDocumentFileResponse.fromJson(Map<String, dynamic> json) {
    return UploadDocumentFileResponse(
      documentId: _readString(json['documentId']),
      googleDriveFileId: _readString(json['googleDriveFileId']),
      webViewLink: _readString(json['webViewLink']),
      webContentLink: _readString(json['webContentLink']),
      fileSize: _readInt(json['fileSize']),
    );
  }
}

/// Represents a document template returned by the API.
@immutable
class DocumentTemplate {
  /// Creates a document template.
  const DocumentTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.fileType,
    required this.originalFileName,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    required this.createdByName,
    required this.category,
    required this.organizationId,
    required this.webViewLink,
    required this.webContentLink,
  });

  /// Template identifier.
  final String id;

  /// Template name.
  final String name;

  /// Template description.
  final String description;

  /// File type (e.g. "docx", "pdf").
  final String fileType;

  /// Original file name.
  final String originalFileName;

  /// Whether the template is active.
  final bool isActive;

  /// Creation timestamp.
  final DateTime? createdAt;

  /// Last update timestamp.
  final DateTime? updatedAt;

  /// Creator display name.
  final String createdByName;

  /// Category.
  final String category;

  /// Organization identifier.
  final String organizationId;

  /// Google Drive web view link.
  final String webViewLink;

  /// Google Drive download link.
  final String webContentLink;

  /// Creates a template from JSON.
  factory DocumentTemplate.fromJson(Map<String, dynamic> json) {
    return DocumentTemplate(
      id: _readString(json['id']),
      name: _readString(json['name']),
      description: _readString(json['description']),
      fileType: _readString(json['fileType']),
      originalFileName: _readString(json['originalFileName']),
      isActive: _readBool(json['isActive']),
      createdAt: _readDateTime(json['createdAt']),
      updatedAt: _readDateTime(json['updatedAt']),
      createdByName: _readString(json['createdByName']),
      category: _readString(json['category']),
      organizationId: _readString(json['organizationId']),
      webViewLink: _readString(json['webViewLink']),
      webContentLink: _readString(json['webContentLink']),
    );
  }
}

/// Notification from the backend.
@immutable
class AppNotification {
  /// Creates a notification.
  const AppNotification({
    required this.id,
    required this.userId,
    required this.message,
    required this.type,
    required this.statusName,
    required this.relatedDocumentId,
    required this.relatedDocumentTitle,
    required this.priority,
    required this.createdAt,
    required this.readAt,
  });

  /// Notification identifier.
  final String id;

  /// Owner user identifier.
  final String userId;

  /// Notification message.
  final String message;

  /// Notification type.
  final String type;

  /// Status name (e.g. "unread", "read").
  final String statusName;

  /// Related document identifier.
  final String relatedDocumentId;

  /// Related document title.
  final String relatedDocumentTitle;

  /// Priority (e.g. "high", "normal").
  final String priority;

  /// Creation timestamp.
  final DateTime? createdAt;

  /// Read timestamp (null if unread).
  final DateTime? readAt;

  /// Whether this notification has been read.
  bool get isRead => readAt != null;

  /// Creates a notification from JSON.
  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final statusMap = _readMap(json['status']);
    final relatedDoc = _readMap(json['relatedDocument']);
    return AppNotification(
      id: _readString(json['id']),
      userId: _readString(json['userId']),
      message: _readString(json['message']),
      type: _readString(json['type']),
      statusName: _readString(statusMap['name']),
      relatedDocumentId: _readString(relatedDoc['documentId']),
      relatedDocumentTitle: _readString(relatedDoc['documentTitle']),
      priority: _readString(json['priority']),
      createdAt: _readDateTime(json['createdAt']),
      readAt: _readDateTime(json['readAt']),
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
