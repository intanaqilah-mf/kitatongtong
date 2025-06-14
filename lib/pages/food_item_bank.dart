import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:projects/widgets/bottomNavBar.dart';
import 'package:path/path.dart' as path;
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:projects/localization/app_localizations.dart';

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
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(_proofImage!.path)}';
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('fooditembank_images')
            .child(fileName);

        final uploadTask = storageRef.putFile(_proofImage!);
        final snapshot  = await uploadTask;
        imageUrl = await snapshot.ref.getDownloadURL();
      }

      await FirebaseFirestore.instance
          .collection('fooditembank')
          .add({
        'type'           : _selectedType,
        'estimatedValue' : double.tryParse(_valueCtrl.text) ?? 0.0,
        'giverName'      : _nameCtrl.text.trim(),
        'phoneNumber'    : _phoneCtrl.text.trim(),
        'email'          : _emailCtrl.text.trim(),
        'taxExemption'   : _wantsTax,
        'imageUrl'       : imageUrl,
        'createdAt'      : FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).translate('food_item_bank_submit_success')))
      );
      Navigator.of(context).pop();

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).translateWithArgs('food_item_bank_submit_error', {'error': e.toString()})))
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
        textAlignVertical: TextAlignVertical.center,
        validator: (v) => v == null || v.isEmpty ? AppLocalizations.of(context).translate('food_item_bank_required_field') : null,
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
    final localizations = AppLocalizations.of(context);

    // Mappings for dropdowns
    final typeMapping = {
      'Food': localizations.translate('food_item_bank_type_food'),
      'Item': localizations.translate('food_item_bank_type_item'),
    };
    final categoryMapping = {
      'Clothes': localizations.translate('food_item_bank_item_type_clothes'),
      'Accessory': localizations.translate('food_item_bank_item_type_accessory'),
      'Baby Stuff': localizations.translate('food_item_bank_item_type_baby'),
      'School Stuff': localizations.translate('food_item_bank_item_type_school'),
      'Other': localizations.translate('food_item_bank_item_type_other'),
    };

    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1C1C),
        elevation: 0,
        title: Text(
          localizations.translate('food_item_bank_title'),
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
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            kBottomNavigationBarHeight + 16,
          ),
          children: [
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Text(localizations.translate('food_item_bank_type'),
                      style: TextStyle(color: Color(0xFFF1D789), fontSize: 14)),
                  const SizedBox(height: 4),
                  _dropdown(
                    typeMapping.values.toList(),
                    typeMapping[_selectedType]!,
                        (v) => setState(() {
                      _selectedType = typeMapping.entries.firstWhere((e) => e.value == v).key;
                    }),
                  ),
                  const SizedBox(height: 16),

                  if (_selectedType == 'Item') ...[
                    Text(localizations.translate('food_item_bank_item_name_label'),
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    _field(_itemNameCtrl, localizations.translate('food_item_bank_item_name_hint')),
                    const SizedBox(height: 16),

                    Text(localizations.translate('food_item_bank_item_type_label'),
                        style:
                        TextStyle(color: Color(0xFFF1D789), fontSize: 14)),
                    const SizedBox(height: 4),
                    _dropdown(
                      categoryMapping.values.toList(),
                      categoryMapping[_itemCategory]!,
                          (v) => setState(() {
                        _itemCategory = categoryMapping.entries.firstWhere((e) => e.value == v).key;
                      }),
                    ),
                    const SizedBox(height: 16),

                    Text(localizations.translate('food_item_bank_number_of_items'),
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
                      Text(localizations.translate('food_item_bank_condition_new'), style: TextStyle(color: Colors.white)),
                      const SizedBox(width: 16),
                      Checkbox(
                          value: !_isNew,
                          activeColor: const Color(0xFFFDB515),
                          onChanged: (v) => setState(() => _isNew = !v!)),
                      Text(localizations.translate('food_item_bank_condition_used'), style: TextStyle(color: Colors.white)),
                    ]),
                    const SizedBox(height: 16),

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
                              ? Text(localizations.translate('food_item_bank_upload_tap'),
                              style: TextStyle(color: Colors.black))
                              : Image.file(_proofImage!, fit: BoxFit.cover),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  Text(localizations.translate('food_item_bank_estimated_value'),
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  _field(_valueCtrl, '0.00', type: TextInputType.number),
                  const SizedBox(height: 24),

                  Text(localizations.translate('food_item_bank_giver_name_label'),
                      style: TextStyle(color: Color(0xFFF1D789), fontSize: 14)),
                  const SizedBox(height: 4),
                  _field(_nameCtrl, localizations.translate('food_item_bank_giver_name_hint')),
                  const SizedBox(height: 16),

                  Text(localizations.translate('food_item_bank_phone_label'),
                      style: TextStyle(color: Color(0xFFF1D789), fontSize: 14)),
                  const SizedBox(height: 4),
                  _field(_phoneCtrl, localizations.translate('food_item_bank_phone_hint'), type: TextInputType.phone),
                  const SizedBox(height: 16),

                  Text(localizations.translate('food_item_bank_email_label'),
                      style: TextStyle(color: Color(0xFFF1D789), fontSize: 14)),
                  const SizedBox(height: 4),
                  _field(_emailCtrl, localizations.translate('food_item_bank_email_hint'), type: TextInputType.emailAddress),
                  const SizedBox(height: 24),

                  Text(
                    localizations.translate('food_item_bank_tax_question'),
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
                      Text(localizations.translate('yes'), style: TextStyle(color: Colors.white)),
                      const SizedBox(width: 24),
                      Radio<bool>(
                        value: false,
                        groupValue: _wantsTax,
                        activeColor: Color(0xFFFDB515),
                        onChanged: (v) => setState(() => _wantsTax = v!),
                      ),
                      Text(localizations.translate('no'), style: TextStyle(color: Colors.white)),
                    ],
                  ),
                  const SizedBox(height: 32),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        localizations.translate('food_item_bank_picture_label'),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFF1D789),
                        ),
                      ),
                      const SizedBox(height: 8),

                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFFFCF40),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: EdgeInsets.zero,
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
                          height: 90,
                          width: double.infinity,
                          child: Center(
                            child: _proofImage == null
                                ? Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.asset('assets/uploadAsnaf.png', height: 24),
                                const SizedBox(height: 6),
                                Text(
                                  localizations.translate('food_item_bank_upload_tap'),
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  localizations.translate('food_item_bank_upload_format'),
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 12,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            )
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
                      child: Text(localizations.translate('submit'),
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