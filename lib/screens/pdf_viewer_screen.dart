import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import '../../providers/pdf_provider.dart';

class PdfViewerScreen extends StatefulWidget {
  final PdfDocument document;

  const PdfViewerScreen({super.key, required this.document});

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  final PdfViewerController _pdfViewerController = PdfViewerController();
  int _currentPage = 1;
  int _totalPages = 0;
  bool _isStarred = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.appBarTheme.foregroundColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            Text(
              widget.document.name,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: theme.appBarTheme.foregroundColor, fontSize: 16),
            ),
            if (_totalPages > 0)
              Text(
                'Page $_currentPage of $_totalPages',
                style: TextStyle(
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  fontSize: 12,
                ),
              ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              _isStarred ? Icons.star : Icons.star_outline,
              color: _isStarred ? Colors.yellow[600] : Colors.white,
            ),
            onPressed: () {
              setState(() {
                _isStarred = !_isStarred;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: () async {
              try {
                final result = XFile(widget.document.path);
                await Share.shareXFiles(
                  [result],
                  text: 'Sharing ${widget.document.name}',
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error sharing file: $e')),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: const Color(0xFF1F2937),
                builder: (context) => SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.info_outline, color: Colors.white),
                        title: const Text('Document Info', style: TextStyle(color: Colors.white)),
                        onTap: () {
                          Navigator.pop(context);
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.print, color: Colors.white),
                        title: const Text('Print', style: TextStyle(color: Colors.white)),
                        onTap: () {
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(child: Column(
        children: [
          // PDF Viewer
          Expanded(
            child: Container(
              color: const Color(0xFF111827),
              padding: const EdgeInsets.all(16),
              child: SfPdfViewer.file(
                File(widget.document.path),
                controller: _pdfViewerController,
                onDocumentLoaded: (PdfDocumentLoadedDetails details) {
                  setState(() {
                    _totalPages = details.document.pages.count;
                  });
                },
                onPageChanged: (PdfPageChangedDetails details) {
                  setState(() {
                    _currentPage = details.newPageNumber;
                  });
                },
              ),
            ),
          ),

          // Bottom Controls
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF1F2937), // Dark gray-800
              border: Border(
                top: BorderSide(color: Color(0xFF374151), width: 1),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Page Navigation
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: _currentPage > 1
                            ? () {
                          _pdfViewerController.previousPage();
                        }
                            : null,
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(0xFF374151),
                          foregroundColor: Colors.white,
                          disabledForegroundColor: Colors.grey[600],
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Previous'),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF374151),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF4B5563)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 40,
                              child: TextField(
                                controller: TextEditingController(text: _currentPage.toString()),
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white, fontSize: 14),
                                decoration: const InputDecoration(
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                  border: InputBorder.none,
                                ),
                                onSubmitted: (value) {
                                  final page = int.tryParse(value);
                                  if (page != null && page >= 1 && page <= _totalPages) {
                                    _pdfViewerController.jumpToPage(page);
                                  }
                                },
                              ),
                            ),
                            Text(
                              ' / $_totalPages',
                              style: TextStyle(color: Colors.grey[400], fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      TextButton(
                        onPressed: _currentPage < _totalPages
                            ? () {
                          _pdfViewerController.nextPage();
                        }
                            : null,
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(0xFF374151),
                          foregroundColor: Colors.white,
                          disabledForegroundColor: Colors.grey[600],
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Next'),
                      ),
                    ],
                  ),
                ),

                // Tool Bar
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _ToolButton(
                        icon: Icons.search,
                        onPressed: () {},
                      ),
                      _ToolButton(
                        icon: Icons.bookmark_add_outlined,
                        onPressed: () {},
                      ),
                      _ToolButton(
                        icon: Icons.zoom_out,
                        onPressed: () {
                          _pdfViewerController.zoomLevel = _pdfViewerController.zoomLevel - 0.25;
                        },
                      ),
                      _ToolButton(
                        icon: Icons.zoom_in,
                        onPressed: () {
                          _pdfViewerController.zoomLevel = _pdfViewerController.zoomLevel + 0.25;
                        },
                      ),
                      _ToolButton(
                        icon: Icons.grid_view,
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      )),
    );
  }

  @override
  void dispose() {
    _pdfViewerController.dispose();
    super.dispose();
  }
}

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _ToolButton({
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white, size: 20),
      style: IconButton.styleFrom(
        backgroundColor: Colors.transparent,
        padding: const EdgeInsets.all(12),
      ),
    );
  }
}

