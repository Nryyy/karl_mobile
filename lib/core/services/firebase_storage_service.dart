import 'dart:io';
import 'dart:developer' as developer;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service for uploading and managing files in Firebase Storage
class FirebaseStorageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Upload an image file to Firebase Storage
  Future<String> uploadImage({
    required File imageFile,
    required String folder,
    String? customFileName,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final fileName =
          customFileName ??
          '${DateTime.now().millisecondsSinceEpoch}_${imageFile.path.split('/').last}';

      final ref = _storage.ref().child('$folder/${user.uid}/$fileName');

      final uploadTask = await ref.putFile(imageFile);
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      developer.log(
        'Image uploaded successfully: $downloadUrl',
        name: 'karl.storage',
      );
      return downloadUrl;
    } catch (e) {
      developer.log(
        'Failed to upload image: $e',
        name: 'karl.storage',
        error: e,
      );
      throw Exception('Failed to upload image: $e');
    }
  }
}
