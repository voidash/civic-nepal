import 'dart:typed_data';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'package:flutter/foundation.dart';

/// Save/download image on web
Future<bool> saveImageToGallery(
  Uint8List bytes, {
  String? album,
  String filename = 'image.jpg',
}) async {
  try {
    final blob = html.Blob([bytes], 'image/jpeg');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', filename)
      ..style.display = 'none';
    html.document.body?.append(anchor);
    anchor.click();
    anchor.remove();
    html.Url.revokeObjectUrl(url);
    return true;
  } catch (e) {
    debugPrint('Error downloading file on web: $e');
    return false;
  }
}

/// Share image on web (falls back to download)
Future<void> shareImageFile(
  Uint8List bytes, {
  String? subject,
  String filename = 'image.jpg',
}) async {
  // On web, we just trigger a download
  await saveImageToGallery(bytes, filename: filename);
}
