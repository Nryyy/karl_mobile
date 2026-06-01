import 'document_models.dart';
import '../../../core/utils/document_utils.dart';

/// Returns documents that belong to the current user or were sent to them.
List<DocumentListItem> mergeVisibleDocuments({
  required String currentUserId,
  required List<DocumentListItem> allDocuments,
  required List<DocumentListItem> sentToMe,
}) {
  final visibleIds = <String>{};
  final visibleDocuments = <DocumentListItem>[];

  for (final document in allDocuments) {
    if (document.authorId != currentUserId) {
      continue;
    }

    if (visibleIds.add(document.id)) {
      visibleDocuments.add(document);
    }
  }

  for (final document in sentToMe) {
    if (visibleIds.add(document.id)) {
      visibleDocuments.add(document);
    }
  }

  return visibleDocuments;
}

/// Returns true when the current approval step is pending for the user.
bool isPendingApprovalForUser(DocumentListItem document, String currentUserId) {
  if (currentUserId.isEmpty) return false;

  final flow = document.approvalFlow;
  if (!flow.isActive || flow.steps.isEmpty) {
    return false;
  }

  final myStep = flow.steps
      .where((step) => step.approverId == currentUserId)
      .firstOrNull;
  if (myStep == null) {
    return false;
  }

  final statusId = myStep.status.id.toLowerCase();
  final statusName = myStep.status.name.toLowerCase();
  final isPending =
      statusId == 'pending' ||
      statusName.contains('pending') ||
      statusName.contains('очіку');
  if (!isPending) {
    return false;
  }

  return myStep.stepOrder == flow.currentStep ||
      myStep.stepOrder == flow.currentStep + 1;
}

/// Returns true when the document has an approved or completed status.
bool isApprovedDocument(DocumentListItem document) {
  return matchesStatus(document.status.name, const <String>[
    'затвер',
    'approve',
    'signed',
    'done',
  ]);
}

/// Returns true when the document was created during the last [days] days.
bool isRecentDocument(DocumentListItem document, {int days = 7}) {
  final createdAt = document.createdAt;
  if (createdAt == null) return false;

  final threshold = DateTime.now().toUtc().subtract(Duration(days: days));
  return createdAt.toUtc().isAfter(threshold);
}
