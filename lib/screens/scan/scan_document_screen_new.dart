import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import '../editor_screen.dart';

class ScanDocumentScreen extends StatefulWidget {
  const ScanDocumentScreen({super.key});

  @override
  State<ScanDocumentScreen> createState() => _ScanDocumentScreenState();
}

class _ScanDocumentScreenState extends State<ScanDocumentScreen>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  List<File> _scannedImages = [];
  final ImagePicker _picker = ImagePicker();
  bool _isCameraReady = false;
  List<CameraDescription>? _cameras;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameraStatus = await Permission.camera.request();
      if (cameraStatus.isDenied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Camera permission is required')),
          );
        }
        return;
      }

      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No camera available')),
          );
        }
        return;
      }

      _cameraController = CameraController(
        _cameras![0],
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      if (mounted) {
        setState(() {
          _isCameraReady = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error initializing camera: $e')),
        );
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Reinitialize camera when app resumes from background
      if (_cameraController != null && !_cameraController!.value.isInitialized) {
        _reinitializeCamera();
      }
    } else if (state == AppLifecycleState.paused) {
      // Only dispose if camera is initialized (actual app pause, not route change)
      if (_cameraController != null && _cameraController!.value.isInitialized) {
        _cameraController?.dispose();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _captureImage() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    try {
      final XFile photo = await _cameraController!.takePicture();
      setState(() {
        _scannedImages.add(File(photo.path));
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo captured!'),
            duration: Duration(seconds: 1),
          ),
        );
        // Open editor after capturing image
        _openEditor();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error capturing photo: $e')),
        );
      }
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        imageQuality: 85,
      );

      if (images.isNotEmpty) {
        setState(() {
          _scannedImages.addAll(images.map((img) => File(img.path)));
        });
        // Open editor after selecting images
        _openEditor();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking images: $e')),
        );
      }
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras == null || _cameras!.length < 2) {
      return;
    }

    try {
      final newCameraIndex = _cameraController?.description == _cameras![0] ? 1 : 0;
      await _cameraController?.dispose();

      _cameraController = CameraController(
        _cameras![newCameraIndex],
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error switching camera: $e')),
        );
      }
    }
  }

  Future<void> _changeResolution() async {
    final resolutions = [
      ResolutionPreset.low,
      ResolutionPreset.medium,
      ResolutionPreset.high,
      ResolutionPreset.veryHigh,
      ResolutionPreset.ultraHigh,
      ResolutionPreset.max,
    ];

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Camera Resolution'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: resolutions.map((preset) {
              return ListTile(
                title: Text(preset.toString().split('.').last),
                onTap: () async {
                  Navigator.pop(context);
                  await _updateCameraResolution(preset);
                },
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Future<void> _updateCameraResolution(ResolutionPreset preset) async {
    try {
      await _cameraController?.dispose();
      _cameraController = CameraController(
        _cameras![0],
        preset,
        enableAudio: false,
      );
      await _cameraController!.initialize();
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error changing resolution: $e')),
        );
      }
    }
  }

  void _openEditor() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditorScreen(
          scannedImages: _scannedImages,
          onAddPage: () {
            // Reinitialize camera when returning to add more pages
            _reinitializeCamera();
          },
          onBack: () {
            setState(() {
              _scannedImages.clear();
            });
          },
        ),
      ),
    );
  }

  Future<void> _reinitializeCamera() async {
    try {
      // If controller exists and is initialized, just setState and return
      if (_cameraController != null && _cameraController!.value.isInitialized) {
        if (mounted) {
          setState(() {});
        }
        return;
      }

      // If controller doesn't exist, create it
      if (_cameraController == null) {
        if (_cameras == null || _cameras!.isEmpty) {
          _cameras = await availableCameras();
        }

        if (_cameras == null || _cameras!.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No camera available')),
            );
          }
          return;
        }

        _cameraController = CameraController(
          _cameras![0],
          ResolutionPreset.high,
          enableAudio: false,
        );
      }

      // Initialize the controller
      await _cameraController!.initialize();
      if (mounted) {
        setState(() {
          _isCameraReady = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error reinitializing camera: $e')),
        );
      }
    }
  }

  Map<String, double> _getResponsiveDimensions(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    final frameWidthPercent = isTablet ? 0.65 : 0.85;
    final frameWidth = size.width * frameWidthPercent;
    final frameHeight = frameWidth * (11 / 8.5);

    final cornerLength = isTablet ? frameWidth * 0.12 : frameWidth * 0.15;
    final strokeWidth = isTablet ? 3.0 : 4.0;
    final iconSize = isTablet ? 56.0 : 48.0;
    final headlineSize = isTablet ? 18.0 : 16.0;
    final helperSize = isTablet ? 13.0 : 12.0;
    final borderRadius = isTablet ? 24.0 : 20.0;

    return {
      'frameWidth': frameWidth,
      'frameHeight': frameHeight,
      'cornerLength': cornerLength,
      'strokeWidth': strokeWidth,
      'iconSize': iconSize,
      'headlineSize': headlineSize,
      'helperSize': helperSize,
      'borderRadius': borderRadius,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          // Header
          SafeArea(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(child: const Text(
                    'Scan Document',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  )),
                  IconButton( onPressed: _changeResolution, icon: const Icon(Icons.settings, color: Colors.white, size: 24), tooltip: 'Change Resolution', ),
                ],
              ),
            ),
          ),

          Stack(
            children: [

            ],
          ),

          // Live Camera Stream with Guide Overlay
          Expanded(
            child: Stack(
              children: [
                // Camera Preview
                _isCameraReady && _cameraController != null
                    ? SizedBox.expand(
                        child: CameraPreview(_cameraController!),
                      )
                    : Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              const Color(0xFF1F2937),
                              const Color(0xFF111827),
                            ],
                          ),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const CircularProgressIndicator(
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Initializing Camera...',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                // Beautiful Document Frame Guide
                if (_isCameraReady)
                  Builder(
                    builder: (context) {
                      final dims = _getResponsiveDimensions(context);
                      return Center(
                        child: Container(
                          width: dims['frameWidth'],
                          height: dims['frameHeight'],
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.7),
                              width: 3,
                            ),
                            borderRadius: BorderRadius.circular(dims['borderRadius']!),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withValues(alpha: 0.3),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(dims['borderRadius']!),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: Center(
                              child: SingleChildScrollView(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(height: dims['frameHeight']! * 0.1),
                                    Icon(
                                      Icons.document_scanner,
                                      size: dims['iconSize'],
                                      color: Colors.white.withValues(alpha: 0.5),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Align Document',
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.7),
                                        fontSize: dims['headlineSize'],
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      child: Text(
                                        'Center your document in the frame',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.5),
                                          fontSize: dims['helperSize'],
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: dims['frameHeight']! * 0.1),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                // Corner guides
                if (_isCameraReady)
                  Positioned.fill(
                    child: Builder(
                      builder: (context) {
                        final dims = _getResponsiveDimensions(context);
                        return CustomPaint(
                          painter: _CornerGuidePainter(
                            dims['frameWidth']!,
                            dims['frameHeight']!,
                            dims['cornerLength']!,
                            dims['strokeWidth']!,
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          // Bottom Controls
          Container(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Gallery button
                IconButton(
                  onPressed: _pickFromGallery,
                  icon: const Icon(Icons.photo_library,
                      color: Colors.white, size: 28),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                    padding: const EdgeInsets.all(12),
                  ),
                ),

                // Capture button
                GestureDetector(
                  onTap: _captureImage,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.4),
                          blurRadius: 12,
                          spreadRadius: 6,
                        ),
                        BoxShadow(
                          color: const Color(0xFF2563EB).withValues(alpha: 0.5),
                          blurRadius: 20,
                          spreadRadius: 8,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                ),

                // Flip camera button
                IconButton(
                  onPressed: _switchCamera,
                  icon: const Icon(Icons.flip_camera_android,
                      color: Colors.white, size: 28),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                    padding: const EdgeInsets.all(12),
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

class _CornerGuidePainter extends CustomPainter {
  final double frameWidth;
  final double frameHeight;
  final double cornerLength;
  final double strokeWidth;

  _CornerGuidePainter(
    this.frameWidth,
    this.frameHeight,
    this.cornerLength,
    this.strokeWidth,
  );

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final halfWidth = frameWidth / 2;
    final halfHeight = frameHeight / 2;

    final paint = Paint()
      ..color = Colors.blue.withValues(alpha: 0.6)
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Top-left corner
    canvas.drawLine(
      Offset(centerX - halfWidth, centerY - halfHeight),
      Offset(centerX - halfWidth + cornerLength, centerY - halfHeight),
      paint,
    );
    canvas.drawLine(
      Offset(centerX - halfWidth, centerY - halfHeight),
      Offset(centerX - halfWidth, centerY - halfHeight + cornerLength),
      paint,
    );

    // Top-right corner
    canvas.drawLine(
      Offset(centerX + halfWidth, centerY - halfHeight),
      Offset(centerX + halfWidth - cornerLength, centerY - halfHeight),
      paint,
    );
    canvas.drawLine(
      Offset(centerX + halfWidth, centerY - halfHeight),
      Offset(centerX + halfWidth, centerY - halfHeight + cornerLength),
      paint,
    );

    // Bottom-left corner
    canvas.drawLine(
      Offset(centerX - halfWidth, centerY + halfHeight),
      Offset(centerX - halfWidth + cornerLength, centerY + halfHeight),
      paint,
    );
    canvas.drawLine(
      Offset(centerX - halfWidth, centerY + halfHeight),
      Offset(centerX - halfWidth, centerY + halfHeight - cornerLength),
      paint,
    );

    // Bottom-right corner
    canvas.drawLine(
      Offset(centerX + halfWidth, centerY + halfHeight),
      Offset(centerX + halfWidth - cornerLength, centerY + halfHeight),
      paint,
    );
    canvas.drawLine(
      Offset(centerX + halfWidth, centerY + halfHeight),
      Offset(centerX + halfWidth, centerY + halfHeight - cornerLength),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

