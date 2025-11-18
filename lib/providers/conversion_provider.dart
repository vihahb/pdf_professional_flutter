import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ConversionRecord {
  final String id;
  final String sourceFileName;
  final String sourcePath;
  final String outputFileName;
  final String outputPath;
  final String conversionType;
  final DateTime conversionDate;
  final int sourceFileSize;
  final int outputFileSize;
  final bool isSuccess;
  final String? errorMessage;

  ConversionRecord({
    required this.id,
    required this.sourceFileName,
    required this.sourcePath,
    required this.outputFileName,
    required this.outputPath,
    required this.conversionType,
    required this.conversionDate,
    required this.sourceFileSize,
    required this.outputFileSize,
    this.isSuccess = true,
    this.errorMessage,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'sourceFileName': sourceFileName,
        'sourcePath': sourcePath,
        'outputFileName': outputFileName,
        'outputPath': outputPath,
        'conversionType': conversionType,
        'conversionDate': conversionDate.toIso8601String(),
        'sourceFileSize': sourceFileSize,
        'outputFileSize': outputFileSize,
        'isSuccess': isSuccess,
        'errorMessage': errorMessage,
      };

  factory ConversionRecord.fromJson(Map<String, dynamic> json) =>
      ConversionRecord(
        id: json['id'] as String,
        sourceFileName: json['sourceFileName'] as String,
        sourcePath: json['sourcePath'] as String,
        outputFileName: json['outputFileName'] as String,
        outputPath: json['outputPath'] as String,
        conversionType: json['conversionType'] as String,
        conversionDate: DateTime.parse(json['conversionDate'] as String),
        sourceFileSize: json['sourceFileSize'] as int,
        outputFileSize: json['outputFileSize'] as int,
        isSuccess: json['isSuccess'] as bool? ?? true,
        errorMessage: json['errorMessage'] as String?,
      );

  String get sourceFileExtension =>
      sourceFileName.split('.').last.toUpperCase();
  String get outputFileExtension =>
      outputFileName.split('.').last.toUpperCase();

  String getFormattedSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String get formattedSourceSize => getFormattedSize(sourceFileSize);
  String get formattedOutputSize => getFormattedSize(outputFileSize);
}

class ConversionProvider with ChangeNotifier {
  List<ConversionRecord> _conversions = [];
  static const String _storageKey = 'conversion_history';

  List<ConversionRecord> get conversions => List.unmodifiable(_conversions);

  ConversionProvider() {
    _loadConversions();
  }

  Future<void> _loadConversions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? conversionsJson = prefs.getString(_storageKey);
      if (conversionsJson != null) {
        final List<dynamic> decoded = json.decode(conversionsJson);
        _conversions = decoded
            .map((item) => ConversionRecord.fromJson(item as Map<String, dynamic>))
            .toList();
        // Sort by date, newest first
        _conversions.sort((a, b) => b.conversionDate.compareTo(a.conversionDate));
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading conversions: $e');
    }
  }

  Future<void> _saveConversions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String encoded = json.encode(
        _conversions.map((c) => c.toJson()).toList(),
      );
      await prefs.setString(_storageKey, encoded);
    } catch (e) {
      debugPrint('Error saving conversions: $e');
    }
  }

  Future<void> addConversion(ConversionRecord record) async {
    _conversions.insert(0, record); // Add to beginning (newest first)
    notifyListeners();
    await _saveConversions();
  }

  Future<void> removeConversion(String id) async {
    _conversions.removeWhere((c) => c.id == id);
    notifyListeners();
    await _saveConversions();
  }

  Future<void> clearHistory() async {
    _conversions.clear();
    notifyListeners();
    await _saveConversions();
  }

  List<ConversionRecord> getConversionsByType(String type) {
    return _conversions.where((c) => c.conversionType == type).toList();
  }

  int get totalConversions => _conversions.length;
  int get successfulConversions =>
      _conversions.where((c) => c.isSuccess).length;
  int get failedConversions => _conversions.where((c) => !c.isSuccess).length;
}
