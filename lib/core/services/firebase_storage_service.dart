import 'dart:io';
import 'dart:typed_data';
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

      final fileName = customFileName ?? 
          '${DateTime.now().millisecondsSinceEpoch}_${imageFile.path.split('/').last}';
      
      final ref = _storage.ref().child('$folder/${user.uid}/$fileName');
      
      final uploadTask = await ref.putFile(imageFile);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      
      developer.log('Image uploaded successfully: $downloadUrl', name: 'karl.storage');
      return downloadUrl;
    } catch (e) {
      developer.log('Failed to upload image: $e', name: 'karl.storage', error: e);
      throw Exception('Failed to upload image: $e');
    }
  }

  /// Upload image bytes to Firebase Storage
  Future<String> uploadImageBytes({
    required Uint8List imageBytes,
    required String fileName,
    required String folder,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final ref = _storage.ref().child('$folder/${user.uid}/$fileName');
      
      final uploadTask = await ref.putData(imageBytes);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      
      developer.log('Image bytes uploaded successfully: $downloadUrl', name: 'karl.storage');
      return downloadUrl;
    } catch (e) {
      developer.log('Failed to upload image bytes: $e', name: 'karl.storage', error: e);
      throw Exception('Failed to upload image bytes: $e');
    }
  }

  /// Delete an image from Firebase Storage
  Future<void> deleteImage({required String downloadUrl}) async {
    try {
      final ref = _storage.refFromURL(downloadUrl);
      await ref.delete();
      developer.log('Image deleted successfully: $downloadUrl', name: 'karl.storage');
    } catch (e) {
      developer.log('Failed to delete image: $e', name: 'karl.storage', error: e);
      throw Exception('Failed to delete image: $e');
    }
  }

  /// Get file metadata from Firebase Storage
  Future<FullMetadata> getFileMetadata({required String downloadUrl}) async {
    try {
      final ref = _storage.refFromURL(downloadUrl);
      return await ref.getMetadata();
    } catch (e) {
      developer.log('Failed to get file metadata: $e', name: 'karl.storage', error: e);
      throw Exception('Failed to get file metadata: $e');
    }
  }

  /// List all files in a folder for the current user
  Future<List<Reference>> listUserFiles({required String folder}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final ref = _storage.ref().child('$folder/${user.uid}');
      final result = await ref.listAll();
      
      return result.items;
    } catch (e) {
      developer.log('Failed to list user files: $e', name: 'karl.storage', error: e);
      throw Exception('Failed to list user files: $e');
    }
  }

  /// Get download URL for a file path
  Future<String> getDownloadUrl({required String path}) async {
    try {
      final ref = _storage.ref().child(path);
      return await ref.getDownloadURL();
    } catch (e) {
      developer.log('Failed to get download URL: $e', name: 'karl.storage', error: e);
      throw Exception('Failed to get download URL: $e');
    }
  }
}
