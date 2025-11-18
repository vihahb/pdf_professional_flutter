import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../providers/premium_provider.dart';
import '../providers/conversion_provider.dart';
import '../services/conversion_service.dart';

class ConverterScreen extends StatefulWidget {
  const ConverterScreen({super.key});

  @override
  State<ConverterScreen> createState() => _ConverterScreenState();
}

class _ConverterScreenState extends State<ConverterScreen> {
  String? _selectedFilePath;
  String? _selectedFileName;
  int? _selectedFileSize;
  String? _selectedFormat;
  bool _isConverting = false;
  bool _isComplete = false;
  String _conversionMode = 'to_pdf'; // 'to_pdf' or 'from_pdf'

  final List<Map<String, dynamic>> _toPdfOptions = [
    {
      'id': 'docx_to_pdf',
      'icon': Icons.description,
      'label': 'DOCX to PDF',
      'description': 'Convert Word documents',
      'premium': false,
      'extensions': ['docx', 'doc'],
    },
    {
      'id': 'excel_to_pdf',
      'icon': Icons.table_chart,
      'label': 'Excel to PDF',
      'description': 'Convert spreadsheets',
      'premium': false,
      'extensions': ['xlsx', 'xls'],
    },
  ];

  final List<Map<String, dynamic>> _fromPdfOptions = [
    {
      'id': 'pdf_to_word',
      'icon': Icons.description,
      'label': 'PDF to Word',
      'description': 'Convert to .docx format',
      'premium': false,
    },
    {
      'id': 'pdf_to_excel',
      'icon': Icons.table_chart,
      'label': 'PDF to Excel',
      'description': 'Convert to .xlsx format',
      'premium': true,
    },
    {
      'id': 'pdf_to_text',
      'icon': Icons.text_snippet,
      'label': 'PDF to Text',
      'description': 'Extract text to .txt',
      'premium': false,
    },
  ];

  List<Map<String, dynamic>> get _currentOptions =>
      _conversionMode == 'to_pdf' ? _toPdfOptions : _fromPdfOptions;

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result;

