import 'package:flutter/foundation.dart';
import 'dart:io';

class PdfDocument {
  final String id;
  final String name;
  final String path;
  final DateTime createdAt;
  final int size;

  PdfDocument({
    required this.id,
    required this.name,
    required this.path,
    required this.createdAt,
    required this.size,
  });
}

class PdfProvider with ChangeNotifier {
  final List<PdfDocument> _documents = [];
  PdfDocument? _currentDocument;
  bool _isLoading = false;

  List<PdfDocument> get documents => _documents;
  PdfDocument? get currentDocument => _currentDocument;
  bool get isLoading => _isLoading;

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void addDocument(PdfDocument document) {
    _documents.insert(0, document);
    notifyListeners();
  }

  void removeDocument(String id) {
    _documents.removeWhere((doc) => doc.id == id);
    if (_currentDocument?.id == id) {
      _currentDocument = null;
    }
    notifyListeners();
  }

  void setCurrentDocument(PdfDocument? document) {
    _currentDocument = document;
    notifyListeners();
  }

  void clearDocuments() {
    _documents.clear();
    _currentDocument = null;
    notifyListeners();
  }

  Future<void> deleteDocumentFile(String id) async {
    final doc = _documents.firstWhere((d) => d.id == id);
    try {
      final file = File(doc.path);
      if (await file.exists()) {
        await file.delete();
      }
      removeDocument(id);
    } catch (e) {
      debugPrint('Error deleting document: $e');
    }
  }
}
