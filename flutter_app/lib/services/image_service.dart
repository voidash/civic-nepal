import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

// Platform-specific implementations for save/share
import 'image_service_mobile.dart' if (dart.library.html) 'image_service_web.dart'
    as platform;

/// Picked image result that works cross-platform
class PickedImage {
  final Uint8List bytes;
  final String? path; // Only available on mobile
  final String name;

  PickedImage({required this.bytes, this.path, required this.name});

  int get size => bytes.length;
}

/// Service for image picking, manipulation, and sharing
class ImageService {
  static final ImagePicker _picker = ImagePicker();

  /// Pick an image from gallery (works on web and mobile)
  static Future<PickedImage?> pickFromGallery() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 2000,
        maxHeight: 2000,
      );
      if (pickedFile == null) return null;

      final bytes = await pickedFile.readAsBytes();
      return PickedImage(
        bytes: bytes,
        path: kIsWeb ? null : pickedFile.path,
        name: pickedFile.name,
      );
    } catch (e) {
      debugPrint('Error picking image from gallery: $e');
      return null;
    }
  }

  /// Pick an image from camera (not available on web)
  static Future<PickedImage?> pickFromCamera() async {
    if (kIsWeb) {
      debugPrint('Camera not available on web');
      return null;
    }

    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 2000,
        maxHeight: 2000,
      );
      if (pickedFile == null) return null;

      final bytes = await pickedFile.readAsBytes();
      return PickedImage(
        bytes: bytes,
        path: pickedFile.path,
        name: pickedFile.name,
      );
    } catch (e) {
      debugPrint('Error picking image from camera: $e');
      return null;
    }
  }

  /// Merge two images vertically (top image above bottom image)
  /// Works on both web and mobile
  static Future<Uint8List?> mergeImagesVertically(Uint8List topBytes, Uint8List bottomBytes) async {
    try {
      final result = await compute(_mergeImagesCompute, {
        'top': topBytes,
        'bottom': bottomBytes,
      });
      return result;
    } catch (e) {
      debugPrint('Error merging images: $e');
      return null;
    }
  }

  /// Background isolate function for image merging
  static Uint8List? _mergeImagesCompute(Map<String, Uint8List> images) {
    try {
      final topDecoded = img.decodeImage(images['top']!);
      final bottomDecoded = img.decodeImage(images['bottom']!);

      if (topDecoded == null || bottomDecoded == null) return null;

      // Resize both images to same width for clean merge
      const targetWidth = 1000;
      final topResized = img.copyResize(topDecoded, width: targetWidth);
      final bottomResized = img.copyResize(bottomDecoded, width: targetWidth);

      // Create merged image
      final mergedHeight = topResized.height + bottomResized.height;
      final merged = img.Image(width: targetWidth, height: mergedHeight);

      // Fill with white background
      img.fill(merged, color: img.ColorRgb8(255, 255, 255));

      // Copy top image
      img.compositeImage(merged, topResized, dstX: 0, dstY: 0);

      // Copy bottom image below top
      img.compositeImage(merged, bottomResized, dstX: 0, dstY: topResized.height);

      // Encode as JPEG with good quality
      return Uint8List.fromList(img.encodeJpg(merged, quality: 90));
    } catch (e) {
      debugPrint('Error in image merge compute: $e');
      return null;
    }
  }

  /// Compress an image to target size (default 500KB)
  /// Works on both web and mobile
  static Future<Uint8List?> compressImage(Uint8List inputBytes, {int targetSizeKB = 500}) async {
    try {
      final result = await compute(_compressImageCompute, {
        'bytes': inputBytes,
        'targetSizeKB': targetSizeKB,
      });
      return result;
    } catch (e) {
      debugPrint('Error compressing image: $e');
      return null;
    }
  }

  /// Background isolate function for image compression
  static Uint8List? _compressImageCompute(Map<String, dynamic> params) {
    try {
      final Uint8List inputBytes = params['bytes'];
      final int targetSizeKB = params['targetSizeKB'];
      final targetSizeBytes = targetSizeKB * 1024;

      final decoded = img.decodeImage(inputBytes);
      if (decoded == null) return null;

      // Start with original size and reduce if needed
      var currentImage = decoded;
      var quality = 90;
      Uint8List? result;

      // First, try just reducing quality
      while (quality >= 10) {
        result = Uint8List.fromList(img.encodeJpg(currentImage, quality: quality));
        if (result.length <= targetSizeBytes) {
          return result;
        }
        quality -= 10;
      }

      // If still too large, resize and try again
      var scale = 0.9;
      while (scale >= 0.3) {
        final newWidth = (decoded.width * scale).round();
        final newHeight = (decoded.height * scale).round();
        currentImage = img.copyResize(decoded, width: newWidth, height: newHeight);

        quality = 85;
        while (quality >= 10) {
          result = Uint8List.fromList(img.encodeJpg(currentImage, quality: quality));
          if (result.length <= targetSizeBytes) {
            return result;
          }
          quality -= 10;
        }
        scale -= 0.1;
      }

      // Return the last attempt even if above target
      return result ?? Uint8List.fromList(img.encodeJpg(currentImage, quality: 10));
    } catch (e) {
      debugPrint('Error in image compress compute: $e');
      return null;
    }
  }

  /// Get file size in human-readable format
  static String getFileSizeString(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  /// Save bytes to device gallery (mobile only) or trigger download (web)
  static Future<bool> saveImage(Uint8List bytes, {String? album, String filename = 'image.jpg'}) async {
    return platform.saveImageToGallery(bytes, album: album, filename: filename);
  }

  /// Share image bytes
  static Future<void> shareImage(Uint8List bytes, {String? subject, String filename = 'image.jpg'}) async {
    await platform.shareImageFile(bytes, subject: subject, filename: filename);
  }

  /// Check if camera is available
  static bool get isCameraAvailable => !kIsWeb;
}
