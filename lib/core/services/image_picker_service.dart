import 'dart:io';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';

/// Service for picking images from camera or gallery
class ImagePickerService {
  static final ImagePicker _imagePicker = ImagePicker();

  /// Pick image from camera
  Future<File?> pickImageFromCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );
      
      return image != null ? File(image.path) : null;
    } catch (e) {
      throw Exception('Failed to pick image from camera: $e');
    }
  }

  /// Pick image from gallery
  Future<File?> pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );
      
      return image != null ? File(image.path) : null;
    } catch (e) {
      throw Exception('Failed to pick image from gallery: $e');
    }
  }

  /// Pick multiple images from gallery
  Future<List<File>> pickMultipleImagesFromGallery() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );
      
      return images.map((image) => File(image.path)).toList();
    } catch (e) {
      throw Exception('Failed to pick multiple images from gallery: $e');
    }
  }

  /// Convert image file to bytes
  Future<Uint8List> imageToBytes(File imageFile) async {
    try {
      return await imageFile.readAsBytes();
    } catch (e) {
      throw Exception('Failed to convert image to bytes: $e');
    }
  }

  /// Get image file size in MB
  double getImageFileSize(File imageFile) {
    final bytes = imageFile.lengthSync();
    return bytes / (1024 * 1024); // Convert to MB
  }

  /// Check if file is an image
  bool isImageFile(File file) {
    final extension = file.path.toLowerCase().split('.').last;
    return ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(extension);
  }
}
