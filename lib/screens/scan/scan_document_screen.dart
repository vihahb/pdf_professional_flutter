// import 'package:flutter/material.dart';
// import 'package:camera/camera.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'dart:io';
// import 'editor_screen.dart';
//
// class ScanDocumentScreen extends StatefulWidget {
//   const ScanDocumentScreen({super.key});
//
//   @override
//   State<ScanDocumentScreen> createState() => _ScanDocumentScreenState();
// }
//
// class _ScanDocumentScreenState extends State<ScanDocumentScreen>
//     with WidgetsBindingObserver {
//   CameraController? _cameraController;
//   List<File> _scannedImages = [];
//   final ImagePicker _picker = ImagePicker();
//   bool _isProcessing = false;
//   bool _isCameraReady = false;
//   List<CameraDescription>? _cameras;
//   bool _isInCameraMode = true;
//   int _currentImageIndex = 0;
//
//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addObserver(this);
//     _initializeCamera();
//   }
//
//   Future<void> _initializeCamera() async {
//     try {
//       final cameraStatus = await Permission.camera.request();
//       if (cameraStatus.isDenied) {
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text('Camera permission is required')),
//           );
//         }
//         return;
//       }
//
//       _cameras = await availableCameras();
//       if (_cameras == null || _cameras!.isEmpty) {
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text('No camera available')),
//           );
//         }
//         return;
//       }
//
//       _cameraController = CameraController(
//         _cameras![0],
//         ResolutionPreset.max,
//         enableAudio: false,
//       );
//
//       await _cameraController!.initialize();
//       if (mounted) {
//         setState(() {
//           _isCameraReady = true;
//         });
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error initializing camera: $e')),
//         );
//       }
//     }
//   }
//
//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     if (state == AppLifecycleState.resumed) {
//       if (_cameraController != null && !_cameraController!.value.isInitialized) {
//         _cameraController!.initialize().then((_) {
//           if (mounted) {
//             setState(() {
//               _isCameraReady = true;
//             });
//           }
//         });
//       }
//     } else if (state == AppLifecycleState.paused) {
//       _cameraController?.dispose();
//     }
//   }
//
//   @override
//   void dispose() {
//     WidgetsBinding.instance.removeObserver(this);
//     _cameraController?.dispose();
//     super.dispose();
//   }
//
//   Future<void> _captureImage() async {
//     if (_cameraController == null || !_cameraController!.value.isInitialized) {
//       return;
//     }
//
//     try {
//       final XFile photo = await _cameraController!.takePicture();
//       setState(() {
//         _scannedImages.add(File(photo.path));
//         _currentImageIndex = _scannedImages.length - 1;
//         _isInCameraMode = false;
//       });
//
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('Photo captured! Edit or add more pages.'),
//             duration: Duration(seconds: 1),
//         );
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//             content: Text('Photo captured!'),
//         );
//       }
//     }
//         // Open editor after capturing image
//         _openEditor();
//   }
//
//   Future<void> _pickFromGallery() async {
//     try {
//       final List<XFile> images = await _picker.pickMultiImage(
//         imageQuality: 85,
//       );
//
//       if (images.isNotEmpty) {
//         setState(() {
//           _scannedImages.addAll(images.map((img) => File(img.path)));
//           _isInCameraMode = false;
//         });
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error picking images: $e')),
//         );
//     }
//         // Open editor after selecting images
//         _openEditor();
//   }
//
//   Future<void> _switchCamera() async {
//     if (_cameras == null || _cameras!.length < 2) {
//       return;
//     }
//
//     try {
//       final newCameraIndex = _cameraController?.description == _cameras![0] ? 1 : 0;
//       await _cameraController?.dispose();
//
//       _cameraController = CameraController(
//         _cameras![newCameraIndex],
//         ResolutionPreset.high,
//         enableAudio: false,
//       );
//
//       await _cameraController!.initialize();
//       if (mounted) {
//         setState(() {});
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error switching camera: $e')),
//         );
//       }
//     }
//   }
//
//   Future<void> _rotateImage() async {
//     if (_currentImageIndex < 0 || _currentImageIndex >= _scannedImages.length) {
//       return;
//     }
//
//     try {
//       final imageFile = _scannedImages[_currentImageIndex];
//       final bytes = await imageFile.readAsBytes();
//   void _openEditor() {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => EditorScreen(
//           scannedImages: _scannedImages,
//           onAddPage: _goBackToCamera,
//           onBack: _goBackToCamera,
//         ),
//       ),
//     ).then((updatedImages) {
//       if (updatedImages != null && updatedImages is List<File>) {
//               duration: Duration(milliseconds: 500),
//           _scannedImages = updatedImages;
//           );
//   }
//     });
//       _cameraController!.initialize().then((_) {
//         if (mounted) {
//           setState(() {
//             _isCameraReady = true;
//           });
//         }
//     }
//   }
//
//   Future<void> _createPdf() async {
//     if (_scannedImages.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please add at least one image')),
//       );
//       return;
//     }
//
//     final frameWidth = size.width * frameWidthPercent;
//     final frameHeight = frameWidth * (11 / 8.5); // A4 aspect ratio
//
//     // Responsive corner guide length (relative to frame size)
//     final cornerLength = isTablet ? frameWidth * 0.12 : frameWidth * 0.15;
//
//     // Responsive stroke width for corner guides
//     final strokeWidth = isTablet ? 3.0 : 4.0;
//
//     // Responsive icon and text sizes
//     final iconSize = isTablet ? 56.0 : 48.0;
//     final headlineSize = isTablet ? 18.0 : 16.0;
//     final helperSize = isTablet ? 13.0 : 12.0;
//     final borderRadius = isTablet ? 24.0 : 20.0;
//
//     return {
//       'frameWidth': frameWidth,
//       'frameHeight': frameHeight,
//       'cornerLength': cornerLength,
//       'strokeWidth': strokeWidth,
//       'iconSize': iconSize,
//       'headlineSize': headlineSize,
//       'helperSize': helperSize,
//       'borderRadius': borderRadius,
//     };
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     // Camera capture mode - show whenever in camera mode
//     if (_isInCameraMode) {
//       return Scaffold(
//         backgroundColor: Colors.black,
//         body: Column(
//           children: [
//             // Header
//             SafeArea(
//               child: Container(
//                 padding: const EdgeInsets.all(16),
//                 decoration: BoxDecoration(
//                   color: Colors.black.withValues(alpha: 0.5),
//                 ),
//                 child: const Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Text(
//                       'Scan Document',
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontSize: 18,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//
//             // Live Camera Stream with Guide Overlay
//             Expanded(
//               child: Stack(
//                 children: [
//                   // Camera Preview
//                   _isCameraReady && _cameraController != null
//                       ? SizedBox.expand( child: OrientationBuilder( builder: (context, orientation) { return CameraPreview(_cameraController!); }, ), )
//                       : Container(
//                           decoration: BoxDecoration(
//                             gradient: LinearGradient(
//                               begin: Alignment.topCenter,
//                               end: Alignment.bottomCenter,
//                               colors: [
//                                 const Color(0xFF1F2937),
//                                 const Color(0xFF111827),
//                               ],
//                             ),
//                           ),
//                           child: Center(
//                             child: Column(
//                               mainAxisAlignment: MainAxisAlignment.center,
//                               children: [
//                                 const CircularProgressIndicator(
//                                   valueColor:
//                                       AlwaysStoppedAnimation<Color>(Colors.white),
//                                 ),
//                                 const SizedBox(height: 16),
//                                 Text(
//                                   'Initializing Camera...',
//                                   style: TextStyle(
//                                     color: Colors.white.withValues(alpha: 0.7),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ),
//
//                   // Beautiful Document Frame Guide
//                   if (_isCameraReady)
//                     Builder(
//                       builder: (context) {
//                         final dims = _getResponsiveDimensions(context);
//                         return Center(
//                           child: Container(
//                             width: dims['frameWidth'],
//                             height: dims['frameHeight'],
//                             decoration: BoxDecoration(
//                               border: Border.all(
//                                 color: Colors.white.withValues(alpha: 0.7),
//                                 width: 3,
//                               ),
//                               borderRadius: BorderRadius.circular(dims['borderRadius']!),
//                               boxShadow: [
//                                 BoxShadow(
//                                   color: Colors.blue.withValues(alpha: 0.3),
//                                   blurRadius: 20,
//                                   spreadRadius: 5,
//                                 ),
//                               ],
//                             ),
//                             child: Container(
//                               decoration: BoxDecoration(
//                                 borderRadius: BorderRadius.circular(dims['borderRadius']!),
//                                 border: Border.all(
//                                   color: Colors.white.withValues(alpha: 0.3),
//                                   width: 1,
//                                 ),
//                               ),
//                               child: Center(
//                                 child: SingleChildScrollView(
//                                   child: Column(
//                                     mainAxisAlignment: MainAxisAlignment.center,
//                                     children: [
//                                       SizedBox(height: dims['frameHeight']! * 0.1),
//                                       Icon(
//                                         Icons.document_scanner,
//                                         size: dims['iconSize'],
//                                         color: Colors.white.withValues(alpha: 0.5),
//                                       ),
//                                       const SizedBox(height: 12),
//                                       Text(
//                                         'Align Document',
//                                         style: TextStyle(
//                                           color: Colors.white.withValues(alpha: 0.7),
//                                           fontSize: dims['headlineSize'],
//                                           fontWeight: FontWeight.w600,
//                                         ),
//                                       ),
//                                       const SizedBox(height: 4),
//                                       Padding(
//                                         padding: const EdgeInsets.symmetric(horizontal: 16),
//                                         child: Text(
//                                           'Center your document in the frame',
//                                           textAlign: TextAlign.center,
//                                           style: TextStyle(
//                                             color: Colors.white.withValues(alpha: 0.5),
//                                             fontSize: dims['helperSize'],
//                                           ),
//                                         ),
//                                       ),
//                                       SizedBox(height: dims['frameHeight']! * 0.1),
//                                     ],
//                                   ),
//                                 ),
//                               ),
//                             ),
//                           ),
//                         );
//                       },
//                     ),
//
//                   // Corner guides (visual indicators) - Responsive
//                   if (_isCameraReady)
//                     Positioned.fill(
//                       child: Builder(
//                         builder: (context) {
//                           final dims = _getResponsiveDimensions(context);
//                           return CustomPaint(
//                             painter: _CornerGuidePainter(
//                               dims['frameWidth']!,
//                               dims['frameHeight']!,
//                               dims['cornerLength']!,
//                               dims['strokeWidth']!,
//                             ),
//                           );
//                         },
//                       ),
//                     ),
//                 ],
//               ),
//             ),
//
//             // Bottom Controls
//             Container(
//               padding: const EdgeInsets.all(24),
//               decoration: BoxDecoration(
//                 color: Colors.black.withValues(alpha: 0.6),
//               ),
//               child: SafeArea(
//                 top: false,
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                   children: [
//                     // Gallery button
//                     IconButton(
//                       onPressed: _pickFromGallery,
//                       icon: const Icon(Icons.photo_library,
//                           color: Colors.white, size: 28),
//                       style: IconButton.styleFrom(
//                         backgroundColor: Colors.white.withValues(alpha: 0.1),
//                         padding: const EdgeInsets.all(12),
//                       ),
//                     ),
//
//                     // Capture button
//                     GestureDetector(
//                       onTap: _captureImage,
//                       child: Container(
//                         width: 72,
//                         height: 72,
//                         decoration: BoxDecoration(
//                           color: const Color(0xFF2563EB),
//                           shape: BoxShape.circle,
//                           boxShadow: [
//                             BoxShadow(
//                               color: Colors.white.withValues(alpha: 0.4),
//                               blurRadius: 12,
//                               spreadRadius: 6,
//                             ),
//                             BoxShadow(
//                               color: const Color(0xFF2563EB).withValues(alpha: 0.5),
//                               blurRadius: 20,
//                               spreadRadius: 8,
//                             ),
//                           ],
//                         ),
//                         child: const Icon(
//                           Icons.camera_alt,
//                           color: Colors.white,
//                           size: 36,
//                         ),
//                       ),
//                     ),
//
//                     // Flip camera button
//                     IconButton(
//                       onPressed: _switchCamera,
//                       icon: const Icon(Icons.flip_camera_android,
//                           color: Colors.white, size: 28),
//                       style: IconButton.styleFrom(
//                         backgroundColor: Colors.white.withValues(alpha: 0.1),
//                         padding: const EdgeInsets.all(12),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       );
//     }
//
//     // Edit mode (images captured or selected)
//     return Scaffold(
//       backgroundColor: const Color(0xFFFAFAFA),
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         elevation: 0,
//         leading: IconButton(
//           icon: Icon(Icons.close, color: Colors.grey[700]),
//           onPressed: () {
//             setState(() {
//               _scannedImages.clear();
//               _isInCameraMode = true;
//               _currentImageIndex = 0;
//             });
//           },
//         ),
//         title: Text(
//           '${_scannedImages.length} ${_scannedImages.length == 1 ? 'Page' : 'Pages'}',
//           style: TextStyle(color: Colors.grey[900]),
//         ),
//         actions: [
//           TextButton(
//             onPressed: _isProcessing ? null : _createPdf,
//             child: _isProcessing
//                 ? const SizedBox(
//                     width: 20,
//                     height: 20,
//                     child: CircularProgressIndicator(strokeWidth: 2),
//                   )
//                 : const Text(
//                     'Save',
//                     style: TextStyle(
//                       fontWeight: FontWeight.bold,
//                       fontSize: 16,
//                       color: Color(0xFF2563EB),
//                     ),
//                   ),
//           ),
//           const SizedBox(width: 8),
//         ],
//       ),
//       body: Column(
//         children: [
//           // Current Page Preview
//           Expanded(
//             child: Container(
//               color: Colors.grey[200],
//               padding: const EdgeInsets.all(16),
//               child: Center(
//                 child: Container(
//                   constraints: const BoxConstraints(maxWidth: 400),
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(16),
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.black.withValues(alpha: 0.1),
//                         blurRadius: 12,
//                         offset: const Offset(0, 4),
//                       ),
//                     ],
//                   ),
//                   child: ClipRRect(
//                     borderRadius: BorderRadius.circular(16),
//                     child: AspectRatio(
//                       aspectRatio: 8.5 / 11,
//                       child: _currentImageIndex >= 0 &&
//                               _currentImageIndex < _scannedImages.length
//                           ? Image.file(
//                               _scannedImages[_currentImageIndex],
//                               fit: BoxFit.contain,
//                             )
//                           : const Center(
//                               child: Text('No image'),
//                             ),
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ),
//
//           // Editing Tools
//           Container(
//             decoration: BoxDecoration(
//               color: Colors.white,
//               border: Border(
//                 top: BorderSide(color: Colors.grey[200]!, width: 1),
//               ),
//             ),
//             child: SafeArea(
//               top: false,
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   // Primary Tools
//                   Padding(
//                     padding: const EdgeInsets.all(16),
//                     child: Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                       children: [
//                         _EditToolButton(
//                           icon: Icons.crop,
//                           label: 'Crop',
//                           onPressed: _cropImage,
//                         ),
//                         _EditToolButton(
//                           icon: Icons.rotate_right,
//                           label: 'Rotate',
//                           onPressed: _rotateImage,
//                         ),
//                         _EditToolButton(
//                           icon: Icons.auto_fix_high,
//                           label: 'Enhance',
//                           onPressed: _enhanceImage,
//                         ),
//                         _EditToolButton(
//                           icon: Icons.add_a_photo,
//                           label: 'Add Page',
//                           onPressed: _goBackToCamera,
//                         ),
//                       ],
//                     ),
//                   ),
//
//                   // Page thumbnails
//                   if (_scannedImages.length > 1)
//                     Padding(
//                       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                       child: SizedBox(
//                         height: 90,
//                         child: ListView.builder(
//                           scrollDirection: Axis.horizontal,
//                           itemCount: _scannedImages.length,
//                           itemBuilder: (context, index) {
//                             final isSelected = index == _currentImageIndex;
//                             return Container(
//                               width: 70,
//                               margin: const EdgeInsets.only(right: 12),
//                               child: GestureDetector(
//                                 onTap: () {
//                                   setState(() {
//                                     _currentImageIndex = index;
//                                   });
//                                 },
//                                 child: Container(
//                                   decoration: BoxDecoration(
//                                     border: Border.all(
//                                       color: isSelected
//                                           ? const Color(0xFF2563EB)
//                                           : Colors.grey[300]!,
//                                       width: isSelected ? 3 : 1,
//                                     ),
//                                     borderRadius: BorderRadius.circular(12),
//                                   ),
//                                   child: Stack(
//                                     children: [
//                                       ClipRRect(
//                                         borderRadius: BorderRadius.circular(12),
//                                         child: Image.file(
//                                           _scannedImages[index],
//                                           fit: BoxFit.cover,
//                                         ),
//                                       ),
//                                       Positioned(
//                                         top: 4,
//                                         right: 4,
//                                         child: GestureDetector(
//                                           onTap: () => _removeImage(index),
//                                           child: Container(
//                                             padding: const EdgeInsets.all(4),
//                                             decoration: BoxDecoration(
//                                               color: Colors.red.withValues(alpha: 0.8),
//                                               shape: BoxShape.circle,
//                                             ),
//                                             child: const Icon(
//                                               Icons.close,
//                                               size: 14,
//                                               color: Colors.white,
//                                             ),
//                                           ),
//                                         ),
//                                       ),
//                                       Positioned(
//                                         bottom: 4,
//                                         left: 4,
//                                         child: Container(
//                                           padding: const EdgeInsets.symmetric(
//                                             horizontal: 6,
//                                             vertical: 2,
//                                           ),
//                                           decoration: BoxDecoration(
//                                             color: Colors.black.withValues(alpha: 0.7),
//                                             borderRadius: BorderRadius.circular(4),
//                                           ),
//                                           child: Text(
//                                             '${index + 1}',
//                                             style: const TextStyle(
//                                               color: Colors.white,
//                                               fontSize: 10,
//                                               fontWeight: FontWeight.bold,
//                                             ),
//                                           ),
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                               ),
//                             );
//                           },
//                         ),
//                       ),
//                     ),
//                   const SizedBox(height: 8),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// class _EditToolButton extends StatelessWidget {
//   final IconData icon;
//   final String label;
//   final VoidCallback onPressed;
//
//   const _EditToolButton({
//     required this.icon,
//     required this.label,
//     required this.onPressed,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return InkWell(
//       onTap: onPressed,
//       borderRadius: BorderRadius.circular(12),
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Icon(
//               icon,
//               color: const Color(0xFF2563EB),
//               size: 28,
//             ),
//             const SizedBox(height: 6),
//             Text(
//               label,
//               style: const TextStyle(
//                 color: Color(0xFF2563EB),
//                 fontSize: 12,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
//
// class _CornerGuidePainter extends CustomPainter {
//   final double frameWidth;
//   final double frameHeight;
//   final double cornerLength;
//   final double strokeWidth;
//
//   _CornerGuidePainter(
//     this.frameWidth,
//     this.frameHeight,
//     this.cornerLength,
//     this.strokeWidth,
//   );
//
//   @override
//   void paint(Canvas canvas, Size size) {
//     final centerX = size.width / 2;
//     final centerY = size.height / 2;
//     final halfWidth = frameWidth / 2;
//     final halfHeight = frameHeight / 2;
//
//     final paint = Paint()
//       ..color = Colors.blue.withValues(alpha: 0.6)
//       ..strokeWidth = strokeWidth
//       ..strokeCap = StrokeCap.round;
//
//
//     // Top-left corner
//     canvas.drawLine(
//       Offset(centerX - halfWidth, centerY - halfHeight),
//       Offset(centerX - halfWidth + cornerLength, centerY - halfHeight),
//       paint,
//     );
//     canvas.drawLine(
//       Offset(centerX - halfWidth, centerY - halfHeight),
//       Offset(centerX - halfWidth, centerY - halfHeight + cornerLength),
//       paint,
//     );
//
//     // Top-right corner
//     canvas.drawLine(
//       Offset(centerX + halfWidth, centerY - halfHeight),
//       Offset(centerX + halfWidth - cornerLength, centerY - halfHeight),
//       paint,
//     );
//     canvas.drawLine(
//       Offset(centerX + halfWidth, centerY - halfHeight),
//       Offset(centerX + halfWidth, centerY - halfHeight + cornerLength),
//       paint,
//     );
//
//     // Bottom-left corner
//     canvas.drawLine(
//       Offset(centerX - halfWidth, centerY + halfHeight),
//       Offset(centerX - halfWidth + cornerLength, centerY + halfHeight),
//       paint,
//     );
//     canvas.drawLine(
//       Offset(centerX - halfWidth, centerY + halfHeight),
//       Offset(centerX - halfWidth, centerY + halfHeight - cornerLength),
//       paint,
//     );
//
//     // Bottom-right corner
//     canvas.drawLine(
//       Offset(centerX + halfWidth, centerY + halfHeight),
//       Offset(centerX + halfWidth - cornerLength, centerY + halfHeight),
//       paint,
//     );
//     canvas.drawLine(
//       Offset(centerX + halfWidth, centerY + halfHeight),
//       Offset(centerX + halfWidth, centerY + halfHeight - cornerLength),
//       paint,
//     );
//   }
//
//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
// }
