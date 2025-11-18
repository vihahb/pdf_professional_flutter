import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../providers/premium_provider.dart';

class ConverterScreen extends StatefulWidget {
  const ConverterScreen({super.key});

  @override
  State<ConverterScreen> createState() => _ConverterScreenState();
}

class _ConverterScreenState extends State<ConverterScreen> {
  String? _selectedFile;
  String? _selectedFormat;
  bool _isConverting = false;
  bool _isComplete = false;

  final List<Map<String, dynamic>> _conversionOptions = [
    {
      'id': 'word',
      'icon': Icons.description,
      'label': 'PDF to Word',
      'description': 'Convert to .docx format',
      'premium': false,
    },
    {
      'id': 'excel',
      'icon': Icons.table_chart,
      'label': 'PDF to Excel',
      'description': 'Convert to .xlsx format',
      'premium': true,
    },
    {
      'id': 'image',
      'icon': Icons.image,
      'label': 'PDF to Images',
      'description': 'Convert to .jpg or .png',
      'premium': false,
    },
    {
      'id': 'text',
      'icon': Icons.text_snippet,
      'label': 'PDF to Text',
      'description': 'Extract text to .txt',
      'premium': false,
    },
  ];

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedFile = result.files.single.name;
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
    if (_selectedFormat == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an output format')),
      );
      return;
    }

    setState(() {
      _isConverting = true;
    });

    // Simulate conversion
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isConverting = false;
      _isComplete = true;
    });
  }

  void _showPremiumDialog() {
    final premiumProvider = context.read<PremiumProvider>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.workspace_premium,
              color: Theme.of(context).colorScheme.secondary,
            ),
            const SizedBox(width: 8),
            const Text('Premium Feature'),
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

  @override
  Widget build(BuildContext context) {
    final isPremium = context.watch<PremiumProvider>().isPremium;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Header
          SliverAppBar(
            expandedHeight: 0,
            floating: true,
            pinned: true,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            automaticallyImplyLeading: false,
            title: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Builder(
                builder: (context) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PDF Converter',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Convert PDFs to different formats',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
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
                          const Icon(Icons.workspace_premium, color: Colors.white, size: 32),
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
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            ),
                            child: const Text('Upgrade', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  ),

                // File Upload Section
                if (_selectedFile == null)
                  Builder(
                    builder: (context) => Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline,
                          width: 2,
                          strokeAlign: BorderSide.strokeAlignInside,
                        ),
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
                                Icon(
                                  Icons.upload_file,
                                  size: 64,
                                  color: Theme.of(context).iconTheme.color?.withValues(alpha: 0.6),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Select a PDF File',
                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Choose a file from your device to convert',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 20),
                                FilledButton(
                                  onPressed: _pickFile,
                                  style: FilledButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                                  ),
                                  child: const Text('Choose File'),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Free users: 3 conversions per day',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  Builder(
                    builder: (context) => Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Text('📄', style: TextStyle(fontSize: 32)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedFile!,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '2.4 MB • 15 pages',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _selectedFile = null;
                                _selectedFormat = null;
                                _isComplete = false;
                              });
                            },
                            child: const Text('Change'),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Conversion Options
                if (_selectedFile != null && !_isComplete) ...[
                  Builder(
                    builder: (context) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        'Select Output Format',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                  ),
                  ..._conversionOptions.map((option) {
                    final isSelected = _selectedFormat == option['id'];
                    final isPremiumOption = option['premium'] as bool;
                    final isLocked = isPremiumOption && !isPremium;

                    return Builder(
                      builder: (context) {
                        final colorScheme = Theme.of(context).colorScheme;
                        final textTheme = Theme.of(context).textTheme;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? colorScheme.primary
                                  : colorScheme.outline.withValues(alpha: 0.3),
                              width: isSelected ? 2 : 1,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: colorScheme.primary.withValues(alpha: 0.2),
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
                                            ? colorScheme.primary.withValues(alpha: 0.1)
                                            : colorScheme.surfaceContainerHighest,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        option['icon'] as IconData,
                                        color: isSelected
                                            ? colorScheme.primary
                                            : colorScheme.onSurfaceVariant,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            option['label'] as String,
                                            style: textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            option['description'] as String,
                                            style: textTheme.bodySmall,
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (isLocked)
                                      Icon(
                                        Icons.lock,
                                        color: colorScheme.secondary,
                                        size: 20,
                                      )
                                    else if (isSelected)
                                      Icon(
                                        Icons.check_circle,
                                        color: colorScheme.primary,
                                        size: 20,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  }),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _isConverting ? null : _convertFile,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isConverting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Convert', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],

                // Conversion Complete
                if (_isComplete) ...[
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green[200]!),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green[600], size: 64),
                        const SizedBox(height: 16),
                        Text(
                          'Conversion Complete!',
                          style: TextStyle(
                            color: Colors.green[900],
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Your file has been converted successfully',
                          style: TextStyle(
                            color: Colors.green[700],
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.download),
                          label: const Text('Download'),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.green[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