      if (_conversionMode == 'to_pdf') {
        // Pick DOCX or Excel files
        result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['docx', 'doc', 'xlsx', 'xls'],
        );
      } else {
        // Pick PDF files
        result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf'],
        );
      }

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final fileSize = await file.length();

        setState(() {
          _selectedFilePath = result!.files.single.path;
          _selectedFileName = result.files.single.name;
          _selectedFileSize = fileSize;
          _isComplete = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking file: $e')),
        );
      }
    }
  }

  Future<void> _convertFile() async {
    if (_selectedFormat == null || _selectedFilePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a file and output format')),
      );
      return;
    }

    setState(() {
      _isConverting = true;
    });

    try {
      String outputPath;
      String conversionType;

      // Perform conversion based on selected format
      switch (_selectedFormat) {
        case 'docx_to_pdf':
          outputPath = await ConversionService.convertDocxToPdf(_selectedFilePath!);
          conversionType = 'DOCX to PDF';
          break;
        case 'excel_to_pdf':
          outputPath = await ConversionService.convertExcelToPdf(_selectedFilePath!);
          conversionType = 'Excel to PDF';
          break;
        case 'pdf_to_word':
          outputPath = await ConversionService.convertPdfToDocx(_selectedFilePath!);
          conversionType = 'PDF to DOCX';
          break;
        case 'pdf_to_excel':
          outputPath = await ConversionService.convertPdfToExcel(_selectedFilePath!);
          conversionType = 'PDF to Excel';
          break;
        case 'pdf_to_text':
          outputPath = await ConversionService.convertPdfToText(_selectedFilePath!);
          conversionType = 'PDF to Text';
          break;
        default:
          throw Exception('Unsupported conversion format');
      }

      // Get output file size
      final outputFile = File(outputPath);
      final outputSize = await outputFile.length();

      // Create conversion record
      final record = ConversionRecord(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        sourceFileName: _selectedFileName!,
        sourcePath: _selectedFilePath!,
        outputFileName: outputPath.split('/').last,
        outputPath: outputPath,
        conversionType: conversionType,
        conversionDate: DateTime.now(),
        sourceFileSize: _selectedFileSize ?? 0,
        outputFileSize: outputSize,
        isSuccess: true,
      );

      // Add to history
      if (mounted) {
        await context.read<ConversionProvider>().addConversion(record);
      }

      setState(() {
        _isConverting = false;
        _isComplete = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Conversion completed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isConverting = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Conversion failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showPremiumDialog() {
    final premiumProvider = context.read<PremiumProvider>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.workspace_premium, color: Color(0xFF7C3AED)),
            SizedBox(width: 8),
            Text('Premium Feature'),
          ],
        ),
        content: const Text(
          'Unlock this conversion format and get unlimited conversions with Premium!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              premiumProvider.purchasePremium();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('🎉 Welcome to Premium!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Upgrade Now'),
          ),
        ],
      ),
    );
  }

  String _getFileIcon(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return '📄';
      case 'docx':
      case 'doc':
        return '📝';
      case 'xlsx':
      case 'xls':
        return '📊';
      case 'txt':
        return '📃';
      default:
        return '📄';
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today ${DateFormat('HH:mm').format(date)}';
    } else if (difference.inDays == 1) {
      return 'Yesterday ${DateFormat('HH:mm').format(date)}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return DateFormat('MMM dd, yyyy').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPremium = context.watch<PremiumProvider>().isPremium;
    final conversions = context.watch<ConversionProvider>().conversions;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: CustomScrollView(
        slivers: [
          // Header
          SliverAppBar(
            expandedHeight: 0,
            floating: true,
            pinned: true,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            automaticallyImplyLeading: false,
            title: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'File Converter',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Convert documents to and from PDF',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Premium Banner
                if (!isPremium)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF7C3AED), Color(0xFFEC4899)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.purple.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(Icons.workspace_premium,
                              color: Colors.white, size: 32),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Unlock Premium Conversions',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Get unlimited conversions & batch processing',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: _showPremiumDialog,
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF7C3AED),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                            ),
                            child: const Text('Upgrade',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Conversion Mode Toggle
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Material(
                            color: _conversionMode == 'to_pdf'
                                ? const Color(0xFF2563EB)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _conversionMode = 'to_pdf';
                                  _selectedFilePath = null;
                                  _selectedFileName = null;
                                  _selectedFormat = null;
                                  _isComplete = false;
                                });
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.arrow_forward,
                                      size: 18,
                                      color: _conversionMode == 'to_pdf'
                                          ? Colors.white
                                          : Colors.grey[700],
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'To PDF',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: _conversionMode == 'to_pdf'
                                            ? Colors.white
                                            : Colors.grey[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Material(
                            color: _conversionMode == 'from_pdf'
                                ? const Color(0xFF2563EB)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _conversionMode = 'from_pdf';
                                  _selectedFilePath = null;
                                  _selectedFileName = null;
                                  _selectedFormat = null;
                                  _isComplete = false;
                                });
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.arrow_back,
                                      size: 18,
                                      color: _conversionMode == 'from_pdf'
                                          ? Colors.white
                                          : Colors.grey[700],
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'From PDF',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: _conversionMode == 'from_pdf'
                                            ? Colors.white
                                            : Colors.grey[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // File Upload Section
                if (_selectedFileName == null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: Colors.grey[300]!,
                          width: 2,
                          strokeAlign: BorderSide.strokeAlignInside),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _pickFile,
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            children: [
                              Icon(Icons.upload_file,
                                  size: 64, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text(
                                _conversionMode == 'to_pdf'
                                    ? 'Select DOCX or Excel File'
                                    : 'Select a PDF File',
                                style: TextStyle(
                                  color: Colors.grey[900],
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Choose a file from your device to convert',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 20),
                              FilledButton(
                                onPressed: _pickFile,
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFF2563EB),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 32, vertical: 12),
                                ),
                                child: const Text('Choose File'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Row(
                      children: [
                        Text(_getFileIcon(_selectedFileName!),
                            style: const TextStyle(fontSize: 32)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedFileName!,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatFileSize(_selectedFileSize ?? 0),
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _selectedFilePath = null;
                              _selectedFileName = null;
                              _selectedFileSize = null;
                              _selectedFormat = null;
                              _isComplete = false;
                            });
                          },
                          child: const Text('Change'),
                        ),
                      ],
                    ),
                  ),

                // Conversion Options
                if (_selectedFileName != null && !_isComplete) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      'Select Output Format',
                      style: TextStyle(
                        color: Colors.grey[900],
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ..._currentOptions.map((option) {
                    final isSelected = _selectedFormat == option['id'];
                    final isPremiumOption = option['premium'] as bool;
                    final isLocked = isPremiumOption && !isPremium;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF2563EB)
                              : Colors.grey[200]!,
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: Colors.blue.withValues(alpha: 0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            if (isLocked) {
                              _showPremiumDialog();
                            } else {
                              setState(() {
                                _selectedFormat = option['id'] as String;
                              });
                            }
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFF2563EB)
                                            .withValues(alpha: 0.1)
                                        : Colors.grey[100],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    option['icon'] as IconData,
                                    color: isSelected
                                        ? const Color(0xFF2563EB)
                                        : Colors.grey[700],
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        option['label'] as String,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                          color: Colors.grey[900],
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        option['description'] as String,
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isLocked)
                                  const Icon(Icons.lock,
                                      color: Color(0xFF7C3AED), size: 20)
                                else if (isSelected)
                                  const Icon(Icons.check_circle,
                                      color: Color(0xFF2563EB), size: 20),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _isConverting ? null : _convertFile,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isConverting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Convert',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Conversion History
                if (conversions.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12, top: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Conversion History',
                          style: TextStyle(
                            color: Colors.grey[900],
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Clear History'),
                                content: const Text(
                                    'Are you sure you want to clear all conversion history?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Cancel'),
                                  ),
                                  FilledButton(
                                    onPressed: () {
                                      context
                                          .read<ConversionProvider>()
                                          .clearHistory();
                                      Navigator.pop(context);
                                    },
                                    style: FilledButton.styleFrom(
                                        backgroundColor: Colors.red),
                                    child: const Text('Clear'),
                                  ),
                                ],
                              ),
                            );
                          },
                          child: const Text('Clear All'),
                        ),
                      ],
                    ),
                  ),
                  ...conversions.map((conversion) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                // Source file icon
                                Text(_getFileIcon(conversion.sourceFileName),
                                    style: const TextStyle(fontSize: 24)),
                                const SizedBox(width: 8),
                                Icon(Icons.arrow_forward,
                                    size: 16, color: Colors.grey[600]),
                                const SizedBox(width: 8),
                                // Output file icon
                                Text(_getFileIcon(conversion.outputFileName),
                                    style: const TextStyle(fontSize: 24)),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        conversion.conversionType,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        _formatDate(conversion.conversionDate),
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (conversion.isSuccess)
                                  const Icon(Icons.check_circle,
                                      color: Colors.green, size: 20)
                                else
                                  const Icon(Icons.error,
                                      color: Colors.red, size: 20),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Source',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey[600],
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              conversion.sourceFileName,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Text(
                                              conversion.formattedSourceSize,
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Output',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey[600],
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              conversion.outputFileName,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Text(
                                              conversion.formattedOutputSize,
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
