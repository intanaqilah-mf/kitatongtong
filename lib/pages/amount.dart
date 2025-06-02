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

class AmountPage extends StatefulWidget {
  const AmountPage({super.key});

  @override
  State<AmountPage> createState() => _AmountPageState();
}

class _AmountPageState extends State<AmountPage> {
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

  Future<void> processPaymentAndRedirect({
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
      print("ToyyibPay configuration (secret key or category code) is missing or empty from AppConfig.");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Payment configuration error. Please contact support.")),
        );
      }
      return;
    }

    print("--- ToyyibPay Request Data (Amount) ---");
    print("userSecretKey (length): ${toyyibpaySecretKey.length > 0 ? toyyibpaySecretKey.substring(0,5)+"..." : "EMPTY"}");
    print("categoryCode: $toyyibpayCategoryCode");
    print("billReturnUrl: $billReturnUrl");
    print("billCallbackUrl: $billCallbackUrl");
    print("billAmount: $amountInCents");
    print("--- End ToyyibPay Request Data ---");

    final response = await http.post(
      Uri.parse('https://toyyibpay.com/index.php/api/createBill'),
      body: {
        'userSecretKey': toyyibpaySecretKey,
        'categoryCode': toyyibpayCategoryCode,
        'billName': 'Kita Tongtong Donation',
        'billDescription': 'Donation to Asnaf Program',
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
                builder: (_) => PaymentWebView(paymentUrl: paymentGatewayUrl, donationData: donationData),
              ),
            );
          }
        }
      } else {
        print("ToyyibPay bill creation successful, but response format unexpected: ${response.body}");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Payment initiation error. Please try again.")),
          );
        }
      }
    } else {
      print("ToyyibPay bill creation failed: Status ${response.statusCode} - Body: ${response.body}");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to initiate payment.")),
        );
      }
    }
  }

  int _selectedIndex = 0;
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController otherAmountController = TextEditingController();
  final TextEditingController contactController = TextEditingController();

  String? selectedAmount;
  String? selectedSalutation;
  bool wantsTaxExemption = false;

  final List<String> salutations = ['Mr.', 'Ms.', 'Mrs.', 'Dr.', 'Prof.'];

  Widget buildAmountBox(String label) {
    final isOther = label == 'Other';
    final isSelected = selectedAmount == label;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedAmount = label;
        });
      },
      child: Container(
        height: 50,
        width: 100,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFDB515) : const Color(0xFFFFCF40),
          borderRadius: BorderRadius.circular(10),
        ),
        child: isOther && isSelected
            ? Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: TextField(
            controller: otherAmountController,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            autofocus: true,
            style: const TextStyle(color: Color(0xFFA67C00), fontWeight: FontWeight.bold, fontSize: 18),
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: 'Amount',
              hintStyle: TextStyle(color: Color(0xFFA67C00), fontWeight: FontWeight.normal),
            ),
          ),
        )
            : Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFFA67C00),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
    );
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

  Future<Uint8List> generatePdfBytes({required String name, required String email, required String amount}) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final String formattedAmount = double.tryParse(amount)?.toStringAsFixed(2) ?? amount;

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
              pw.Text("Thank you for your kind donation of RM $formattedAmount."),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1C),
      appBar: AppBar(
        title: const Text('Donate by Amount', style: TextStyle(color: Color(0xFFFDB515))),
        backgroundColor: const Color(0xFF1C1C1C),
        iconTheme: const IconThemeData(color: Color(0xFFFDB515)),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Help Asnaf by Amount',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFDB515),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: ['10', '20', '30', '50', 'Other']
                  .map((label) => buildAmountBox(label))
                  .toList(),
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
                        padding: const EdgeInsets.only(left: 8.0, right: 12.0),
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
                  final String rawAmountString = selectedAmount == 'Other'
                      ? otherAmountController.text.trim()
                      : selectedAmount ?? "";

                  if (rawAmountString.isEmpty) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please select or enter an amount.')),
                      );
                    }
                    return;
                  }

                  double? parsedAmount = double.tryParse(rawAmountString);
                  if (parsedAmount == null || parsedAmount <= 0) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter a valid amount.')),
                      );
                    }
                    return;
                  }

                  final int amountInCents = (parsedAmount * 100).round();

                  final donationData = {
                    'amount': parsedAmount.toStringAsFixed(2),
                    'designation': selectedSalutation ?? '',
                    'name': nameController.text.trim(),
                    'email': emailController.text.trim(),
                    'contact': contactController.text.trim(),
                    'timestamp': FieldValue.serverTimestamp(),
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
                    'message': 'Donor ${nameController.text.trim()} donated RM ${parsedAmount.toStringAsFixed(2)}',
                  });

                  if (wantsTaxExemption) {
                    try {
                      if (!kIsWeb) {
                        final pdfBytes = await generatePdfBytes(
                          name: nameController.text.trim(),
                          email: emailController.text.trim(),
                          amount: parsedAmount.toStringAsFixed(2),
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
                      print('Error during tax exemption email process: $e');
                    }
                  }

                  await processPaymentAndRedirect(
                    context: context,
                    donationData: donationData,
                    name: nameController.text.trim(),
                    email: emailController.text.trim(),
                    phone: contactController.text.trim(),
                    amountInCents: amountInCents.toString(),
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