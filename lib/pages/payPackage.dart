import 'package:flutter/material.dart';
import 'package:projects/widgets/bottomNavBar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:projects/pages/email_service.dart';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'dart:convert';
// flutter_dotenv import is no longer needed for these keys
import 'package:projects/pages/PaymentWebview.dart';
import 'package:projects/config/app_config.dart'; // Import AppConfig

import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:url_launcher/url_launcher.dart';

class PayPackage extends StatefulWidget {
  final int totalQuantity;
  final int overallAmount;

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

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      FirebaseFirestore.instance.collection('users').doc(user.uid).get().then((doc) {
        if (doc.exists) {
          final data = doc.data()!;
          nameController.text = data['name'] ?? '';
          emailController.text = data['email'] ?? '';
          contactController.text = data['phone'] ?? '';
        }
      });
    }
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
    final String billplzApiKey       = AppConfig.getBillPlzApiKey();
    final String billplzCollectionId = AppConfig.getBillPlzCollectionId();
    final String billExternalRef = 'TXN${DateTime.now().millisecondsSinceEpoch}';

    String billReturnUrl;
    String billCallbackUrl;

    if (kIsWeb) {
      billReturnUrl   = '$webAppDomain/payment-redirect';
      billCallbackUrl = '$webAppDomain/payment-callback-server';
    } else {
      billReturnUrl   = 'myapp://payment-result?status=success';
      billCallbackUrl = 'myapp://payment-result?status=fail';
    }

    print("--- Billplz Request Data (Package) ---");
    print("userSecretKey (length): ${billplzApiKey.isNotEmpty ? billplzApiKey.substring(0, 5) + '...' : 'EMPTY'}");
    print("categoryCode: $billplzCollectionId");
    print("billReturnUrl: $billReturnUrl");
    print("billCallbackUrl: $billCallbackUrl");
    print("billAmount: $amountInCents");
    print("--- End Billplz Request Data ---");

    // Build Basic Auth header (API key + colon, Base64-encoded)
    final String basicAuth = 'Basic ' + base64Encode(utf8.encode('$billplzApiKey:'));

    // Billplz “create bill” endpoint. "collection_id" is sent as form data
    // rather than encoded in the URL path.
    final Uri url = Uri.parse('https://www.billplz.com/api/v3/bills');

    // Form-encoded fields for Billplz
    final Map<String, String> formData = {
      'collection_id' : billplzCollectionId,
      'name'          : name,
      'email'         : email,
      'amount'        : amountInCents,
      'description'   : 'Donation of ${widget.totalQuantity} package(s)',
      'callback_url'  : billCallbackUrl,
      'redirect_url'  : billReturnUrl,
      'mobile'        : phone,
      'reference_1_label': 'Ref',
      'reference_1'      : billExternalRef,
    };

    final response = await http.post(
      url,
      headers: {
        'Authorization': basicAuth,
        'Content-Type' : 'application/x-www-form-urlencoded',
      },
      body: formData,
    );

    if (response.statusCode == 200) {
      final dynamic data = jsonDecode(response.body);
      if (data['data'] != null && data['data']['url'] != null) {
        final String paymentGatewayUrl = data['data']['url'];

        if (kIsWeb) {
          if (!await launchUrl(Uri.parse(paymentGatewayUrl))) {
            print("Could not launch $paymentGatewayUrl");
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
                builder: (_) => PaymentWebView(
                  paymentUrl: paymentGatewayUrl,
                  donationData: donationData,
                ),
              ),
            );
          }
        }
      } else {
        print("Billplz bill creation successful, but response format unexpected: ${response.body}");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Payment initiation error. Please try again.")),
          );
        }
      }
    } else {
      print("Billplz bill creation failed: Status ${response.statusCode} - Body: ${response.body}");
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

  Widget buildFormInput(String label, Widget inputField) {
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
        title: const Text('Donate Package', style: TextStyle(color: Color(0xFFFDB515))),
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
            SizedBox(height: 8),
            Text(
              'Total Amount: RM ${widget.overallAmount}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
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
            ),
            buildFormInput(
              'Email',
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFCF40),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TextField(
                  controller: emailController,
                  style: const TextStyle(color: Colors.black),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Enter email',
                    hintStyle: TextStyle(color: Colors.black54),
                  ),
                ),
              ),
            ),
            buildFormInput(
              'Contact Number',
              Container(
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFCF40),
                  borderRadius: BorderRadius.circular(10),
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
                  final String amountInCents = (widget.overallAmount * 100).toString();

                  final donationData = {
                    'amount': widget.overallAmount.toString(), // RM amount
                    'totalQuantity': widget.totalQuantity,
                    'designation': selectedSalutation ?? '',
                    'name': nameController.text.trim(),
                    'email': emailController.text.trim(),
                    'contact': contactController.text.trim(),
                    'timestamp': FieldValue.serverTimestamp(),
                    'type': 'package'
                  };

                  if (donationData['name'] == '' || donationData['email'] == '' || donationData['contact'] == '') {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please fill in all donor details.')),
                      );
                    }
                    return;
                  }

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
                      if (!kIsWeb) {
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
                      } else {
                        print("Email sending via 'mailer' is not supported on web. PDF generation skipped for web in this path too.");
                      }
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