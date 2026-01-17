import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:gal/gal.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Service for image picking, manipulation, and sharing
class ImageService {
  static final ImagePicker _picker = ImagePicker();

  /// Pick an image from gallery
  static Future<File?> pickFromGallery() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 2000,
        maxHeight: 2000,
      );
      if (pickedFile == null) return null;
      return File(pickedFile.path);
    } catch (e) {
      debugPrint('Error picking image from gallery: $e');
      return null;
    }
  }

  /// Pick an image from camera
  static Future<File?> pickFromCamera() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 2000,
        maxHeight: 2000,
      );
      if (pickedFile == null) return null;
      return File(pickedFile.path);
    } catch (e) {
      debugPrint('Error picking image from camera: $e');
      return null;
    }
  }

  /// Merge two images vertically (top image above bottom image)
  static Future<File?> mergeImagesVertically(File topImage, File bottomImage) async {
    try {
      // Decode images in isolate to avoid UI blocking
      final Uint8List topBytes = await topImage.readAsBytes();
      final Uint8List bottomBytes = await bottomImage.readAsBytes();

      final result = await compute(_mergeImagesCompute, {
        'top': topBytes,
        'bottom': bottomBytes,
      });

      if (result == null) return null;

      // Save to temp file
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final outputPath = '${directory.path}/merged_citizenship_$timestamp.jpg';
      final outputFile = File(outputPath);
      await outputFile.writeAsBytes(result);

      return outputFile;
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
  static Future<File?> compressImage(File inputFile, {int targetSizeKB = 500}) async {
    try {
      final Uint8List inputBytes = await inputFile.readAsBytes();

      final result = await compute(_compressImageCompute, {
        'bytes': inputBytes,
        'targetSizeKB': targetSizeKB,
      });

      if (result == null) return null;

      // Save to temp file
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final outputPath = '${directory.path}/compressed_$timestamp.jpg';
      final outputFile = File(outputPath);
      await outputFile.writeAsBytes(result);

      return outputFile;
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

  /// Save file to device gallery (Photos app)
  static Future<bool> saveToGallery(File file, {String? album}) async {
    try {
      // Check if we have permission
      final hasAccess = await Gal.hasAccess(toAlbum: album != null);
      if (!hasAccess) {
        final granted = await Gal.requestAccess(toAlbum: album != null);
        if (!granted) {
          debugPrint('Gallery access denied');
          return false;
        }
      }

      // Save to gallery
      await Gal.putImage(file.path, album: album);
      return true;
    } catch (e) {
      debugPrint('Error saving to gallery: $e');
      return false;
    }
  }

  /// Share a file
  static Future<void> shareFile(File file, {String? subject}) async {
    try {
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: subject,
      );
    } catch (e) {
      debugPrint('Error sharing file: $e');
    }
  }
}
