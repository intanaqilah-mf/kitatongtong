import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'dart:io';

class PDFViewerScreen extends StatelessWidget {
  final String filePath;

  PDFViewerScreen({required this.filePath});

  @override
  Widget build(BuildContext context) {
    print("File path received in PDFViewerScreen: $filePath"); // Debug log
    return Scaffold(
      appBar: AppBar(
        title: Text("PDF Viewer"),
      ),
      body: filePath.isNotEmpty
          ? SfPdfViewer.file(File(filePath))
          : Center(
        child: Text("Unable to load PDF. File path is empty."),
      ),
    );
  }
}
