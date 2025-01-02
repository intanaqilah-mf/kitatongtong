import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';

class PDFViewerScreen extends StatelessWidget {
  final String filePath;

  PDFViewerScreen({required this.filePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("PDF Viewer"),
        backgroundColor: Color(0xFF303030),
      ),
      body: PDFView(
        filePath: filePath,
      ),
    );
  }
}
