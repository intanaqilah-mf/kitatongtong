import 'package:flutter/material.dart';
import 'package:projects/widgets/bottomNavBar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:projects/pages/email_service.dart';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:projects/pages/PaymentWebview.dart';

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
  // Controllers for donor's information
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController contactController = TextEditingController();

  // Variables for donor designation and tax exemption option
  String? selectedSalutation;
  bool wantsTaxExemption = false;

  // Predefined list of salutations
  final List<String> salutations = ['Mr.', 'Ms.', 'Mrs.', 'Dr.', 'Prof.'];

  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();

    // Pre-fill donor info if user is available, similar to amount.dart
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
  Future<void> redirectToToyyibPayWebView({
    required BuildContext context,
    required Map<String, dynamic> donationData,
    required String name,
    required String email,
    required String phone,
    required String amount, // amount in "cents" (as a string, e.g. "1000")
  }) async {
    final response = await http.post(
      Uri.parse('https://toyyibpay.com/index.php/api/createBill'),
      body: {
        'userSecretKey': dotenv.env['TOYYIBPAY_SECRET_KEY'],
        'categoryCode': dotenv.env['TOYYIBPAY_CATEGORY_CODE'],
        'billName': 'Kita Tongtong Donation',
        'billDescription': 'Donation to Asnaf Program',
        'billPriceSetting': '1',
        'billPayorInfo': '1',
        'billAmount': amount, // amount in cents
        // Use your custom deep link URLs in both fields:
        'billReturnUrl': 'myapp://payment-result?status=success',
        'billCallbackUrl': 'myapp://payment-result?status=fail',
        'billExternalReferenceNo': 'TXN${DateTime.now().millisecondsSinceEpoch}',
        'billTo': name,
        'billEmail': email,
        'billPhone': phone,
        'billSplitPayment': '0',
        'billPaymentChannel': '0',
        'billDisplayMerchant': '1'
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final billCode = data[0]['BillCode'];
      final url = 'https://toyyibpay.com/$billCode';
      // Instead of launching an external browser, navigate to our PaymentWebView
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentWebView(paymentUrl: url, donationData: donationData),
        ),
      );
    } else {
      print("ToyyibPay bill creation failed: ${response.body}");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to initiate payment.")),
      );
    }
  }

  Future<Uint8List> generatePdfBytes({required String name, required String email, required String amount}) async {
    final pdf = pw.Document();
    final now = DateTime.now();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Center(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text("Tax Exemption Receipt", style: pw.TextStyle(fontSize: 24)),
              pw.SizedBox(height: 20),
              pw.Text("To: $name"),
              pw.Text("Email: $email"),
              pw.Text("Date: ${now.toLocal()}"),
              pw.SizedBox(height: 20),
              pw.Text("Thank you for your kind donation of RM $amount."),
              pw.Text("This letter serves as official acknowledgment for tax exemption purposes."),
              pw.SizedBox(height: 20),
              pw.Text("Issued by: MADAD"),
            ],
          ),
        ),
      ),
    );
    return pdf.save();
  }

  // Helper widget for a labeled input field
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
      // Navigation logic if needed.
    });
  }

  @override
  Widget build(BuildContext context) {
    // In this version, the overall donation amount is passed from PackagePage (widget.overallAmount)
    // and no explicit amount selection UI is needed.
    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1C1C),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Help Asnaf by Package',
              style: TextStyle(
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
                        setState(() {
                          wantsTaxExemption = true;
                        });
                      },
                    ),
                    const Text("Yes", style: TextStyle(color: Colors.white)),
                    Radio<bool>(
                      value: false,
                      groupValue: wantsTaxExemption,
                      activeColor: const Color(0xFFFDB515),
                      onChanged: (value) {
                        setState(() {
                          wantsTaxExemption = false;
                        });
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
                  hint: const Text("Select", style: TextStyle(color: Colors.black)),
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
                    setState(() {
                      selectedSalutation = value;
                    });
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
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Enter full name',
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
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Enter email',
                  ),
                ),
              ),
            ),
            buildFormInput(
              'Contact Number',
              Container(
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFCF40),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text(
                        "+60",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    const VerticalDivider(color: Colors.black, thickness: 1),
                    Expanded(
                      child: TextField(
                        controller: contactController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(8),
                          hintText: "Enter your mobile number",
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
                // Card box
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
                // FPX box
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
                  print("Donate Now pressed");

                  final donationAmount = (widget.overallAmount * 100).toString();  // RM10 → "1000"

                  final donationData = {
                    'amount': donationAmount,
                    'designation': selectedSalutation,
                    'name': nameController.text,
                    'email': emailController.text,
                    'contact': contactController.text,
                    'timestamp': FieldValue.serverTimestamp(),
                  };

                  await FirebaseFirestore.instance.collection('donation').add(donationData);
                  final now = DateTime.now();
                  await FirebaseFirestore.instance
                      .collection('notifications')
                      .add({
                    'date': now.toIso8601String(),
                    'role': 'Admin',
                    'message':
                    'Donor ${nameController.text} donated RM ${widget.overallAmount}',
                  });

                  if (wantsTaxExemption) {
                    try {
                      final pdfBytes = await generatePdfBytes(
                        name: nameController.text,
                        email: emailController.text,
                        amount: donationAmount,
                      );
                      print("PDF generated, bytes length: ${pdfBytes.length}");

                      await sendTaxEmail(
                        name: nameController.text,
                        recipientEmail: emailController.text,
                        pdfBytes: pdfBytes,
                      );
                    } catch (e) {
                      print('Error sending tax email: $e');
                    }
                  }
                  await redirectToToyyibPayWebView(
                    context: context,
                    donationData: donationData,
                    name: nameController.text,
                    email: emailController.text,
                    phone: contactController.text,
                    amount: donationAmount,  // pass the amount in cents string
                  );

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Donation submitted successfully!')),
                  );
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