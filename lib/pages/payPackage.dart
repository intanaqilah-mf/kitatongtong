import 'package:flutter/material.dart';
import 'package:projects/widgets/bottomNavBar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:projects/pages/email_service.dart';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:projects/pages/PaymentWebview.dart';
import 'package:projects/config/app_config.dart'; // Import AppConfig

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';

class PayPackage extends StatefulWidget {
  final int totalQuantity;
  final double  overallAmount;

  const PayPackage({
    Key? key,
    required this.totalQuantity,
    required this.overallAmount,
  }) : super(key: key);

  @override
  _PayPackageState createState() => _PayPackageState();
}

class _PayPackageState extends State<PayPackage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController contactController = TextEditingController();

  String? selectedSalutation;
  bool wantsTaxExemption = false;
  final List<String> salutations = ['Mr.', 'Ms.', 'Mrs.', 'Dr.', 'Prof.'];
  int _selectedIndex = 0;

  String? _nameError;
  String? _emailError;
  String? _contactError;


  @override
  void initState() {
    super.initState();
    _loadUserData();
    nameController.addListener(_validateName);
    emailController.addListener(_validateEmail);
    contactController.addListener(_validateContact);
  }

  @override
  void dispose() {
    nameController.removeListener(_validateName);
    emailController.removeListener(_validateEmail);
    contactController.removeListener(_validateContact);
    nameController.dispose();
    emailController.dispose();
    contactController.dispose();
    super.dispose();
  }

  void _loadUserData() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      FirebaseFirestore.instance.collection('users').doc(user.uid).get().then((doc) {
        if (doc.exists) {
          final data = doc.data()!;
          setState(() {
            nameController.text = data['name'] ?? '';
            emailController.text = data['email'] ?? '';
            contactController.text = data['phone'] ?? '';
          });
        }
      });
    }
  }

  void _validateName() {
    setState(() {
      if (nameController.text.trim().isEmpty) {
        _nameError = 'Full name is required';
      } else {
        _nameError = null;
      }
    });
  }

  void _validateEmail() {
    setState(() {
      final email = emailController.text.trim();
      if (email.isEmpty) {
        _emailError = 'Email is required';
      } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
        _emailError = 'Enter a valid email address';
      } else {
        _emailError = null;
      }
    });
  }

  void _validateContact() {
    setState(() {
      final contact = contactController.text.trim();
      if (contact.isEmpty) {
        _contactError = 'Contact number is required';
      } else if (!RegExp(r'^\d{9,10}$').hasMatch(contact)) {
        _contactError = 'Must be 9-10 digits';
      } else {
        _contactError = null;
      }
    });
  }

  Future<void> processPackagePaymentAndRedirect({
    required BuildContext context,
    required Map<String, dynamic> donationData,
    required String name,
    required String email,
    required String phone,
    required String amountInCents,
  }) async {
    final String webAppDomain = AppConfig.getWebAppDomain();
    final String toyyibpaySecretKey = AppConfig.getToyyibPaySecretKey();
    final String toyyibpayCategoryCode = AppConfig.getToyyibPayCategoryCode();
    final String billExternalRef = 'TXN${DateTime.now().millisecondsSinceEpoch}';

    String billReturnUrl;
    String billCallbackUrl;

    if (kIsWeb) {
      billReturnUrl = '$webAppDomain/payment-redirect';
      billCallbackUrl = '$webAppDomain/payment-callback-server';
    } else {
      billReturnUrl = 'myapp://payment-result?status=success';
      billCallbackUrl = 'myapp://payment-result?status=fail';
    }

    if (toyyibpaySecretKey.isEmpty || toyyibpayCategoryCode.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Payment configuration error. Please contact support.")),
        );
      }
      return;
    }

    final response = await http.post(
      Uri.parse('https://toyyibpay.com/index.php/api/createBill'),
      body: {
        'userSecretKey': toyyibpaySecretKey,
        'categoryCode': toyyibpayCategoryCode,
        'billName': 'Kita Tongtong Package Donation',
        'billDescription': 'Donation of ${widget.totalQuantity} package(s)',
        'billPriceSetting': '1',
        'billPayorInfo': '1',
        'billAmount': amountInCents,
        'billReturnUrl': billReturnUrl,
        'billCallbackUrl': billCallbackUrl,
        'billExternalReferenceNo': billExternalRef,
        'billTo': name,
        'billEmail': email,
        'billPhone': phone,
        'billSplitPayment': '0',
        'billPaymentChannel': '0',
        'billDisplayMerchant': '1'
      },
    );

    if (response.statusCode == 200) {
      final dynamic data = jsonDecode(response.body);
      if (data is List && data.isNotEmpty && data[0]['BillCode'] != null) {
        final billCode = data[0]['BillCode'];
        final paymentGatewayUrl = 'https://toyyibpay.com/$billCode';

        if (kIsWeb) {
          if (!await launchUrl(Uri.parse(paymentGatewayUrl))) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Could not open payment page.")),
              );
            }
          }
        } else {
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PaymentWebView(paymentUrl: paymentGatewayUrl, donationData: donationData),
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Payment initiation error. Please try again.")),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to initiate payment.")),
        );
      }
    }
  }

  Future<Uint8List> generatePdfBytes({required String name, required String email, required String amountRM}) async {
    final pdf = pw.Document();
    final now = DateTime.now();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Center(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text("Tax Exemption Receipt", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 20),
              pw.Text("To: $name"),
              pw.Text("Email: $email"),
              pw.Text("Date: ${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}"),
              pw.SizedBox(height: 20),
              pw.Text("Thank you for your kind donation of RM $amountRM for ${widget.totalQuantity} package(s)."),
              pw.Text("This letter serves as official acknowledgment for tax exemption purposes."),
              pw.SizedBox(height: 40),
              pw.Text("Issued by: Kita Tongtong Organization"),
              pw.SizedBox(height: 10),
              pw.Text("Reg. No: XXXXXX-X"),
              pw.Text("Address: 123 Charity Lane, Kuala Lumpur, Malaysia"),
            ],
          ),
        ),
      ),
    );
    return pdf.save();
  }

  Widget buildFormInput(String label, Widget inputField, {String? errorText}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Color(0xFFF1D789), fontSize: 14),
          ),
          const SizedBox(height: 4),
          inputField,
          if (errorText != null)
            Padding(
              padding: const EdgeInsets.only(top: 5.0, left: 12.0),
              child: Text(
                errorText,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1C1C),
        iconTheme: const IconThemeData(color: Color(0xFFFDB515)),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Help Asnaf by Package (${widget.totalQuantity} selected)',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFDB515),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            const Text(
              "Donor’s information",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFDB515),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Expanded(
                  flex: 2,
                  child: Text(
                    "Would you like a tax exemption letter to be sent to you?",
                    style: TextStyle(color: Color(0xFFF1D789)),
                  ),
                ),
                Row(
                  children: [
                    Radio<bool>(
                      value: true,
                      groupValue: wantsTaxExemption,
                      activeColor: const Color(0xFFFDB515),
                      onChanged: (value) {
                        setState(() => wantsTaxExemption = true);
                      },
                    ),
                    const Text("Yes", style: TextStyle(color: Colors.white)),
                    Radio<bool>(
                      value: false,
                      groupValue: wantsTaxExemption,
                      activeColor: const Color(0xFFFDB515),
                      onChanged: (value) {
                        setState(() => wantsTaxExemption = false);
                      },
                    ),
                    const Text("No", style: TextStyle(color: Colors.white)),
                  ],
                )
              ],
            ),
            buildFormInput(
              'Designation',
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFCF40),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: DropdownButton<String>(
                  value: selectedSalutation,
                  hint: const Text("Select", style: TextStyle(color: Colors.black54)),
                  isExpanded: true,
                  underline: Container(),
                  dropdownColor: const Color(0xFFFFCF40),
                  iconEnabledColor: Colors.black,
                  items: salutations.map((val) {
                    return DropdownMenuItem(
                      value: val,
                      child: Text(val, style: const TextStyle(color: Colors.black)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => selectedSalutation = value);
                  },
                ),
              ),
            ),
            buildFormInput(
              'Full Name',
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFCF40),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _nameError != null ? Colors.red : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: TextField(
                  controller: nameController,
                  style: const TextStyle(color: Colors.black),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Enter full name',
                    hintStyle: TextStyle(color: Colors.black54),
                  ),
                ),
              ),
              errorText: _nameError,
            ),
            buildFormInput(
              'Email',
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFCF40),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _emailError != null ? Colors.red : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: Colors.black),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Enter email',
                    hintStyle: TextStyle(color: Colors.black54),
                  ),
                ),
              ),
              errorText: _emailError,
            ),
            buildFormInput(
              'Contact Number',
              Container(
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFCF40),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _contactError != null ? Colors.red : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12.0),
                      child: Text(
                        "+60",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    Container(
                        height: 30,
                        child: const VerticalDivider(color: Colors.black54, thickness: 1)
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left:8.0, right: 12.0),
                        child: TextField(
                          controller: contactController,
                          keyboardType: TextInputType.phone,
                          style: const TextStyle(color: Colors.black, fontSize: 16),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: "Enter mobile number",
                            hintStyle: TextStyle(color: Colors.black54),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              errorText: _contactError,
            ),

            const SizedBox(height: 20),
            const Divider(color: Colors.white, thickness: 2),
            const SizedBox(height: 20),
            const Text(
              "Payment Method",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFDB515),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1D789),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Image.asset('assets/bankcard.png', height: 40),
                      const SizedBox(height: 8),
                      const Text('Card',
                          style: TextStyle(
                            color: Color(0xFFA67C00),
                            fontWeight: FontWeight.bold,
                          )),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  width: 100,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1D789),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Image.asset('assets/fpx.png', height: 40),
                      const SizedBox(height: 8),
                      const Text('FPX',
                          style: TextStyle(
                            color: Color(0xFFA67C00),
                            fontWeight: FontWeight.bold,
                          )),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: 160,
              height: 45,
              child: ElevatedButton(
                onPressed: () async {
                  _validateName();
                  _validateEmail();
                  _validateContact();

                  if (_nameError != null || _emailError != null || _contactError != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please fix the errors before submitting.')),
                    );
                    return;
                  }

                  final String amountInCents = (widget.overallAmount * 100).toInt().toString();

                  final donationData = {
                    'amount': widget.overallAmount, // RM amount
                    'totalQuantity': widget.totalQuantity,
                    'designation': selectedSalutation ?? '',
                    'name': nameController.text.trim(),
                    'email': emailController.text.trim(),
                    'contact': contactController.text.trim(),
                    'timestamp': FieldValue.serverTimestamp(),
                    'type': 'package'
                  };

                  await FirebaseFirestore.instance.collection('donation').add(donationData);

                  await FirebaseFirestore.instance
                      .collection('notifications')
                      .add({
                    'createdAt': FieldValue.serverTimestamp(),
                    'recipientRole': 'Admin',
                    'message': 'Donor ${nameController.text.trim()} donated RM ${widget.overallAmount} via package.',
                  });

                  if (wantsTaxExemption) {
                    try {
                      final pdfBytes = await generatePdfBytes(
                        name: nameController.text.trim(),
                        email: emailController.text.trim(),
                        amountRM: widget.overallAmount.toString(),
                      );
                      await sendTaxEmail(
                        name: nameController.text.trim(),
                        recipientEmail: emailController.text.trim(),
                        pdfBytes: pdfBytes,
                      );
                    } catch (e) {
                      print('Error sending tax email for package: $e');
                    }
                  }

                  await processPackagePaymentAndRedirect(
                    context: context,
                    donationData: donationData,
                    name: nameController.text.trim(),
                    email: emailController.text.trim(),
                    phone: contactController.text.trim(),
                    amountInCents: amountInCents,
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Donation processing... Please follow payment instructions.')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEFBF04),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Donate Now',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}