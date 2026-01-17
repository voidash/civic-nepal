import 'dart:io';

import 'package:flutter/material.dart';
import '../../services/image_service.dart';

/// Compression target options
enum CompressionTarget {
  kb300(300, '300 KB'),
  kb500(500, '500 KB'),
  mb1(1024, '1 MB');

  final int sizeKB;
  final String label;

  const CompressionTarget(this.sizeKB, this.label);
}

/// Screen for compressing images to a target size
class ImageCompressorScreen extends StatefulWidget {
  const ImageCompressorScreen({super.key});

  @override
  State<ImageCompressorScreen> createState() => _ImageCompressorScreenState();
}

class _ImageCompressorScreenState extends State<ImageCompressorScreen> {
  File? _originalImage;
  File? _compressedImage;
  int _originalSize = 0;
  int _compressedSize = 0;
  bool _isProcessing = false;
  CompressionTarget _selectedTarget = CompressionTarget.kb500;

  Future<void> _pickImage() async {
    final source = await _showImageSourceDialog();
    if (source == null) return;

    final File? picked = source == _ImageSource.camera
        ? await ImageService.pickFromCamera()
        : await ImageService.pickFromGallery();

    if (picked != null) {
      final size = await picked.length();
      setState(() {
        _originalImage = picked;
        _originalSize = size;
        _compressedImage = null;
        _compressedSize = 0;
      });
    }
  }

  Future<_ImageSource?> _showImageSourceDialog() async {
    return showModalBottomSheet<_ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(context, _ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(context, _ImageSource.camera),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _compressImage() async {
    if (_originalImage == null) return;

    setState(() => _isProcessing = true);

    try {
      final compressed = await ImageService.compressImage(
        _originalImage!,
        targetSizeKB: _selectedTarget.sizeKB,
      );

      if (compressed != null && mounted) {
        final size = await compressed.length();
        setState(() {
          _compressedImage = compressed;
          _compressedSize = size;
        });
      } else if (mounted) {
        _showError('Failed to compress image. Please try again.');
      }
    } catch (e) {
      if (mounted) {
        _showError('Error: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _saveImage() async {
    if (_compressedImage == null) return;

    final success = await ImageService.saveToGallery(
      _compressedImage!,
      album: 'Nepal Civic',
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Saved to Photos' : 'Failed to save'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _shareImage() async {
    if (_compressedImage == null) return;
    await ImageService.shareFile(
      _compressedImage!,
      subject: 'Compressed Image',
    );
  }

  void _reset() {
    setState(() {
      _originalImage = null;
      _compressedImage = null;
      _originalSize = 0;
      _compressedSize = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Compressor'),
        actions: [
          if (_originalImage != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _reset,
              tooltip: 'Reset',
            ),
        ],
      ),
      body: _originalImage == null
          ? _buildEmptyState()
          : _buildCompressionView(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.compress,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Compress Images',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Reduce image file size while maintaining quality',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.add_photo_alternate),
              label: const Text('Select Image'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompressionView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image preview
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                AspectRatio(
                  aspectRatio: 1.5,
                  child: Image.file(
                    _compressedImage ?? _originalImage!,
                    fit: BoxFit.cover,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: _SizeInfo(
                          label: 'Original',
                          size: _originalSize,
                          color: Colors.grey,
                        ),
                      ),
                      if (_compressedImage != null) ...[
                        const Icon(Icons.arrow_forward, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _SizeInfo(
                            label: 'Compressed',
                            size: _compressedSize,
                            color: _compressedSize <= _selectedTarget.sizeKB * 1024
                                ? Colors.green
                                : Colors.orange,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Compression savings banner
          if (_compressedImage != null) ...[
            _CompressionSavingsBanner(
              originalSize: _originalSize,
              compressedSize: _compressedSize,
              targetKB: _selectedTarget.sizeKB,
            ),
            const SizedBox(height: 16),
          ],

          // Target size selector
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Target Size',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<CompressionTarget>(
                    segments: CompressionTarget.values
                        .map((t) => ButtonSegment(
                              value: t,
                              label: Text(t.label),
                            ))
                        .toList(),
                    selected: {_selectedTarget},
                    onSelectionChanged: (selection) {
                      setState(() {
                        _selectedTarget = selection.first;
                        _compressedImage = null;
                        _compressedSize = 0;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Compress / Action buttons
          if (_compressedImage == null)
            FilledButton.icon(
              onPressed: _isProcessing ? null : _compressImage,
              icon: _isProcessing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.compress),
              label: Text(_isProcessing ? 'Compressing...' : 'Compress'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _saveImage,
                    icon: const Icon(Icons.save_alt),
                    label: const Text('Save'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _shareImage,
                    icon: const Icon(Icons.share),
                    label: const Text('Share'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),

          // Re-compress button if already compressed
          if (_compressedImage != null) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _isProcessing ? null : _compressImage,
              icon: const Icon(Icons.refresh),
              label: const Text('Compress Again'),
            ),
          ],
        ],
      ),
    );
  }
}

enum _ImageSource { gallery, camera }

class _SizeInfo extends StatelessWidget {
  final String label;
  final int size;
  final Color color;

  const _SizeInfo({
    required this.label,
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        Text(
          ImageService.getFileSizeString(size),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _CompressionSavingsBanner extends StatelessWidget {
  final int originalSize;
  final int compressedSize;
  final int targetKB;

  const _CompressionSavingsBanner({
    required this.originalSize,
    required this.compressedSize,
    required this.targetKB,
  });

  @override
  Widget build(BuildContext context) {
    final saved = originalSize - compressedSize;
    final percentage = ((saved / originalSize) * 100).round();
    final isUnderTarget = compressedSize <= targetKB * 1024;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isUnderTarget ? Colors.green[50] : Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUnderTarget ? Colors.green[200]! : Colors.orange[200]!,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isUnderTarget ? Icons.check_circle : Icons.info,
            color: isUnderTarget ? Colors.green[700] : Colors.orange[700],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isUnderTarget
                      ? 'Compressed to under ${targetKB ~/ (targetKB >= 1024 ? 1024 : 1)}${targetKB >= 1024 ? " MB" : " KB"}'
                      : 'Could not reach target size',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isUnderTarget ? Colors.green[700] : Colors.orange[700],
                  ),
                ),
                Text(
                  'Saved ${ImageService.getFileSizeString(saved)} ($percentage% smaller)',
                  style: TextStyle(
                    color: isUnderTarget ? Colors.green[600] : Colors.orange[600],
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
