import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'image_service.dart' show PickedImage;

bool get isDesktopPlatform =>
    Platform.isMacOS || Platform.isWindows || Platform.isLinux;

/// Pick image using native file dialog on desktop
Future<PickedImage?> pickImageNative() async {
  if (!isDesktopPlatform) return null; // Let caller fall through to image_picker

  try {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;

    final file = result.files.first;
    Uint8List? bytes = file.bytes;

    if (bytes == null && file.path != null) {
      bytes = await File(file.path!).readAsBytes();
    }

    if (bytes == null) return null;

    return PickedImage(
      bytes: bytes,
      path: file.path,
      name: file.name,
    );
  } catch (e) {
    debugPrint('Error picking image on desktop: $e');
    return null;
  }
}

/// Save image to gallery on mobile, or via file save dialog on desktop
Future<bool> saveImageToGallery(
  Uint8List bytes, {
  String? album,
  String filename = 'image.jpg',
}) async {
  if (isDesktopPlatform) {
    return _saveWithFileDialog(bytes, filename: filename, extensions: ['jpg', 'png']);
  }

  try {
    final directory = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final outputPath =
        '${directory.path}/${filename.replaceAll('.jpg', '')}_$timestamp.jpg';
    final outputFile = File(outputPath);
    await outputFile.writeAsBytes(bytes);

    final hasAccess = await Gal.hasAccess(toAlbum: album != null);
    if (!hasAccess) {
      final granted = await Gal.requestAccess(toAlbum: album != null);
      if (!granted) {
        debugPrint('Gallery access denied');
        return false;
      }
    }

    await Gal.putImage(outputPath, album: album);
    return true;
  } catch (e) {
    debugPrint('Error saving to gallery: $e');
    return false;
  }
}

/// Share image on mobile, or save via file dialog on desktop
Future<void> shareImageFile(
  Uint8List bytes, {
  String? subject,
  String filename = 'image.jpg',
}) async {
  if (isDesktopPlatform) {
    await _saveWithFileDialog(bytes, filename: filename, extensions: ['jpg', 'png']);
    return;
  }

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

/// Common file save dialog for desktop platforms
Future<bool> _saveWithFileDialog(
  Uint8List bytes, {
  required String filename,
  required List<String> extensions,
}) async {
  try {
    final result = await FilePicker.platform.saveFile(
      dialogTitle: 'Save As',
      fileName: filename,
      type: FileType.custom,
      allowedExtensions: extensions,
    );
    if (result == null) return false;

    final file = File(result);
    await file.writeAsBytes(bytes);
    return true;
  } catch (e) {
    debugPrint('Error saving file: $e');
    return false;
  }
}
