import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

class EkycScreen extends StatefulWidget {
  const EkycScreen({Key? key}) : super(key: key);

  @override
  _EkycScreenState createState() => _EkycScreenState();
}

class _EkycScreenState extends State<EkycScreen> {
  File? _nricImageFile;
  File? _selfieImageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  String _nricNumber = '';
  String _nricName = '';

  // Initialize ML Kit detectors
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      performanceMode: FaceDetectorMode.accurate,
    ),
  );
  final TextRecognizer _textRecognizer = TextRecognizer();

  // Function to capture NRIC photo
  Future<void> _captureNricPhoto() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() {
        _nricImageFile = File(image.path);
      });
    }
  }

  // Function to capture Selfie photo
  Future<void> _captureSelfie() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front, // Prefer the front camera
    );
    if (image != null) {
      setState(() {
        _selfieImageFile = File(image.path);
      });
    }
  }

  // The main validation and upload logic
  Future<void> _validateAndUpload() async {
    if (_nricImageFile == null || _selfieImageFile == null) {
      _showErrorDialog("Please capture both NRIC and Selfie images.");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Validate images using ML Kit
      final bool isNricValid = await _validateNricImage(_nricImageFile!);
      if (!isNricValid) {
        _showErrorDialog("NRIC validation failed. Please ensure the photo is clear, includes a face, and has readable text.");
        setState(() { _isLoading = false; });
        return;
      }

      final bool isSelfieValid = await _validateSelfieImage(_selfieImageFile!);
      if (!isSelfieValid) {
        _showErrorDialog("Selfie validation failed. Please ensure your face is clearly visible in the selfie.");
        setState(() { _isLoading = false; });
        return;
      }

      // 2. Upload images to Firebase Storage
      final String userId = FirebaseAuth.instance.currentUser!.uid;
      final String nricImageUrl = await _uploadFile(_nricImageFile!, 'users/$userId/nric.jpg');
      final String selfieImageUrl = await _uploadFile(_selfieImageFile!, 'users/$userId/selfie.jpg');

      // 3. Update user data in Firestore
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'nric': _nricNumber, // Extracted NRIC number
        'name': _nricName,   // Extracted Name
        'nricImageUrl': nricImageUrl,
        'selfieImageUrl': selfieImageUrl,
        'ekycVerifiedOn': FieldValue.serverTimestamp(),
      });

      // If successful, pop the screen and return true
      Navigator.of(context).pop(true);

    } catch (e) {
      _showErrorDialog("An error occurred during eKYC process: ${e.toString()}");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // ML Kit validation for NRIC
  Future<bool> _validateNricImage(File image) async {
    final inputImage = InputImage.fromFile(image);

    // Run face detection
    final List<Face> faces = await _faceDetector.processImage(inputImage);
    if (faces.isEmpty) {
      print("Validation failed: No face detected in NRIC image.");
      return false; // Fail if no face is on the NRIC
    }

    // Run text recognition
    final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
    if (recognizedText.text.isEmpty) {
      print("Validation failed: No text detected in NRIC image.");
      return false; // Fail if no text is found
    }

    // Attempt to extract NRIC and Name (this part may need adjustment based on NRIC format)
    // This is a simplified example. You might need more robust parsing logic.
    final nricRegex = RegExp(r'\d{6}-\d{2}-\d{4}');
    final nameRegex = RegExp(r'Name\s*:\s*(.*)', caseSensitive: false);

    setState(() {
      _nricNumber = nricRegex.firstMatch(recognizedText.text)?.group(0) ?? 'Not Found';
      _nricName = nameRegex.firstMatch(recognizedText.text)?.group(1) ?? 'Not Found';
    });

    if (_nricNumber == 'Not Found') {
      print("Validation failed: Could not extract NRIC number.");
      return false;
    }

    return true;
  }

  // ML Kit validation for Selfie
  Future<bool> _validateSelfieImage(File image) async {
    final inputImage = InputImage.fromFile(image);
    final List<Face> faces = await _faceDetector.processImage(inputImage);
    // Ensure exactly one face is detected in the selfie
    return faces.length == 1;
  }

  // Helper to upload a file to Firebase Storage
  Future<String> _uploadFile(File file, String path) async {
    final ref = FirebaseStorage.instance.ref().child(path);
    final uploadTask = ref.putFile(file);
    final snapshot = await uploadTask.whenComplete(() => {});
    return await snapshot.ref.getDownloadURL();
  }

  // Helper to show an error dialog
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Validation Error'),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: Text('Okay'),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    _faceDetector.close();
    _textRecognizer.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("eKYC Verification"),
        backgroundColor: Color(0xFFFDB515),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // NRIC Capture Section
            _buildImageCaptureBox(
              title: "1. Capture NRIC Photo",
              imageFile: _nricImageFile,
              onTap: _captureNricPhoto,
            ),
            SizedBox(height: 24),

            // Selfie Capture Section
            _buildImageCaptureBox(
              title: "2. Take a Selfie",
              imageFile: _selfieImageFile,
              onTap: _captureSelfie,
            ),
            SizedBox(height: 40),

            // Submit Button
            if (!_isLoading)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFFFCF40),
                  foregroundColor: Colors.black,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                onPressed: _validateAndUpload,
                child: Text("Verify & Submit"),
              ),
            if (_isLoading)
              Center(
                child: CircularProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageCaptureBox({
    required String title,
    required File? imageFile,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        SizedBox(height: 12),
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Color(0xFFFFCF40), width: 2),
              image: imageFile != null
                  ? DecorationImage(image: FileImage(imageFile), fit: BoxFit.cover)
                  : null,
            ),
            child: imageFile == null
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.camera_alt, color: Color(0xFFFFCF40), size: 50),
                  SizedBox(height: 8),
                  Text("Tap to open camera", style: TextStyle(color: Colors.white70)),
                ],
              ),
            )
                : null,
          ),
        ),
      ],
    );
  }
}
