import 'dart:typed_data';

import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../services/image_service.dart';
import '../../widgets/home_title.dart';

/// Screen for merging front and back citizenship photos into a single image
class CitizenshipMergerScreen extends StatefulWidget {
  const CitizenshipMergerScreen({super.key});

  @override
  State<CitizenshipMergerScreen> createState() => _CitizenshipMergerScreenState();
}

class _CitizenshipMergerScreenState extends State<CitizenshipMergerScreen> {
  PickedImage? _frontImage;
  PickedImage? _backImage;
  Uint8List? _mergedImage;
  bool _isProcessing = false;

  Future<void> _pickImage(bool isFront) async {
    final source = await _showImageSourceDialog();
    if (source == null) return;

    final PickedImage? picked = source == ImageSource.camera
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
    final l10n = AppLocalizations.of(context);

    // On web, camera is not available, so just pick from gallery
    if (!ImageService.isCameraAvailable) {
      return ImageSource.gallery;
    }

    return showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(l10n.gallery),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text(l10n.camera),
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
        _frontImage!.bytes,
        _backImage!.bytes,
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

    final success = await ImageService.saveImage(
      _mergedImage!,
      album: 'Nepal Civic',
      filename: 'citizenship_merged.jpg',
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
    await ImageService.shareImage(
      _mergedImage!,
      subject: 'Citizenship Photo',
      filename: 'citizenship_merged.jpg',
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
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: HomeTitle(child: Text(l10n.citizenshipPhotoMerger)),
        actions: [
          if (_frontImage != null || _backImage != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _reset,
              tooltip: l10n.reset,
            ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 600;
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: _mergedImage != null
                  ? _buildMergedResultView(isWide)
                  : _buildImageSelectionView(isWide),
            ),
          );
        },
      ),
    );
  }

  Widget _buildImageSelectionView(bool isWide) {
    final l10n = AppLocalizations.of(context);
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
                  Text(
                    l10n.mergerInstructions,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Image picker cards - side by side on wide screens
          if (isWide)
            Row(
              children: [
                Expanded(
                  child: _ImagePickerCard(
                    title: l10n.frontSide,
                    titleNp: 'अगाडिको भाग',
                    imageBytes: _frontImage?.bytes,
                    onTap: () => _pickImage(true),
                    icon: Icons.credit_card,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _ImagePickerCard(
                    title: l10n.backSide,
                    titleNp: 'पछाडिको भाग',
                    imageBytes: _backImage?.bytes,
                    onTap: () => _pickImage(false),
                    icon: Icons.credit_card_outlined,
                  ),
                ),
              ],
            )
          else ...[
            _ImagePickerCard(
              title: l10n.frontSide,
              titleNp: 'अगाडिको भाग',
              imageBytes: _frontImage?.bytes,
              onTap: () => _pickImage(true),
              icon: Icons.credit_card,
            ),
            const SizedBox(height: 16),
            _ImagePickerCard(
              title: l10n.backSide,
              titleNp: 'पछाडिको भाग',
              imageBytes: _backImage?.bytes,
              onTap: () => _pickImage(false),
              icon: Icons.credit_card_outlined,
            ),
          ],
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
            label: Text(_isProcessing ? l10n.processing : l10n.mergePhotos),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMergedResultView(bool isWide) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        // Merged image preview
        Expanded(
          child: InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Image.memory(
                _mergedImage!,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),

        // File size info
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            l10n.fileSize(ImageService.getFileSizeString(_mergedImage!.length)),
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
        const SizedBox(height: 8),

        // Action buttons
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: isWide ? 200 : null,
                  child: Expanded(
                    flex: isWide ? 0 : 1,
                    child: OutlinedButton.icon(
                      onPressed: _saveImage,
                      icon: const Icon(Icons.save_alt),
                      label: Text(l10n.save),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: isWide ? 200 : null,
                  child: Expanded(
                    flex: isWide ? 0 : 1,
                    child: FilledButton.icon(
                      onPressed: _shareImage,
                      icon: const Icon(Icons.share),
                      label: Text(l10n.share),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
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
  final Uint8List? imageBytes;
  final VoidCallback onTap;
  final IconData icon;

  const _ImagePickerCard({
    required this.title,
    required this.titleNp,
    required this.imageBytes,
    required this.onTap,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: imageBytes != null
            ? Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 1.6,
                    child: Image.memory(
                      imageBytes!,
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
            : Builder(
                builder: (context) {
                  final l10n = AppLocalizations.of(context);
                  return Container(
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
                          l10n.addTitle(title),
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
                          l10n.tapToSelect,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[500],
                              ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}
