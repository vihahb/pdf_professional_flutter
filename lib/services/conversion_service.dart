import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:archive/archive.dart';
import 'package:xml/xml.dart';
import 'package:excel/excel.dart' as excel_lib;
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class ConversionService {
  // Convert DOCX to PDF
  static Future<String> convertDocxToPdf(String docxPath) async {
    try {
      // Validate file extension
      final extension = docxPath.split('.').last.toLowerCase();
      if (extension != 'docx') {
        throw UnsupportedError(
          'Unsupported Word format. Only .docx files are supported. '
          'Please convert .doc files to .docx format first.',
        );
      }

      // Read the DOCX file
      final file = File(docxPath);
      final bytes = await file.readAsBytes();

      // Extract text from DOCX
      final text = await _extractTextFromDocx(bytes);

      // Create PDF
      final pdf = pw.Document();

      // Split text into lines for better formatting
      final lines = text.split('\n');
      final chunks = <String>[];
      String currentChunk = '';

      for (final line in lines) {
        if (currentChunk.length + line.length > 500) {
          chunks.add(currentChunk);
          currentChunk = line + '\n';
        } else {
          currentChunk += line + '\n';
        }
      }
      if (currentChunk.isNotEmpty) {
        chunks.add(currentChunk);
      }

      // Add pages to PDF
      for (final chunk in chunks) {
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            build: (pw.Context context) {
              return pw.Padding(
                padding: const pw.EdgeInsets.all(40),
                child: pw.Text(
                  chunk,
                  style: const pw.TextStyle(fontSize: 12),
                ),
              );
            },
          ),
        );
      }

      // Save PDF
      final outputPath = await _getOutputPath(docxPath, 'pdf');
      final outputFile = File(outputPath);
      await outputFile.writeAsBytes(await pdf.save());

      return outputPath;
    } catch (e) {
      debugPrint('Error converting DOCX to PDF: $e');
      rethrow;
    }
  }

  // Extract text from DOCX
  static Future<String> _extractTextFromDocx(Uint8List bytes) async {
    try {
      final archive = ZipDecoder().decodeBytes(bytes);

      // Find document.xml
      final documentXml = archive.firstWhere(
        (file) => file.name == 'word/document.xml',
      );

      final content = String.fromCharCodes(documentXml.content as List<int>);
      final document = XmlDocument.parse(content);

      // Extract all text nodes
      final textNodes = document.findAllElements('w:t');
      final buffer = StringBuffer();

      for (final node in textNodes) {
        buffer.write(node.innerText);
        // Add space between text nodes
        buffer.write(' ');
      }

      // Extract paragraph breaks
      final paragraphs = document.findAllElements('w:p');
      final result = StringBuffer();

      for (final para in paragraphs) {
        final texts = para.findAllElements('w:t');
        for (final text in texts) {
          result.write(text.innerText);
        }
        result.write('\n');
      }

      return result.toString().trim();
    } catch (e) {
      debugPrint('Error extracting text from DOCX: $e');
      // Fallback to simple text extraction
      return 'Unable to extract text from document. Please ensure the file is a valid DOCX file.';
    }
  }

  // Convert Excel to PDF
  static Future<String> convertExcelToPdf(String excelPath) async {
    try {
      // Validate file extension
      final extension = excelPath.split('.').last.toLowerCase();
      if (extension != 'xlsx') {
        throw UnsupportedError(
          'Unsupported Excel format. Only .xlsx files are supported. '
          'Please convert .xls files to .xlsx format first.',
        );
      }

      // Read the Excel file
      final file = File(excelPath);
      final bytes = await file.readAsBytes();

      final excelFile = excel_lib.Excel.decodeBytes(bytes);

      // Create PDF
      final pdf = pw.Document();

      // Process each sheet
      for (final sheetName in excelFile.tables.keys) {
        final sheet = excelFile.tables[sheetName];
        if (sheet == null) continue;

        // Create table data
        final tableData = <List<String>>[];

        for (final row in sheet.rows) {
          final rowData = <String>[];
          for (final cell in row) {
            rowData.add(cell?.value?.toString() ?? '');
          }
          tableData.add(rowData);
        }

        // Add page with table
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4.landscape,
            build: (pw.Context context) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    sheetName,
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Table.fromTextArray(
                    data: tableData,
                    cellStyle: const pw.TextStyle(fontSize: 8),
                    headerStyle: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 9,
                    ),
                    cellAlignment: pw.Alignment.centerLeft,
                    border: pw.TableBorder.all(color: PdfColors.grey),
                  ),
                ],
              );
            },
          ),
        );
      }

      // Save PDF
      final outputPath = await _getOutputPath(excelPath, 'pdf');
      final outputFile = File(outputPath);
      await outputFile.writeAsBytes(await pdf.save());

      return outputPath;
    } catch (e) {
      debugPrint('Error converting Excel to PDF: $e');
      rethrow;
    }
  }

  // Convert PDF to DOCX (simple text extraction)
  static Future<String> convertPdfToDocx(String pdfPath) async {
    try {
      // For now, create a simple text file with .docx extension
      // In production, you'd use a proper DOCX library or API
      final text = await _extractTextFromPdf(pdfPath);

      final outputPath = await _getOutputPath(pdfPath, 'docx');
      final outputFile = File(outputPath);

      // Create a simple DOCX (for demo purposes, this is simplified)
      // In production, use a proper DOCX generation library
      await outputFile.writeAsString(text);

      return outputPath;
    } catch (e) {
      debugPrint('Error converting PDF to DOCX: $e');
      rethrow;
    }
  }

  // Convert PDF to Excel (simple table extraction)
  static Future<String> convertPdfToExcel(String pdfPath) async {
    try {
      final text = await _extractTextFromPdf(pdfPath);

      // Create Excel file
      final excelFile = excel_lib.Excel.createExcel();
      final sheet = excelFile['Sheet1'];

      // Split text into lines and add to Excel
      final lines = text.split('\n');
      for (var i = 0; i < lines.length; i++) {
        sheet.appendRow([excel_lib.TextCellValue(lines[i])]);
      }

      // Save Excel
      final outputPath = await _getOutputPath(pdfPath, 'xlsx');
      final outputFile = File(outputPath);
      final excelBytes = excelFile.encode();
      if (excelBytes != null) {
        await outputFile.writeAsBytes(excelBytes);
      }

      return outputPath;
    } catch (e) {
      debugPrint('Error converting PDF to Excel: $e');
      rethrow;
    }
  }

  // Convert PDF to Text
  static Future<String> convertPdfToText(String pdfPath) async {
    try {
      final text = await _extractTextFromPdf(pdfPath);

      final outputPath = await _getOutputPath(pdfPath, 'txt');
      final outputFile = File(outputPath);
      await outputFile.writeAsString(text);

      return outputPath;
    } catch (e) {
      debugPrint('Error converting PDF to Text: $e');
      rethrow;
    }
  }

  // Extract text from PDF (placeholder - would need PDF text extraction library)
  static Future<String> _extractTextFromPdf(String pdfPath) async {
    // For now, return a placeholder text
    // In production, use a PDF text extraction library
    return 'PDF text extraction requires additional libraries.\n'
        'This is a placeholder for the extracted content from: ${pdfPath.split('/').last}';
  }

  // Get output file path
  static Future<String> _getOutputPath(String inputPath, String extension) async {
    final directory = await getApplicationDocumentsDirectory();
    final inputFileName = inputPath.split('/').last;
    final nameWithoutExtension = inputFileName.substring(
      0,
      inputFileName.lastIndexOf('.'),
    );
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${directory.path}/${nameWithoutExtension}_$timestamp.$extension';
  }

  // Get file size
  static Future<int> getFileSize(String filePath) async {
    final file = File(filePath);
    return await file.length();
  }

  // Get file extension
  static String getFileExtension(String filePath) {
    return filePath.split('.').last.toUpperCase();
  }

  // Check if file is supported
  static bool isSupportedFile(String filePath) {
    final extension = getFileExtension(filePath).toLowerCase();
    return ['pdf', 'docx', 'xlsx'].contains(extension);
  }

  // Get conversion type label
  static String getConversionTypeLabel(String sourceExt, String targetExt) {
    return '${sourceExt.toUpperCase()} to ${targetExt.toUpperCase()}';
  }
}
