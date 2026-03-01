import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:simple_pdf_compression/simple_pdf_compression.dart';

bool get _isDesktop =>
    Platform.isMacOS || Platform.isWindows || Platform.isLinux;

/// Read file bytes from path
Future<Uint8List?> readFileBytes(String path) async {
  try {
    final file = File(path);
    return await file.readAsBytes();
  } catch (e) {
    debugPrint('Error reading file: $e');
    return null;
  }
}

/// Compress PDF
/// On mobile: uses simple_pdf_compression
/// On desktop: not supported, returns original bytes
Future<Uint8List?> compressPdf(
  Uint8List pdfBytes, {
  required int quality,
  required String filename,
}) async {
  if (_isDesktop) {
    // simple_pdf_compression uses Android/iOS native code; not available on desktop
    return pdfBytes;
  }

  try {
    final tempDir = await getTemporaryDirectory();
    final inputFile = File('${tempDir.path}/input_$filename');
    await inputFile.writeAsBytes(pdfBytes);

    final compressor = PDFCompression();
    final compressedFile = await compressor.compressPdf(
      inputFile,
      quality: quality,
    );

    final compressedBytes = await compressedFile.readAsBytes();

    try {
      await inputFile.delete();
      if (compressedFile.path != inputFile.path) {
        await compressedFile.delete();
      }
    } catch (_) {}

    return compressedBytes;
  } catch (e) {
    debugPrint('Error compressing PDF: $e');
    return null;
  }
}

/// Share PDF file (mobile) or save via file dialog (desktop)
Future<void> sharePdf(Uint8List bytes, {required String filename}) async {
  if (_isDesktop) {
    await _saveWithFileDialog(bytes, filename: filename);
    return;
  }

  try {
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/$filename');
    await file.writeAsBytes(bytes);

    await Share.shareXFiles(
      [XFile(file.path)],
      subject: filename,
    );
  } catch (e) {
    debugPrint('Error sharing PDF: $e');
  }
}

/// Save PDF to downloads (mobile) or via file dialog (desktop)
Future<bool> savePdf(Uint8List bytes, {required String filename}) async {
  if (_isDesktop) {
    return _saveWithFileDialog(bytes, filename: filename);
  }

  try {
    Directory? saveDir;
    if (Platform.isAndroid) {
      saveDir = Directory('/storage/emulated/0/Download');
      if (!await saveDir.exists()) {
        saveDir = await getExternalStorageDirectory();
      }
    } else {
      saveDir = await getApplicationDocumentsDirectory();
    }

    if (saveDir == null) return false;

    final file = File('${saveDir.path}/$filename');
    await file.writeAsBytes(bytes);
    return true;
  } catch (e) {
    debugPrint('Error saving PDF: $e');
    return false;
  }
}

/// File save dialog for desktop
Future<bool> _saveWithFileDialog(Uint8List bytes, {required String filename}) async {
  try {
    final result = await FilePicker.platform.saveFile(
      dialogTitle: 'Save PDF',
      fileName: filename,
      type: FileType.custom,
      allowedExtensions: ['pdf'],
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
