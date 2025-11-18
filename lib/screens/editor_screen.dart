import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:pdf/pdf.dart' hide PdfDocument;
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:image/image.dart' as img;
import '../../providers/pdf_provider.dart';
import '../../providers/premium_provider.dart';
import '../../services/ad_service.dart';

class EditorScreen extends StatefulWidget {
  final List<File> scannedImages;
  final VoidCallback onAddPage;
  final VoidCallback onBack;

  const EditorScreen({
    required this.scannedImages,
    required this.onAddPage,
    required this.onBack,
    super.key,
  });

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  late List<File> _scannedImages;
  int _currentImageIndex = 0;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _scannedImages = List.from(widget.scannedImages);
  }

  Future<void> _rotateImage() async {
    if (_currentImageIndex < 0 || _currentImageIndex >= _scannedImages.length) {
      return;
    }

    try {
      final imageFile = _scannedImages[_currentImageIndex];
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);

      if (image != null) {
        final rotated = img.copyRotate(image, angle: 90);
        await imageFile.writeAsBytes(img.encodePng(rotated));

        // Force image cache refresh
        imageCache.clear();
        imageCache.clearLiveImages();

        setState(() {});

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image rotated'),
              duration: Duration(milliseconds: 500),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error rotating image: $e')),
        );
      }
    }
  }

  Future<void> _cropImage() async {
    if (_currentImageIndex < 0 || _currentImageIndex >= _scannedImages.length) {
      return;
    }

    try {
      final imageFile = _scannedImages[_currentImageIndex];

      final croppedFile = await ImageCropper().cropImage(
        sourcePath: imageFile.path,
        compressFormat: ImageCompressFormat.png,
        compressQuality: 100,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            toolbarColor: const Color(0xFF2563EB),
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
            hideBottomControls: false,
            showCropGrid: true,
          ),
          IOSUiSettings(
            title: 'Crop Image',
            doneButtonTitle: 'Done',
            cancelButtonTitle: 'Cancel',
            aspectRatioLockEnabled: false,
            aspectRatioPresets: [
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio3x2,
              CropAspectRatioPreset.ratio5x3,
            ],
          ),
        ],
      );

      if (croppedFile != null) {
        final croppedBytes = await croppedFile.readAsBytes();
        await imageFile.writeAsBytes(croppedBytes);

        imageCache.clear();
        imageCache.clearLiveImages();

        setState(() {});

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image cropped successfully'),
              duration: Duration(milliseconds: 500),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cropping image: $e')),
        );
      }
    }
  }

  Future<void> _enhanceImage() async {
    if (_currentImageIndex < 0 || _currentImageIndex >= _scannedImages.length) {
      return;
    }

    try {
      final imageFile = _scannedImages[_currentImageIndex];
      final bytes = await imageFile.readAsBytes();
      var image = img.decodeImage(bytes);

      if (image != null) {
        image = img.grayscale(image);
        image = img.adjustColor(image, contrast: 1.5);
        await imageFile.writeAsBytes(img.encodePng(image));

        imageCache.clear();
        imageCache.clearLiveImages();

        setState(() {});

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image enhanced'),
              duration: Duration(milliseconds: 500),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error enhancing image: $e')),
        );
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _scannedImages.removeAt(index);
      if (_currentImageIndex >= _scannedImages.length) {
        _currentImageIndex = _scannedImages.length - 1;
      }
      if (_scannedImages.isEmpty) {
        widget.onBack();
      }
    });
  }

  Future<void> _createPdf() async {
    if (_scannedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one image')),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final pdf = pw.Document();

      for (final imageFile in _scannedImages) {
        final image = pw.MemoryImage(imageFile.readAsBytesSync());
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            build: (pw.Context context) {
              return pw.Center(
                child: pw.Image(image, fit: pw.BoxFit.contain),
              );
            },
          ),
        );
      }

      final output = await getApplicationDocumentsDirectory();
      final fileName = 'Scan_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('${output.path}/$fileName');
      await file.writeAsBytes(await pdf.save());

      final document = PdfDocument(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: fileName,
        path: file.path,
        createdAt: DateTime.now(),
        size: await file.length(),
      );

      if (mounted) {
        context.read<PdfProvider>().addDocument(document);

        final isPremium = context.read<PremiumProvider>().isPremium;
        if (!isPremium) {
          final adService = context.read<AdService>();
          adService.showInterstitialAd();
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF created successfully!')),
        );

        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating PDF: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: Colors.grey[700]),
          onPressed: widget.onBack,
        ),
        title: Text(
          '${_scannedImages.length} ${_scannedImages.length == 1 ? 'Page' : 'Pages'}',
          style: TextStyle(color: Colors.grey[900]),
        ),
        actions: [
          TextButton(
            onPressed: _isProcessing ? null : _createPdf,
            child: _isProcessing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF2563EB),
                    ),
                  ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Current Page Preview
          Expanded(
            child: Container(
              color: Colors.grey[200],
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 400),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: AspectRatio(
                      aspectRatio: 8.5 / 11,
                      child: _currentImageIndex >= 0 &&
                              _currentImageIndex < _scannedImages.length
                          ? Image.file(
                              _scannedImages[_currentImageIndex],
                              fit: BoxFit.contain,
                            )
                          : const Center(
                              child: Text('No image'),
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Editing Tools
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.grey[200]!, width: 1),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Primary Tools
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _EditToolButton(
                          icon: Icons.crop,
                          label: 'Crop',
                          onPressed: _cropImage,
                        ),
                        _EditToolButton(
                          icon: Icons.rotate_right,
                          label: 'Rotate',
                          onPressed: _rotateImage,
                        ),
                        _EditToolButton(
                          icon: Icons.auto_fix_high,
                          label: 'Enhance',
                          onPressed: _enhanceImage,
                        ),
                        _EditToolButton(
                          icon: Icons.add_a_photo,
                          label: 'Add Page',
                          onPressed: () {
                            Navigator.pop(context, _scannedImages);
                            widget.onAddPage();
                          },
                        ),
                      ],
                    ),
                  ),

                  // Page thumbnails
                  if (_scannedImages.length > 1)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: SizedBox(
                        height: 90,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _scannedImages.length,
                          itemBuilder: (context, index) {
                            final isSelected = index == _currentImageIndex;
                            return Container(
                              width: 70,
                              margin: const EdgeInsets.only(right: 12),
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _currentImageIndex = index;
                                  });
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: isSelected
                                          ? const Color(0xFF2563EB)
                                          : Colors.grey[300]!,
                                      width: isSelected ? 3 : 1,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.file(
                                          _scannedImages[index],
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      Positioned(
                                        top: 4,
                                        right: 4,
                                        child: GestureDetector(
                                          onTap: () => _removeImage(index),
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              color: Colors.red.withValues(alpha: 0.8),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.close,
                                              size: 14,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        bottom: 4,
                                        left: 4,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withValues(alpha: 0.7),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            '${index + 1}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditToolButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _EditToolButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: const Color(0xFF2563EB),
              size: 28,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF2563EB),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

