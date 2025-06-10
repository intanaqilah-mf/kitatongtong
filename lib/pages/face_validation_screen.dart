import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

class FaceValidationScreen extends StatefulWidget {
  final String ekycSelfieImageUrl;

  const FaceValidationScreen({Key? key, required this.ekycSelfieImageUrl}) : super(key: key);

  @override
  _FaceValidationScreenState createState() => _FaceValidationScreenState();
}

class _FaceValidationScreenState extends State<FaceValidationScreen> {
  CameraController? _cameraController;
  Future<void>? _initializeControllerFuture;
  XFile? _newSelfie;
  bool _isCameraInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      // Prefer the front camera for selfies
      final frontCamera = cameras.firstWhere(
            (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.high,
      );

      _initializeControllerFuture = _cameraController!.initialize();
      await _initializeControllerFuture;

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error initializing camera: $e")),
        );
      }
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    try {
      await _initializeControllerFuture;
      final image = await _cameraController!.takePicture();
      if (mounted) {
        setState(() {
          _newSelfie = image;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to take picture: $e")),
        );
      }
    }
  }

  Widget _buildComparisonView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: 20),
          Text("Please Verify The Identity", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPhotoCard("eKYC Photo", Image.network(widget.ekycSelfieImageUrl, fit: BoxFit.cover)),
              _buildPhotoCard("Pickup Photo", Image.file(File(_newSelfie!.path), fit: BoxFit.cover)),
            ],
          ),
          SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context, false),
                icon: Icon(Icons.close, color: Colors.white),
                label: Text("Reject", style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red, minimumSize: Size(120, 50)),
              ),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context, true),
                icon: Icon(Icons.check, color: Colors.white),
                label: Text("Confirm", style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green, minimumSize: Size(120, 50)),
              ),
            ],
          ),
          SizedBox(height: 20),
          TextButton.icon(
            icon: Icon(Icons.camera_alt_outlined),
            onPressed: () => setState(() { _newSelfie = null; }),
            label: Text("Retake Photo"),
            style: TextButton.styleFrom(foregroundColor: Color(0xFFFDB515)),
          )
        ],
      ),
    );
  }

  Widget _buildPhotoCard(String title, Widget imageWidget) {
    return Column(
      children: [
        Text(title, style: TextStyle(color: Colors.white, fontSize: 16)),
        SizedBox(height: 8),
        Container(
          width: MediaQuery.of(context).size.width * 0.4,
          height: MediaQuery.of(context).size.width * 0.4,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Color(0xFFFDB515), width: 2),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: imageWidget,
          ),
        ),
      ],
    );
  }

  Widget _buildCameraView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text("Position Asnaf's face in the circle", style: TextStyle(color: Colors.white70, fontSize: 16), textAlign: TextAlign.center,),
        SizedBox(height: 20),
        Center(
          child: Container(
            width: 300,
            height: 300,
            child: _isCameraInitialized
                ? ClipOval(child: CameraPreview(_cameraController!))
                : Center(child: CircularProgressIndicator()),
          ),
        ),
        SizedBox(height: 30),
        ElevatedButton(
          onPressed: _isCameraInitialized ? _takePicture : null,
          style: ElevatedButton.styleFrom(
            shape: CircleBorder(),
            padding: EdgeInsets.all(20),
            backgroundColor: Colors.white,
          ),
          child: Icon(Icons.camera_alt, color: Colors.black, size: 40),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF303030),
      appBar: AppBar(
        title: Text('Pickup Face Verification'),
        backgroundColor: Colors.black,
        foregroundColor: Color(0xFFFDB515),
      ),
      body: _newSelfie == null ? _buildCameraView() : _buildComparisonView(),
    );
  }
}
