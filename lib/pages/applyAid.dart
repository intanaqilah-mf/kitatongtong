import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:projects/widgets/bottomNavBar.dart';
import 'package:file_picker/file_picker.dart';
import '../pages/PDFViewerScreen.dart';
import 'package:path/path.dart' as path;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../pages/applicationReviewScreen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';
import 'package:projects/pages/ekyc_screen.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:csv/csv.dart';
import 'package:projects/localization/app_localizations.dart';

class ApplyAid extends StatefulWidget {
  @override
  _ApplyAidState createState() => _ApplyAidState();
}

class _ApplyAidState extends State<ApplyAid> {
  String? userRole;
  bool _isEkycComplete = false;
  List<List<dynamic>> _postcodeData = [];

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _loadPostcodeData();
    postcodeController.addListener(_onPostcodeChanged);
  }

  @override
  void dispose() {
    postcodeController.removeListener(_onPostcodeChanged);
    nricController.dispose();
    fullnameController.dispose();
    emailController.dispose();
    mobileNumberController.dispose();
    add1Controller.dispose();
    add2Controller.dispose();
    cityController.dispose();
    postcodeController.dispose();
    stateController.dispose();
    justificationController.dispose();
    occupationController.dispose();
    incomeController.dispose();
    asnafInController.dispose();
    super.dispose();
  }

  int currentStep = 1;
  final int totalSteps = 5;
  int _selectedIndex = 0;

  // Page 1 Controllers
  TextEditingController nricController = TextEditingController(); // Kept for data handling
  TextEditingController fullnameController = TextEditingController(); // Kept for data handling
  TextEditingController emailController = TextEditingController();
  TextEditingController mobileNumberController = TextEditingController();
  TextEditingController add1Controller = TextEditingController();
  TextEditingController add2Controller = TextEditingController();
  TextEditingController cityController = TextEditingController();
  TextEditingController postcodeController = TextEditingController();
  TextEditingController stateController = TextEditingController();

  // Page 2 State & Controllers
  String? _selectedResidency;
  String? _selectedEmployment;
  String? _selectedAsnaf;
  TextEditingController occupationController = TextEditingController();
  TextEditingController incomeController = TextEditingController();
  TextEditingController asnafInController = TextEditingController();
  TextEditingController justificationController = TextEditingController();

  final Map<String, dynamic> formData = {};
  String? fileName2;
  String? fileName3;

  Future<void> _loadPostcodeData() async {
    final rawData = await rootBundle.loadString('assets/postcode_my.csv');
    List<List<dynamic>> listData = const CsvToListConverter().convert(rawData);
    setState(() {
      _postcodeData = listData;
    });
  }
  void _onPostcodeChanged() {
    final userInputPostcode = postcodeController.text;

    if (userInputPostcode.length >= 4 && userInputPostcode.length <= 5) {
      final userInputAsInt = int.tryParse(userInputPostcode);
      if (userInputAsInt == null) {
        return;
      }

      for (var i = 1; i < _postcodeData.length; i++) {
        final csvPostcodeString = _postcodeData[i][3].toString();
        final csvPostcodeAsInt = int.tryParse(csvPostcodeString);

        if (csvPostcodeAsInt != null && csvPostcodeAsInt == userInputAsInt) {
          setState(() {
            cityController.text = _postcodeData[i][2].toString();
            stateController.text = _postcodeData[i][4].toString();
          });
          return;
        }
      }
    }

    setState(() {
      cityController.clear();
      stateController.clear();
    });
  }

  String generateUniqueCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    Random random = Random();
    return "#" + String.fromCharCodes(Iterable.generate(6, (_) => chars.codeUnitAt(random.nextInt(chars.length))));
  }

  void uploadToFirebase(Map<String, dynamic> data) async {
    final localizations = AppLocalizations.of(context);
    try {
      final DateTime now = DateTime.now();
      final String applicationCode = generateUniqueCode(); // Defined here

      data['date'] = now.toIso8601String();
      data['applicationCode'] = applicationCode;
      data['statusApplication'] = "Pending";
      String submitterName = fullnameController.text;
      // Correctly handle submission based on the user's role
      if (userRole == 'staff') {
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser == null) {
          showSnackBar("Staff user not found. Please log in again.");
          return;
        }
        final String staffUserId = currentUser.uid;
        final staffDoc = await FirebaseFirestore.instance.collection('users').doc(staffUserId).get();
        final String staffName = staffDoc.data()?['name'] ?? 'Unknown Staff';
        submitterName = staffName;
        data['submittedBy'] = {
          'uid': staffUserId,
          'name': staffName
        };
        data['userId'] = null; // Applicant is identified by NRIC, not a user ID

      } else { // Asnaf is applying for themselves
        final String asnafUserId = FirebaseAuth.instance.currentUser!.uid;
        data['userId'] = asnafUserId;
        data['submittedBy'] = 'system';
      }

      final newApplicationRef = await FirebaseFirestore.instance.collection("applications").add(data);
      String notificationMessage = "A new aid application ($applicationCode) was submitted by $submitterName and requires verification.";

      // Notify Admins
      await FirebaseFirestore.instance.collection('notifications').add({
        'createdAt': FieldValue.serverTimestamp(),
        'recipients': ['ROLE_ADMIN'], // Target all admins
        'message': notificationMessage,
        'type': 'new_application',
        'referenceId': newApplicationRef.id, // Link to the new application
      });

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ApplicationReviewScreen()),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations.translate('apply_aid_submit_success'))),
      );

    } catch (e) {
      print("Error during submission: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations.translate('apply_aid_submit_fail'))),
      );
    }
  }

  Future<void> _fetchUserData() async {
    try {
      final String userId = FirebaseAuth.instance.currentUser!.uid;
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final role = userData['role'] ?? 'asnaf';
        setState(() {
          userRole = role;
        });

        // If the user is an 'asnaf', populate their data.
        if (role == 'asnaf') {
          final fullAddress = userData['address'] ?? '';
          final addressParts = fullAddress.split(',');

          setState(() {
            nricController.text = userData['nric'] ?? '';
            fullnameController.text = userData['name'] ?? '';
            emailController.text = FirebaseAuth.instance.currentUser!.email ?? '';
            mobileNumberController.text = userData['phone'] ?? '';
            add1Controller.text = addressParts.isNotEmpty ? addressParts[0].trim() : '';
            add2Controller.text = addressParts.length > 1 ? addressParts.sublist(1).join(',').trim() : '';
            cityController.text = userData['city'] ?? '';
            postcodeController.text = userData['postcode'] ?? '';
            stateController.text = userData['state'] ?? '';

            // Check eKYC status only for asnaf
            if ((userData['nric'] ?? '').isNotEmpty) {
              _isEkycComplete = true;
            } else {
              _isEkycComplete = false;
            }
          });
        }
        // If the user is a 'staff', ensure the form is empty.
        else if (role == 'staff') {
          setState(() {
            nricController.clear();
            fullnameController.clear();
            emailController.clear();
            mobileNumberController.clear();
            add1Controller.clear();
            add2Controller.clear();
            cityController.clear();
            postcodeController.clear();
            stateController.clear();

            // Always reset eKYC status for staff
            _isEkycComplete = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching user data: $e");
    }
  }

  Future<void> _updateUserProfile() async {
    try {
      final String userId = FirebaseAuth.instance.currentUser!.uid;
      final String mergedAddress = [add1Controller.text.trim(), add2Controller.text.trim()]
          .where((s) => s.isNotEmpty)
          .join(', ');

      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        'phone': mobileNumberController.text,
        'address': mergedAddress,
        'city': cityController.text,
        'postcode': postcodeController.text,
        'state': stateController.text,
      }, SetOptions(merge: true));

      print("✅ User profile updated from ApplyAid form.");
    } catch (e) {
      print("❌ Error updating user profile: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    double progressValue = currentStep / totalSteps;
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(80.0),
        child: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Color(0xFF303030),
          flexibleSpace: Padding(
            padding: const EdgeInsets.only(top: 20.0, left: 16.0, right: 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () {
                        if (currentStep > 1) {
                          setState(() => currentStep--);
                        } else {
                          Navigator.pop(context);
                        }
                      },
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Stack(
                          children: [
                            Container(
                              height: 23,
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                            ),
                            AnimatedContainer(
                              duration: Duration(milliseconds: 300),
                              width: MediaQuery.of(context).size.width * 0.74 * progressValue,
                              height: 23,
                              decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(10)),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Text("$currentStep/$totalSteps", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 20),
            Center(child: _buildStepHeader()),
            SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: _buildCurrentStepForm(),
              ),
            ),
            _buildNavigationControls(),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: (index) => setState(() => _selectedIndex = index),
      ),
    );
  }

  Widget _buildStepHeader() {
    String title = "";
    String subtitle = "";
    final localizations = AppLocalizations.of(context);
    switch (currentStep) {
      case 1:
        title = localizations.translate('apply_aid_step1_title');
        subtitle = localizations.translate('apply_aid_step1_subtitle');
        break;
      case 2:
        title = localizations.translate('apply_aid_step2_title');
        subtitle = localizations.translate('apply_aid_step2_subtitle');
        break;
      case 3:
        title = localizations.translate('apply_aid_step3_title');
        subtitle = localizations.translate('apply_aid_step3_subtitle');
        break;
      case 4:
        title = localizations.translate('apply_aid_step4_title');
        subtitle = localizations.translate('apply_aid_step4_subtitle');
        break;
      case 5:
        title = localizations.translate('apply_aid_step5_title');
        subtitle = localizations.translate('apply_aid_step5_subtitle');
        break;
    }
    return Column(
      children: [
        Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFFDB515)), textAlign: TextAlign.center),
        SizedBox(height: 8),
        Text(subtitle, style: TextStyle(fontSize: 14, color: Colors.yellow[200]), textAlign: TextAlign.center),
      ],
    );
  }

  List<Widget> _buildCurrentStepForm() {
    switch (currentStep) {
      case 1: return buildPersonalDetailsForm();
      case 2: return buildEligibilityForm();
      case 3: return buildUploadDocumentsForm();
      case 4: return buildReviewDocumentsForm();
      case 5: return buildAgreementPage();
      default: return [];
    }
  }

  Widget _buildNavigationControls() {
    final localizations = AppLocalizations.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Divider(color: Colors.white, thickness: 1),
        SizedBox(height: 2),
        Padding(
          padding: const EdgeInsets.only(bottom: 20.0),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFFFCF40),
              foregroundColor: Colors.black,
            ),
            onPressed: _onNextPressed,
            child: Text(currentStep == totalSteps ? localizations.translate('submit') : localizations.translate('next')),
          ),
        ),
      ],
    );
  }

  void _onNextPressed() async {
    bool isPageValid = false;
    switch(currentStep) {
      case 1: isPageValid = _validatePage1(); break;
      case 2: isPageValid = _validatePage2(); break;
      case 3: isPageValid = _validatePage3(); break;
      case 4: isPageValid = true; break;
      case 5:
        consolidateAndUploadData();
        return;
    }

    if (!isPageValid) {
      return;
    }

    if (userRole == 'asnaf' && (currentStep == 1 || currentStep == 2)){
      await _updateUserProfile();
    }

    if (currentStep < totalSteps) {
      setState(() => currentStep++);
    }
  }

  void showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red));
  }

  bool _validatePage1() {
    final localizations = AppLocalizations.of(context);
    if (mobileNumberController.text.isEmpty || !RegExp(r'^(1|01)\d{8,9}$').hasMatch(mobileNumberController.text)) {
      showSnackBar(localizations.translate('apply_aid_validation_mobile'));
      return false;
    }
    if (add1Controller.text.isEmpty) {
      showSnackBar(localizations.translate('apply_aid_validation_addr1'));
      return false;
    }
    if (postcodeController.text.isEmpty || !RegExp(r'^\d{5}$').hasMatch(postcodeController.text)) {
      showSnackBar(localizations.translate('apply_aid_validation_postcode'));
      return false;
    }
    if (cityController.text.isEmpty || stateController.text.isEmpty) {
      showSnackBar(localizations.translate('apply_aid_validation_city_state'));
      return false;
    }
    return true;
  }

  bool _validatePage2() {
    final localizations = AppLocalizations.of(context);
    if (_selectedResidency == null) {
      showSnackBar(localizations.translate('apply_aid_validation_residency'));
      return false;
    }
    if (_selectedEmployment == null) {
      showSnackBar(localizations.translate('apply_aid_validation_employment'));
      return false;
    }
    if (_selectedEmployment == "Employed") {
      if (occupationController.text.isEmpty) {
        showSnackBar(localizations.translate('apply_aid_validation_occupation'));
        return false;
      }
      if (incomeController.text.isEmpty) {
        showSnackBar(localizations.translate('apply_aid_validation_income'));
        return false;
      }
      final income = double.tryParse(incomeController.text);
      if (income == null) {
        showSnackBar(localizations.translate('apply_aid_validation_income_numeric'));
        return false;
      }
      if (income > 8000) {
        showSnackBar(localizations.translate('apply_aid_validation_income_limit'));
        return false;
      }
    }
    if (_selectedEmployment == "Unemployed") {
      if (_selectedAsnaf == null) {
        showSnackBar(localizations.translate('apply_aid_validation_is_asnaf'));
        return false;
      }
      if (_selectedAsnaf == "Yes" && asnafInController.text.isEmpty) {
        showSnackBar(localizations.translate('apply_aid_validation_asnaf_in'));
        return false;
      }
    }
    if (justificationController.text.isEmpty) {
      showSnackBar(localizations.translate('apply_aid_validation_justification'));
      return false;
    }
    return true;
  }

  bool _validatePage3() {
    final localizations = AppLocalizations.of(context);
    if (!_isEkycComplete) {
      showSnackBar(localizations.translate('apply_aid_validation_ekyc_incomplete'));
      return false;
    }
    if (fileName2 == null) {
      showSnackBar(localizations.translate('apply_aid_validation_proof_address'));
      return false;
    }
    if (_selectedEmployment == "Employed" && fileName3 == null) {
      showSnackBar(localizations.translate('apply_aid_validation_proof_income'));
      return false;
    }
    return true;
  }


  List<Widget> buildPersonalDetailsForm() {
    final localizations = AppLocalizations.of(context);
    return [
      if (userRole == 'staff') ...[
        buildTextField(
            localizations.translate('profile_nric'),
            "nric",
            nricController,
            readOnly: true,
            hint: "Complete eKYC to populate applicant NRIC"
        ),
        SizedBox(height: 10),
        buildTextField(
            localizations.translate('profile_set_name_hint'),
            "fullname",
            fullnameController,
            readOnly: true,
            hint: "Complete eKYC to populate applicant name"
        ),
        SizedBox(height: 10),
      ],
      buildTextField(
          localizations.translate('apply_aid_label_email'),
          "email",
          emailController,
          readOnly: userRole == 'asnaf', // Email is read-only for 'asnaf'
          hint: localizations.translate('apply_aid_hint_email')
      ),
      SizedBox(height: 10),
      buildMobileNumberField("mobileNumber", mobileNumberController),
      SizedBox(height: 10),
      buildTextField(
          localizations.translate('apply_aid_label_addr1'),
          "addressLine1",
          add1Controller,
          hint: localizations.translate('apply_aid_hint_addr1')
      ),
      SizedBox(height: 10),
      buildTextField(
          localizations.translate('apply_aid_label_addr2'),
          "addressLine2",
          add2Controller,
          hint: localizations.translate('apply_aid_hint_addr2')
      ),
      SizedBox(height: 10),
      buildTextField(
          localizations.translate('apply_aid_label_postcode'),
          "postcode",
          postcodeController,
          hint: localizations.translate('apply_aid_hint_postcode'),
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(5)
          ]
      ),
      SizedBox(height: 10),
      buildTextField(
          localizations.translate('apply_aid_label_city'),
          "city",
          cityController,
          hint: localizations.translate('apply_aid_hint_city'),
          readOnly: true
      ),
      SizedBox(height: 10),
      buildTextField(
          localizations.translate('apply_aid_label_state'),
          "state",
          stateController,
          hint: localizations.translate('apply_aid_hint_state'),
          readOnly: true
      ),
    ];
  }

  List<Widget> buildEligibilityForm() {
    final localizations = AppLocalizations.of(context);
    final residencyMap = {
      "Malaysian": localizations.translate('apply_aid_residency_malaysian'),
      "Non-Malaysian": localizations.translate('apply_aid_residency_non_malaysian'),
    };
    final employmentMap = {
      "Employed": localizations.translate('apply_aid_employment_employed'),
      "Unemployed": localizations.translate('apply_aid_employment_unemployed'),
    };
    final asnafMap = {
      "Yes": localizations.translate('yes'),
      "No": localizations.translate('no'),
    };

    return [
      buildDropdownField(localizations.translate('apply_aid_label_residency'), "residencyStatus", residencyMap.values.toList(), _selectedResidency != null ? residencyMap[_selectedResidency] : null, (newValue) {
        setState(() { _selectedResidency = residencyMap.entries.firstWhere((entry) => entry.value == newValue).key; });
      }, hint: localizations.translate('apply_aid_hint_residency')),
      SizedBox(height: 10),
      buildDropdownField(localizations.translate('apply_aid_label_employment'), "employmentStatus", employmentMap.values.toList(), _selectedEmployment != null ? employmentMap[_selectedEmployment] : null, (newValue) {
        setState(() {
          _selectedEmployment = employmentMap.entries.firstWhere((entry) => entry.value == newValue).key;
          if (_selectedEmployment == "Unemployed") incomeController.clear();
        });
      }, hint: localizations.translate('apply_aid_hint_employment')),
      SizedBox(height: 10),
      if (_selectedEmployment == "Employed") ...[
        buildTextField(localizations.translate('apply_aid_label_occupation'), "occupation", occupationController, hint: localizations.translate('apply_aid_hint_occupation')),
        SizedBox(height: 10),
        buildTextField(localizations.translate('apply_aid_label_income'), "monthlyIncome", incomeController, hint: localizations.translate('apply_aid_hint_income'), keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
        SizedBox(height: 10),
      ],
      if (_selectedEmployment == "Unemployed") ...[
        buildDropdownField(localizations.translate('apply_aid_label_is_asnaf'), "isAsnaf", asnafMap.values.toList(), _selectedAsnaf != null ? asnafMap[_selectedAsnaf] : null, (newValue) {
          setState(() { _selectedAsnaf = asnafMap.entries.firstWhere((entry) => entry.value == newValue).key; });
        }, hint: localizations.translate('apply_aid_hint_is_asnaf')),
        SizedBox(height: 10),
        if (_selectedAsnaf == "Yes") ...[
          buildTextField(localizations.translate('apply_aid_label_asnaf_in'), "asnafIn", asnafInController, hint: localizations.translate('apply_aid_hint_asnaf_in')),
          SizedBox(height: 10),
        ]
      ],
      buildLongTextField(localizations.translate('apply_aid_label_justification'), "justificationApplication", justificationController, hint: localizations.translate('apply_aid_hint_justification')),
    ];
  }

  List<Widget> buildUploadDocumentsForm() {
    final localizations = AppLocalizations.of(context);
    return [
      buildEkycVerificationField(localizations.translate('apply_aid_label_ekyc'), localizations.translate('apply_aid_subtitle_ekyc')),
      SizedBox(height: 10),
      buildFileUploadField(localizations.translate('apply_aid_label_proof_address'), localizations.translate('apply_aid_upload_proof_address'), localizations.translate('apply_aid_upload_format'), "proofOfAddress", 2),
      SizedBox(height: 10),
      if (_selectedEmployment == "Employed")
        buildFileUploadField(localizations.translate('apply_aid_label_proof_income'), localizations.translate('apply_aid_upload_proof_income'), localizations.translate('apply_aid_upload_format'), "proofOfIncome", 3),
    ];
  }

  List<Widget> buildReviewDocumentsForm() {
    final localizations = AppLocalizations.of(context);
    return [
      buildFileDisplayField(localizations.translate('apply_aid_label_proof_address'), fileName2),
      SizedBox(height: 10),
      if (_selectedEmployment == "Employed")
        buildFileDisplayField(localizations.translate('apply_aid_label_proof_income'), fileName3),
    ];
  }

  Widget buildEkycVerificationField(String title, String subtitle) {
    final localizations = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
        SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            // Pass the user's role to determine the eKYC mode.
            final result = await Navigator.push(context, MaterialPageRoute(
                builder: (context) => EkycScreen(isStaffMode: userRole == 'staff')),
            );

            if (result == null) return; // User cancelled

            // Handle the return data based on the user's role.
            if (userRole == 'staff') {
              if (result is Map<String, dynamic>) {
                // For staff, update controllers with returned data to preserve the form.
                setState(() {
                  nricController.text = result['nric'] ?? '';
                  fullnameController.text = result['name'] ?? '';
                  _isEkycComplete = true;
                });
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(localizations.translate('apply_aid_ekyc_success')), backgroundColor: Colors.green));
              }
            } else {
              // For asnaf, reload their own profile data.
              if (result == true) {
                await _fetchUserData();
                setState(() => _isEkycComplete = true);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(localizations.translate('apply_aid_ekyc_success')), backgroundColor: Colors.green));
              }
            }
          },
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
                color: _isEkycComplete ? Colors.green : Color(0xFFFFCF40),
                borderRadius: BorderRadius.circular(10)
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        _isEkycComplete ? localizations.translate('apply_aid_ekyc_complete') : localizations.translate('apply_aid_ekyc_start'),
                        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)
                    ),
                    Text(subtitle, style: TextStyle(color: Colors.black87, fontSize: 12)),
                  ],
                ),
                Icon(_isEkycComplete ? Icons.check_circle : Icons.arrow_forward_ios, color: Colors.black),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void consolidateAndUploadData() {
    if (!_validatePage1() || !_validatePage2() || !_validatePage3()) {
      showSnackBar(AppLocalizations.of(context).translate('apply_aid_validation_all_fields'));
      return;
    }

    formData["nric"] = nricController.text;
    formData["fullname"] = fullnameController.text;
    formData["email"] = emailController.text;
    formData["mobileNumber"] = mobileNumberController.text;
    formData["addressLine1"] = add1Controller.text;
    formData["addressLine2"] = add2Controller.text;
    formData["city"] = cityController.text;
    formData["postcode"] = postcodeController.text;
    formData["state"] = stateController.text;

    formData["residencyStatus"] = _selectedResidency;
    formData["employmentStatus"] = _selectedEmployment;
    if(_selectedEmployment == "Employed") {
      formData["occupation"] = occupationController.text;
      formData["monthlyIncome"] = incomeController.text;
    } else {
      formData["isAsnaf"] = _selectedAsnaf;
      if(_selectedAsnaf == "Yes"){
        formData["asnafIn"] = asnafInController.text;
      }
    }
    formData["justificationApplication"] = justificationController.text;

    final localizations = AppLocalizations.of(context);
    formData["proofOfAddress"] = fileName2 ?? localizations.translate('apply_aid_no_file_uploaded');
    formData["proofOfIncome"] = fileName3 ?? localizations.translate('apply_aid_no_file_uploaded');

    uploadToFirebase(formData);
  }

  List<Widget> buildAgreementPage() {
    final localizations = AppLocalizations.of(context);
    return [
      SizedBox(height: 16),
      Container(
        height: MediaQuery.of(context).size.height * 0.5,
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAgreementPoint(localizations.translate('apply_aid_agreement1_title'), localizations.translate('apply_aid_agreement1_content')),
                _buildAgreementPoint(localizations.translate('apply_aid_agreement2_title'), localizations.translate('apply_aid_agreement2_content')),
                _buildAgreementPoint(localizations.translate('apply_aid_agreement3_title'), localizations.translate('apply_aid_agreement3_content')),
                _buildAgreementPoint(localizations.translate('apply_aid_agreement4_title'), localizations.translate('apply_aid_agreement4_content')),
              ],
            ),
          ),
        ),
      ),
    ];
  }

  Widget _buildAgreementPoint(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFFFCF40))),
        SizedBox(height: 4),
        Text(content, style: TextStyle(fontSize: 14, color: Color(0xFFD9D9D9), height: 1.5)),
        SizedBox(height: 10),
      ],
    );
  }

  Widget buildFileDisplayField(String title, String? fileName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
        SizedBox(height: 8),
        GestureDetector(
          onTap: () {
            if (fileName != null && fileName.endsWith('.pdf')) {
              Navigator.push(context, MaterialPageRoute(builder: (context) => PDFViewerScreen(filePath: fileName)));
            }
          },
          child: Container(
            decoration: BoxDecoration(color: Color(0xFFFFCF40), borderRadius: BorderRadius.circular(10)),
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Image.asset('assets/docAsnaf.png', height: 24),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          fileName != null ? path.basename(fileName) : AppLocalizations.of(context).translate('apply_aid_no_file_uploaded'),
                          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget buildFileUploadField(String title, String label, String subtitle, String key, int index) {
    String? uploadedFileName = index == 2 ? fileName2 : fileName3;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
        SizedBox(height: 8),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFFFFCF40),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: EdgeInsets.zero,
          ),
          onPressed: () async {
            try {
              FilePickerResult? result = await FilePicker.platform.pickFiles(
                  type: FileType.custom, allowedExtensions: ['jpeg', 'jpg', 'pdf']);
              if (result != null) {
                setState(() {
                  if (index == 2) fileName2 = result.files.single.path!;
                  if (index == 3) fileName3 = result.files.single.path!;
                  formData[key] = result.files.single.path!;
                });
              }
            } catch (e) {
              debugPrint("Error while picking file: $e");
            }
          },
          child: Container(
            height: 90,
            width: double.infinity,
            child: Center(
              child: uploadedFileName == null
                  ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/uploadAsnaf.png', height: 24),
                  SizedBox(height: 6),
                  Text(label, style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14), textAlign: TextAlign.center),
                  SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(color: Colors.black, fontSize: 12), textAlign: TextAlign.center),
                ],
              )
                  : Text(path.basename(uploadedFileName), style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14), textAlign: TextAlign.center),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildLongTextField(String label, String key, TextEditingController controller, {String? hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
        SizedBox(height: 8),
        Container(
          height: 120,
          decoration: BoxDecoration(color: Color(0xFFFFCF40), borderRadius: BorderRadius.circular(10)),
          child: TextField(
            controller: controller,
            maxLines: null,
            expands: true,
            textAlignVertical: TextAlignVertical.top,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.black54),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildTextField(String label, String key, TextEditingController controller, {bool readOnly = false, String? hint, TextInputType? keyboardType, List<TextInputFormatter>? inputFormatters}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
        SizedBox(height: 8),
        Container(
          height: 40,
          decoration: BoxDecoration(color: Color(0xFFFFCF40), borderRadius: BorderRadius.circular(10)),
          child: TextField(
            controller: controller,
            readOnly: readOnly,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.black54),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildDropdownField(String label, String key, List<String> items, String? selectedValue, ValueChanged<String?> onChanged, {String? hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
        SizedBox(height: 8),
        Container(
          height: 45,
          padding: EdgeInsets.symmetric(horizontal: 12.0),
          decoration: BoxDecoration(color: Color(0xFFFFCF40), borderRadius: BorderRadius.circular(10)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedValue,
              isExpanded: true,
              hint: Text(hint ?? AppLocalizations.of(context).translate('apply_aid_hint_is_asnaf'), style: TextStyle(color: Colors.black54)),
              icon: Icon(Icons.arrow_drop_down, color: Colors.black),
              dropdownColor: Color(0xFFFFCF40),
              onChanged: onChanged,
              items: items.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(value: value, child: Text(value, style: TextStyle(color: Colors.black)));
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildMobileNumberField(String key, TextEditingController controller) {
    final localizations = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(localizations.translate('apply_aid_label_mobile'), style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
        SizedBox(height: 8),
        Container(
          height: 40,
          decoration: BoxDecoration(color: Color(0xFFFFCF40), borderRadius: BorderRadius.circular(10)),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Text("+60", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black)),
              ),
              VerticalDivider(color: Colors.black, thickness: 1, indent: 8, endIndent: 8),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
                    hintText: localizations.translate('apply_aid_hint_mobile'),
                    hintStyle: TextStyle(color: Colors.black54),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}