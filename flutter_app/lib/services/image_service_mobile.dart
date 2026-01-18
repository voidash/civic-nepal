import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Save image to gallery on mobile
Future<bool> saveImageToGallery(
  Uint8List bytes, {
  String? album,
  String filename = 'image.jpg',
}) async {
  try {
    // Save to temp file first
    final directory = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final outputPath =
        '${directory.path}/${filename.replaceAll('.jpg', '')}_$timestamp.jpg';
    final outputFile = File(outputPath);
    await outputFile.writeAsBytes(bytes);

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
    await Gal.putImage(outputPath, album: album);
    return true;
  } catch (e) {
    debugPrint('Error saving to gallery: $e');
    return false;
  }
}

/// Share image on mobile
Future<void> shareImageFile(
  Uint8List bytes, {
  String? subject,
  String filename = 'image.jpg',
}) async {
  try {
    final directory = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final outputPath =
        '${directory.path}/${filename.replaceAll('.jpg', '')}_$timestamp.jpg';
    final outputFile = File(outputPath);
    await outputFile.writeAsBytes(bytes);

    await Share.shareXFiles(
      [XFile(outputPath)],
      subject: subject,
    );
  } catch (e) {
    debugPrint('Error sharing file: $e');
  }
}
