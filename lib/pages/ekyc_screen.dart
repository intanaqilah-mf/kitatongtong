import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:projects/localization/app_localizations.dart';

class EkycScreen extends StatefulWidget {
  // Add isStaffMode to differentiate the workflow
  final bool isStaffMode;

  const EkycScreen({Key? key, this.isStaffMode = false}) : super(key: key);

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

  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      performanceMode: FaceDetectorMode.accurate,
    ),
  );
  final TextRecognizer _textRecognizer = TextRecognizer();

  Future<void> _captureNricPhoto() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() {
        _nricImageFile = File(image.path);
      });
    }
  }

  Future<void> _captureSelfie() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
    );
    if (image != null) {
      setState(() {
        _selfieImageFile = File(image.path);
      });
    }
  }

  /// Validates images and either returns data (Staff) or saves data (Asnaf).
  Future<void> _validateAndUpload() async {
    if (_nricImageFile == null || _selfieImageFile == null) {
      _showErrorDialog(AppLocalizations.of(context).translate('ekyc_error_missing_images'));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // NEW: Check NRIC image and get a specific error message if it fails.
      final String? nricValidationError = await _validateNricImage(_nricImageFile!);
      if (nricValidationError != null) {
        _showErrorDialog(nricValidationError); // Show the specific error from validation.
        if(mounted) setState(() { _isLoading = false; });
        return;
      }

      final bool isSelfieValid = await _validateSelfieImage(_selfieImageFile!);
      if (!isSelfieValid) {
        _showErrorDialog(AppLocalizations.of(context).translate('ekyc_error_selfie_validation_failed'));
        if(mounted) setState(() { _isLoading = false; });
        return;
      }

      // Staff Mode returns a Map of data back to the ApplyAid screen.
      if (widget.isStaffMode) {
        if(mounted) {
          Navigator.of(context).pop({
            'nric': _nricNumber,
            'name': _nricName,
          });
        }
        return; // Stop execution for staff.
      }

      // Original flow for Asnaf: Save data to their own profile.
      final String userId = FirebaseAuth.instance.currentUser!.uid;
      final String nricImageUrl = await _uploadFile(_nricImageFile!, 'users/$userId/nric.jpg');
      final String selfieImageUrl = await _uploadFile(_selfieImageFile!, 'users/$userId/selfie.jpg');

      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        'nric': _nricNumber,
        'name': _nricName,
        'nricImageUrl': nricImageUrl,
        'selfieImageUrl': selfieImageUrl,
        'ekycVerifiedOn': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Pop with 'true' for success for the Asnaf flow.
      if(mounted) Navigator.of(context).pop(true);

    } catch (e) {
      _showErrorDialog(AppLocalizations.of(context).translateWithArgs('ekyc_error_generic', {'error': e.toString()}));
    } finally {
      if(mounted){
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<String?> _validateNricImage(File image) async {
    final localizations = AppLocalizations.of(context);
    final inputImage = InputImage.fromFile(image);

    // 1. Face detection on NRIC
    final List<Face> faces = await _faceDetector.processImage(inputImage);
    if (faces.isEmpty) {
      final error = localizations.translate('ekyc_error_no_face');
      print("Validation failed: $error");
      return error;
    }

    // 2. Text recognition on NRIC
    final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
    final String fullText = recognizedText.text;
    if (fullText.isEmpty) {
      final error = localizations.translate('ekyc_error_no_text');
      print("Validation failed: $error");
      return error;
    }

    // 3. ENHANCED: Extract NRIC number with a more flexible regex
    final nricRegex = RegExp(r'(\d{6})\s*-\s*(\d{2})\s*-\s*(\d{4})');
    final nricMatch = nricRegex.firstMatch(fullText);
    if (nricMatch == null) {
      // Create a more specific and user-friendly error message
      final error = AppLocalizations.of(context).translate('ekyc_error_no_nric');
      print("Validation failed: $error. Full text was: \n$fullText");
      _showErrorDialog(error); // Show immediate feedback
      return error;
    }
    // Re-format to ensure consistency: XXXXXX-XX-XXXX
    _nricNumber = '${nricMatch.group(1)}-${nricMatch.group(2)}-${nricMatch.group(3)}';
    print("✅ Extracted NRIC: $_nricNumber");

    // 4. ENHANCED: Extract Name with more robust logic
    final List<String> lines = fullText.split('\n');
    String foundName = '';

    // Strategy 1: Look for "NAMA" and grab the text after it on the same line or the next line.
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (RegExp(r'\bNAMA\b', caseSensitive: false).hasMatch(line)) {
        // Check the same line first
        String potentialName = line.replaceAll(RegExp(r'.*NAMA\s*:?\s*', caseSensitive: false), '').trim();
        if (potentialName.isNotEmpty && potentialName.split(' ').length >= 2) {
          foundName = potentialName;
          break;
        }
        // Check the next line if same line is not fruitful
        if (i + 1 < lines.length) {
          potentialName = lines[i + 1].trim();
          if (potentialName.isNotEmpty && potentialName.split(' ').length >= 2) {
            foundName = potentialName;
            break;
          }
        }
      }
    }

    // Strategy 2: Fallback to find the longest, all-caps line without keywords if Strategy 1 fails.
    if (foundName.isEmpty) {
      List<String> candidates = [];
      for (String line in lines) {
        final trimmedLine = line.trim();
        // A good name candidate is all uppercase, has at least two parts, no digits, and isn't a known keyword.
        if (trimmedLine.toUpperCase() == trimmedLine &&
            trimmedLine.split(' ').where((s) => s.isNotEmpty).length >= 2 &&
            !trimmedLine.contains(RegExp(r'\d')) &&
            !RegExp(r'KAD PENGENALAN|MALAYSIA|NAMA|ALAMAT|IC|NO|MYKAD|NEGARA', caseSensitive: false).hasMatch(trimmedLine)) {
          candidates.add(trimmedLine);
        }
      }
      if (candidates.isNotEmpty) {
        // Sort by length to find the most likely name
        candidates.sort((a, b) => b.length.compareTo(a.length));
        foundName = candidates.first;
      }
    }

    if (foundName.isEmpty) {
      // Create a more specific and user-friendly error message
      final error = AppLocalizations.of(context).translate('ekyc_error_no_name');
      print("Validation failed: $error. Full text was: \n$fullText");
      _showErrorDialog(error); // Show immediate feedback
      return error;
    }
    _nricName = foundName.replaceAll(RegExp(r'[^A-Z\s]'), '').trim(); // Clean up the name
    print("✅ Extracted Name: $_nricName");

    if (mounted) setState(() {});
    return null; // Return null on success
  }

  Future<bool> _validateSelfieImage(File image) async {
    final inputImage = InputImage.fromFile(image);
    final List<Face> faces = await _faceDetector.processImage(inputImage);
    return faces.length == 1; // Ensure only one face is in the selfie
  }

  Future<String> _uploadFile(File file, String path) async {
    final ref = FirebaseStorage.instance.ref().child(path);
    final uploadTask = ref.putFile(file);
    final snapshot = await uploadTask.whenComplete(() => {});
    return await snapshot.ref.getDownloadURL();
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;
    final localizations = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(localizations.translate('ekyc_validation_error_title')),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: Text(localizations.translate('ok')),
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
    final localizations = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.translate('ekyc_title')),
        backgroundColor: Color(0xFFFDB515),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildImageCaptureBox(
              title: localizations.translate('ekyc_capture_nric_title'),
              imageFile: _nricImageFile,
              onTap: _captureNricPhoto,
            ),
            SizedBox(height: 24),
            _buildImageCaptureBox(
              title: localizations.translate('ekyc_capture_selfie_title'),
              imageFile: _selfieImageFile,
              onTap: _captureSelfie,
            ),
            SizedBox(height: 40),
            if (!_isLoading)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFFFCF40),
                  foregroundColor: Colors.black,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                onPressed: (_nricImageFile != null && _selfieImageFile != null) ? _validateAndUpload : null,
                child: Text(localizations.translate('ekyc_verify_submit_button')),
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
    final localizations = AppLocalizations.of(context);
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
                  Text(localizations.translate('ekyc_tap_to_open_camera'), style: TextStyle(color: Colors.white70)),
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