import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrScannerPage extends StatefulWidget {
  const QrScannerPage({super.key});

  @override
  State<QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<QrScannerPage> {
  final MobileScannerController controller = MobileScannerController(
    // Adjust controller settings here if needed for v6.0.10
    // e.g., detectionSpeed, formats, etc.
    // formats: [BarcodeFormat.qrCode], // Example: only scan QR codes
  );
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        backgroundColor: const Color(0xFF303030),
        iconTheme: const IconThemeData(color: Color(0xFFFDB515)),
        titleTextStyle: const TextStyle(color: Color(0xFFFDB515), fontSize: 20),
        actions: [
          IconButton(
            color: const Color(0xFFFDB515),
            icon: const Icon(Icons.flash_on), // Static icon
            tooltip: 'Toggle Torch',
            iconSize: 32.0,
            onPressed: () async {
              try {
                await controller.toggleTorch();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Torch error: ${e.toString()}')),
                  );
                }
                print("Error toggling torch: $e");
              }
            },
          ),
          IconButton(
            color: const Color(0xFFFDB515),
            icon: const Icon(Icons.flip_camera_ios), // Static icon
            tooltip: 'Switch Camera',
            iconSize: 32.0,
            onPressed: () async {
              try {
                await controller.switchCamera();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Camera switch error: ${e.toString()}')),
                  );
                }
                print("Error switching camera: $e");
              }
            },
          ),
        ],
      ),
      body: MobileScanner(
        controller: controller,
        onDetect: (capture) {
          if (_isProcessing) return;

          final List<Barcode> barcodes = capture.barcodes;
          if (barcodes.isNotEmpty) {
            final String? code = barcodes.first.rawValue;
            if (code != null && code.isNotEmpty) {
              if (mounted) {
                setState(() {
                  _isProcessing = true;
                });
                Navigator.pop(context, code);
              }
            }
          }
        },
        // SIMPLIFIED errorBuilder
        errorBuilder: (context, error, child) {
          print('MobileScanner errorBuilder caught: ${error.runtimeType} - ${error.toString()}');
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Scanner Error. Please try again.\n(${error.toString()})', // Using basic toString()
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}