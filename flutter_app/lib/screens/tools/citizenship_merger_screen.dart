import 'dart:io';

import 'package:flutter/material.dart';
import '../../services/image_service.dart';

/// Screen for merging front and back citizenship photos into a single image
class CitizenshipMergerScreen extends StatefulWidget {
  const CitizenshipMergerScreen({super.key});

  @override
  State<CitizenshipMergerScreen> createState() => _CitizenshipMergerScreenState();
}

class _CitizenshipMergerScreenState extends State<CitizenshipMergerScreen> {
  File? _frontImage;
  File? _backImage;
  File? _mergedImage;
  bool _isProcessing = false;

  Future<void> _pickImage(bool isFront) async {
    final source = await _showImageSourceDialog();
    if (source == null) return;

    final File? picked = source == ImageSource.camera
        ? await ImageService.pickFromCamera()
        : await ImageService.pickFromGallery();

    if (picked != null) {
      setState(() {
        if (isFront) {
          _frontImage = picked;
        } else {
          _backImage = picked;
        }
        // Reset merged image when source images change
        _mergedImage = null;
      });
    }
  }

  Future<ImageSource?> _showImageSourceDialog() async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _mergeImages() async {
    if (_frontImage == null || _backImage == null) return;

    setState(() => _isProcessing = true);

    try {
      final merged = await ImageService.mergeImagesVertically(
        _frontImage!,
        _backImage!,
      );

      if (merged != null && mounted) {
        setState(() => _mergedImage = merged);
      } else if (mounted) {
        _showError('Failed to merge images. Please try again.');
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
    if (_mergedImage == null) return;

    final success = await ImageService.saveToGallery(
      _mergedImage!,
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
    if (_mergedImage == null) return;
    await ImageService.shareFile(
      _mergedImage!,
      subject: 'Citizenship Photo',
    );
  }

  void _reset() {
    setState(() {
      _frontImage = null;
      _backImage = null;
      _mergedImage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Citizenship Photo Merger'),
        actions: [
          if (_frontImage != null || _backImage != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _reset,
              tooltip: 'Reset',
            ),
        ],
      ),
      body: _mergedImage != null
          ? _buildMergedResultView()
          : _buildImageSelectionView(),
    );
  }

  Widget _buildImageSelectionView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Instructions
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700], size: 32),
                  const SizedBox(height: 8),
                  const Text(
                    'Add front and back photos of your citizenship card to merge them into a single image.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Front image
          _ImagePickerCard(
            title: 'Front Side',
            titleNp: 'अगाडिको भाग',
            image: _frontImage,
            onTap: () => _pickImage(true),
            icon: Icons.credit_card,
          ),
          const SizedBox(height: 16),

          // Back image
          _ImagePickerCard(
            title: 'Back Side',
            titleNp: 'पछाडिको भाग',
            image: _backImage,
            onTap: () => _pickImage(false),
            icon: Icons.credit_card_outlined,
          ),
          const SizedBox(height: 24),

          // Merge button
          FilledButton.icon(
            onPressed: (_frontImage != null && _backImage != null && !_isProcessing)
                ? _mergeImages
                : null,
            icon: _isProcessing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.merge_type),
            label: Text(_isProcessing ? 'Processing...' : 'Merge Photos'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMergedResultView() {
    return Column(
      children: [
        // Merged image preview
        Expanded(
          child: InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Image.file(
                _mergedImage!,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),

        // File size info
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: FutureBuilder<int>(
            future: _mergedImage!.length(),
            builder: (context, snapshot) {
              final size = snapshot.data ?? 0;
              return Text(
                'Size: ${ImageService.getFileSizeString(size)}',
                style: TextStyle(color: Colors.grey[600]),
              );
            },
          ),
        ),
        const SizedBox(height: 8),

        // Action buttons
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
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
          ),
        ),
      ],
    );
  }
}

enum ImageSource { gallery, camera }

class _ImagePickerCard extends StatelessWidget {
  final String title;
  final String titleNp;
  final File? image;
  final VoidCallback onTap;
  final IconData icon;

  const _ImagePickerCard({
    required this.title,
    required this.titleNp,
    required this.image,
    required this.onTap,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: image != null
            ? Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 1.6,
                    child: Image.file(
                      image!,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.edit,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              )
            : Container(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        size: 32,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Add $title',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      titleNp,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap to select',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[500],
                          ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
