import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class ImageUploadWidget extends StatefulWidget {
  final bool allowMultiple;
  final String title;
  final String cameraText;
  final String galleryText;
  final String uploadButtonText;
  final Function(List<File>) onImagesSelected;
  final Function(List<String>) onUploadTap;
  final double imageSize;
  final Color? primaryColor;
  final Color? backgroundColor;

  const ImageUploadWidget({
    super.key,
    this.allowMultiple = false,
    this.title = "Upload Image",
    this.cameraText = "Camera",
    this.galleryText = "Gallery",
    this.uploadButtonText = "Upload",
    required this.onImagesSelected,
    required this.onUploadTap,
    this.imageSize = 120,
    this.primaryColor,
    this.backgroundColor,
  });

  @override
  State<ImageUploadWidget> createState() => _ImageUploadWidgetState();
}

class _ImageUploadWidgetState extends State<ImageUploadWidget> {
  final ImagePicker _picker = ImagePicker();
  List<XFile> _selectedImages = [];

  Future<void> _pickImage(ImageSource source) async {
    try {
      if (widget.allowMultiple && source == ImageSource.gallery) {
        final List<XFile> images = await _picker.pickMultiImage(
          imageQuality: 85,
        );
        if (images.isNotEmpty) {
          setState(() {
            _selectedImages.addAll(images);
          });
          _notifyImagesSelected();
        }
      } else {
        final XFile? image = await _picker.pickImage(
          source: source,
          imageQuality: 85,
        );
        if (image != null) {
          setState(() {
            if (widget.allowMultiple) {
              _selectedImages.add(image);
            } else {
              _selectedImages = [image];
            }
          });
          _notifyImagesSelected();
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
      }
    }
  }

  void _notifyImagesSelected() {
    if (kIsWeb) {
      // For web, we cannot create File objects
      // Pass empty list or handle differently
      widget.onImagesSelected([]);
    } else {
      final files = _selectedImages.map((xfile) => File(xfile.path)).toList();
      widget.onImagesSelected(files);
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
    _notifyImagesSelected();
  }

  void _editImage(int index) async {
    await _pickImage(ImageSource.gallery);
    if (_selectedImages.length > index + 1) {
      setState(() {
        _selectedImages.removeAt(index);
      });
    }
  }

  void _handleUpload() {
    final paths = _selectedImages.map((img) => img.path).toList();
    widget.onUploadTap(paths);
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = widget.primaryColor ?? const Color(0xFF4169E1);
    final bgColor = widget.backgroundColor ?? Colors.grey[100];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            widget.title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Action Buttons (Camera & Gallery)
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt),
                  label: Text(widget.cameraText),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library),
                  label: Text(widget.galleryText),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Image Preview Grid
          if (_selectedImages.isNotEmpty) ...[
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _selectedImages.asMap().entries.map((entry) {
                final index = entry.key;
                final image = entry.value;
                return _buildImagePreview(image, index);
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Upload Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _handleUpload,
                icon: const Icon(Icons.cloud_upload),
                label: Text(widget.uploadButtonText),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildImagePreview(XFile image, int index) {
    return Container(
      width: widget.imageSize,
      height: widget.imageSize,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[400]!),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: kIsWeb
                ? Image.network(
                    image.path,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.image, size: 40),
                      );
                    },
                  )
                : Image.file(
                    File(image.path),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.image, size: 40),
                      );
                    },
                  ),
          ),

          // Action buttons (Edit & Delete)
          Positioned(
            top: 4,
            right: 4,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Edit button
                InkWell(
                  onTap: () => _editImage(index),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.edit,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                // Delete button
                InkWell(
                  onTap: () => _removeImage(index),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 18,
                    ),
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
