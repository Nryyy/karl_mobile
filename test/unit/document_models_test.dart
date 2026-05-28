import 'package:flutter_test/flutter_test.dart';
import 'package:karl_mobile/features/documents/domain/document_models.dart';

void main() {
  test('DocumentStatus.fromJson parses id and name', () {
    final json = {'id': 'st1', 'name': 'Pending'};
    final status = DocumentStatus.fromJson(json);
    expect(status.id, 'st1');
    expect(status.name, 'Pending');
  });

  test('DocumentMetadata.fromJson parses tags and fileSize', () {
    final json = {
      'version': 1,
      'tags': ['a', 'b'],
      'category': 'general',
      'fileSize': 2048,
      'pageCount': 3,
    };
    final meta = DocumentMetadata.fromJson(json);
    expect(meta.version, 1);
    expect(meta.tags, ['a', 'b']);
    expect(meta.fileSize, 2048);
    expect(meta.pageCount, 3);
  });

  test('DocumentListItem.fromJson constructs nested objects', () {
    final json = {
      'id': 'd1',
      'title': 'Doc',
      'authorId': 'u1',
      'authorName': 'User',
      'status': {'id': 's1', 'name': 'New'},
      'fileType': 'pdf',
      'googleDriveFileId': 'g1',
      'webViewLink': 'http://',
      'webContentLink': 'http://',
      'createdAt': '2020-01-01T12:00:00Z',
      'updatedAt': null,
      'signatures': [],
      'comments': [],
      'approvalFlow': {'isActive': false, 'steps': [], 'currentStep': 0},
      'metadata': {'version': 1, 'tags': [], 'category': '', 'fileSize': 0, 'pageCount': 0},
    };
    final item = DocumentListItem.fromJson(json);
    expect(item.id, 'd1');
    expect(item.title, 'Doc');
    expect(item.status.name, 'New');
    expect(item.createdAt?.toUtc().year, 2020);
  });

  test('UploadDocumentFileResponse.fromJson parses fields', () {
    final json = {
      'documentId': 'doc1',
      'googleDriveFileId': 'g1',
      'webViewLink': 'v',
      'webContentLink': 'c',
      'fileSize': 12345,
    };
    final resp = UploadDocumentFileResponse.fromJson(json);
    expect(resp.documentId, 'doc1');
    expect(resp.fileSize, 12345);
  });

  test('CreateApprovalStep.toJson round-trips expected fields', () {
    final step = CreateApprovalStep(stepOrder: 1, approverId: 'a', approverName: 'A', approverEmail: 'a@x.com');
    final json = step.toJson();
    expect(json['stepOrder'], 1);
    expect(json['approverEmail'], 'a@x.com');
  });
}
