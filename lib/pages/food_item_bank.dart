import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:projects/widgets/bottomNavBar.dart';
import 'package:path/path.dart' as path;
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FoodItemBank extends StatefulWidget {
  @override
  _FoodItemBankState createState() => _FoodItemBankState();
}

class _FoodItemBankState extends State<FoodItemBank> {
  final _formKey = GlobalKey<FormState>();
  final _picker  = ImagePicker();

  String _selectedType = 'Food';
  String _itemCategory = 'Clothes';
  bool   _isNew        = true;
  bool   _wantsTax     = false;
  File?  _proofImage;

  final _itemNameCtrl = TextEditingController();
  final _numberCtrl   = TextEditingController();
  final _valueCtrl    = TextEditingController();
  final _nameCtrl     = TextEditingController();
  final _phoneCtrl    = TextEditingController();
  final _emailCtrl    = TextEditingController();


  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _nameCtrl.text  = user.displayName ?? '';
      _emailCtrl.text = user.email       ?? '';
      _phoneCtrl.text = user.phoneNumber ?? '';
    }
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _proofImage = File(picked.path));
  }


  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    String? imageUrl;
    try {
      if (_proofImage != null) {
        // 1️⃣ Upload image to Storage
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(_proofImage!.path)}';
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('fooditembank_images')
            .child(fileName);

        final uploadTask = storageRef.putFile(_proofImage!);
        final snapshot  = await uploadTask;
        imageUrl = await snapshot.ref.getDownloadURL();
      }

      // 2️⃣ Write to Firestore
      await FirebaseFirestore.instance
          .collection('fooditembank')
          .add({
        'type'           : _selectedType,
        'estimatedValue' : double.tryParse(_valueCtrl.text) ?? 0.0,
        'giverName'      : _nameCtrl.text.trim(),
        'phoneNumber'    : _phoneCtrl.text.trim(),
        'email'          : _emailCtrl.text.trim(),
        'taxExemption'   : _wantsTax,
        'imageUrl'       : imageUrl,                  // ← download URL or null
        'createdAt'      : FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Submitted successfully!'))
      );
      Navigator.of(context).pop();

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'))
      );
    }
  }

  Widget _field(TextEditingController c, String hint,
      {TextInputType type = TextInputType.text}) {
    return Container(
      height: 30,
      decoration: BoxDecoration(
        color: const Color(0xFFFFCF40),
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextFormField(
        controller: c,
        keyboardType: type,
        textAlignVertical: TextAlignVertical.center,    // ← NEW
        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
        decoration: InputDecoration(
          hintText: hint,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12,  vertical: 6),
        ),
      ),
    );
  }

  Widget _dropdown(List<String> items, String sel, ValueChanged<String?> onCh) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFCF40),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButton<String>(
        value: sel,
        isExpanded: true,
        underline: const SizedBox(),
        dropdownColor: const Color(0xFFFFCF40),
        items: items
            .map((e) => DropdownMenuItem(
          value: e,
          child: Text(e, style: const TextStyle(color: Colors.black)),
        ))
            .toList(),
        onChanged: onCh,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1C1C),
        elevation: 0,
        title: const Text(
          'Food / Item Bank',
          style: TextStyle(color: Color(0xFFFDB515)),
        ),
        centerTitle: true,
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: 2,
        onItemTapped: (idx) {},
      ),
      body: SafeArea(
        child: ListView(
          // give bottom padding so content scrolls above the nav bar
          padding: EdgeInsets.fromLTRB(
            16,                                       // left
            16,                                       // top
            16,                                       // right
            kBottomNavigationBarHeight + 16,          // bottom
          ),
          children: [
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // TYPE
                  const Text('Type',
                      style: TextStyle(color: Color(0xFFF1D789), fontSize: 14)),
                  const SizedBox(height: 4),
                  _dropdown(
                    ['Food', 'Item'],
                    _selectedType,
                        (v) => setState(() => _selectedType = v!),
                  ),
                  const SizedBox(height: 16),

                  // ITEM‐ONLY FIELDS
                  if (_selectedType == 'Item') ...[
                    const Text('Item Name',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    _field(_itemNameCtrl, 'Enter item name'),
                    const SizedBox(height: 16),

                    const Text('Type of Item',
                        style:
                        TextStyle(color: Color(0xFFF1D789), fontSize: 14)),
                    const SizedBox(height: 4),
                    _dropdown(
                      ['Clothes', 'Accessory', 'Baby Stuff', 'School Stuff', 'Other'],
                      _itemCategory,
                          (v) => setState(() => _itemCategory = v!),
                    ),
                    const SizedBox(height: 16),

                    const Text('Number of Items',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    _field(_numberCtrl, '0', type: TextInputType.number),
                    const SizedBox(height: 16),

                    Row(children: [
                      Checkbox(
                          value: _isNew,
                          activeColor: const Color(0xFFFDB515),
                          onChanged: (v) => setState(() => _isNew = v!)),
                      const Text('New', style: TextStyle(color: Colors.white)),
                      const SizedBox(width: 16),
                      Checkbox(
                          value: !_isNew,
                          activeColor: const Color(0xFFFDB515),
                          onChanged: (v) => setState(() => _isNew = !v!)),
                      const Text('Used', style: TextStyle(color: Colors.white)),
                    ]),
                    const SizedBox(height: 16),

                    const Text('Proof of Pic',
                        style: TextStyle(color: Color(0xFFF1D789), fontSize: 14)),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 100,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFCF40),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: _proofImage == null
                              ? const Text('Tap to upload image',
                              style: TextStyle(color: Colors.black))
                              : Image.file(_proofImage!, fit: BoxFit.cover),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ESTIMATED VALUE
                  const Text('Estimated Value (RM)',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  _field(_valueCtrl, '0.00', type: TextInputType.number),
                  const SizedBox(height: 24),

                  // GIVER INFO
                  const Text('Giver Name',
                      style: TextStyle(color: Color(0xFFF1D789), fontSize: 14)),
                  const SizedBox(height: 4),
                  _field(_nameCtrl, 'Enter your name'),
                  const SizedBox(height: 16),

                  const Text('Phone Number',
                      style: TextStyle(color: Color(0xFFF1D789), fontSize: 14)),
                  const SizedBox(height: 4),
                  _field(_phoneCtrl, 'Enter your phone number', type: TextInputType.phone),
                  const SizedBox(height: 16),

                  const Text('Email',
                      style: TextStyle(color: Color(0xFFF1D789), fontSize: 14)),
                  const SizedBox(height: 4),
                  _field(_emailCtrl, 'Enter your email', type: TextInputType.emailAddress),
                  const SizedBox(height: 24),

                  // TAX‐EXEMPTION QUESTION (split)
                  const Text(
                    'Would you like a tax-exemption letter?',
                    style: TextStyle(color: Color(0xFFF1D789)),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Radio<bool>(
                        value: true,
                        groupValue: _wantsTax,
                        activeColor: Color(0xFFFDB515),
                        onChanged: (v) => setState(() => _wantsTax = v!),
                      ),
                      const Text('Yes', style: TextStyle(color: Colors.white)),
                      const SizedBox(width: 24),
                      Radio<bool>(
                        value: false,
                        groupValue: _wantsTax,
                        activeColor: Color(0xFFFDB515),
                        onChanged: (v) => setState(() => _wantsTax = v!),
                      ),
                      const Text('No', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                  const SizedBox(height: 32),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1) The section title
                      Text(
                        'Picture of Food/Item',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFF1D789),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // 2) The upload button styled 1:1 with applyAid
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFFFCF40),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: EdgeInsets.zero, // we’ll size via the child Container
                        ),
                        onPressed: () async {
                          FilePickerResult? result = await FilePicker.platform.pickFiles(
                            type: FileType.image,
                            allowedExtensions: ['jpg', 'jpeg', 'png'],
                          );
                          if (result != null) {
                            setState(() {
                              _proofImage = File(result.files.single.path!);
                            });
                          }
                        },
                        child: Container(
                          height: 90,            // same as applyAid
                          width: double.infinity,
                          child: Center(
                            child: _proofImage == null
                            // 2a) no file yet → icon + label + subtitle
                                ? Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.asset('assets/uploadAsnaf.png', height: 24),
                                const SizedBox(height: 6),
                                const Text(
                                  'Tap to upload image',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Format: jpeg/jpg/png',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 12,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            )
                            // 2b) file selected → filename centered
                                : Text(
                              path.basename(_proofImage!.path),
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),
                    ],
                  ),

                  // SUBMIT BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 45,
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEFBF04),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Submit',
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

}
