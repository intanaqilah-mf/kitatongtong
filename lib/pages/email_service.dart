// lib/pages/email_service.dart
import 'dart:io'; // File operations are not available on web.
import 'dart:typed_data';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:projects/config/app_config.dart'; // Ensure this path is correct
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'dart:convert';

Future<void> sendTaxEmail({
  required String name,
  required String recipientEmail,
  required Uint8List pdfBytes,
}) async {
  if (kIsWeb) {
    // ---- WEB: Call Cloud Function ----
    print("Preparing to send tax email via Cloud Function for web.");
    try {
      String pdfBase64 = base64Encode(pdfBytes);

      // Ensure this URL is correct for your deployed Cloud Function
      final functionUrl = Uri.parse("https://sendemailwithpdf-m4nvbdigca-uc.a.run.app");

      //final functionUrl = Uri.parse("https://us-central1-kita-tongtong.cloudfunctions.net/sendEmailWithPdf");

      final response = await http.post(
        functionUrl,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          'name': name,
          'recipientEmail': recipientEmail,
          'pdfBase64': pdfBase64,
          'fileName': 'Tax_Receipt_KitaTongtong.pdf',
        }),
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        if (responseBody['success'] == true) {
          print('✅ Tax Email successfully triggered via Cloud Function for: $recipientEmail');
        } else {
          print('❌ Cloud Function reported an error: ${responseBody['message']}');
        }
      } else {
        print('❌ Failed to call Cloud Function: ${response.statusCode} - ${response.body}');
      }
    } catch (e, stackTrace) {
      print('❌ Error calling Cloud Function for email: $e');
      print('Stack trace: $stackTrace');
    }
    return; // End web execution for email
  }

  // ---- MOBILE: Direct SMTP ----
  final String smtpHost = AppConfig.getSmtpHost();
  final int smtpPort = AppConfig.getSmtpPort();
  final String smtpUsername = AppConfig.getSmtpUsername();
  final String smtpPassword = AppConfig.getSmtpPassword();
  final String senderEmail = AppConfig.getSenderEmail();

  if (smtpHost.isEmpty || smtpPort == 0 || smtpUsername.isEmpty || smtpPassword.isEmpty || senderEmail.isEmpty) {
    print('SMTP configuration is incomplete for mobile. Cannot send tax email.');
    print('Host: $smtpHost, Port: $smtpPort, UserSet: ${smtpUsername.isNotEmpty}, PassSet: ${smtpPassword.isNotEmpty}, SenderSet: ${senderEmail.isNotEmpty}');
    return;
  }

  SmtpServer serverConfig;
  if (smtpHost.toLowerCase().contains('gmail.com')) {
    serverConfig = gmail(smtpUsername, smtpPassword); // Uses configured username and app password
  } else {
    serverConfig = SmtpServer(
      smtpHost,
      port: smtpPort,
      username: smtpUsername,
      password: smtpPassword,
      ssl: (smtpPort == 465), // Typically SSL for port 465
      // For STARTTLS (often on port 587), mailer usually handles it if ssl:false and server supports it.
      // You might need to adjust 'ssl' based on your provider's requirements for other ports.
      allowInsecure: false,
      ignoreBadCertificate: false,
    );
  }

  File? tempFile;
  String? tempFilePath;

  try {
    final Directory tempDir = await Directory.systemTemp.createTemp('tax_receipts_mobile');
    tempFilePath = '${tempDir.path}/tax_receipt_${DateTime.now().millisecondsSinceEpoch}.pdf';
    tempFile = File(tempFilePath);
    await tempFile.writeAsBytes(pdfBytes);
    print("PDF for mobile email written to temp file: $tempFilePath");

    final message = Message()
      ..from = Address(senderEmail, 'Kita Tongtong Support')
      ..recipients.add(recipientEmail)
      ..subject = 'Your Tax Exemption Receipt - Kita Tongtong Donation'
      ..html = """
      <h3>Dear $name,</h3>
      <p>Thank you for your generous donation to Kita Tongtong. We greatly appreciate your support towards our cause.</p>
      <p>Please find your tax exemption receipt attached to this email.</p>
      <p>If you have any questions, feel free to contact us.</p>
      <p>Sincerely,<br>The Kita Tongtong Team</p>
      """
      ..attachments = [
        if (await tempFile.exists()) FileAttachment(tempFile)..fileName = 'Tax_Receipt_KitaTongtong.pdf',
      ];

    print("Attempting to send tax email (mobile) to: $recipientEmail via $smtpHost...");
    final sendReport = await send(message, serverConfig);

    // Check sendReport for problems - The SendReport class in mailer 6.x.x does not have a 'problems' getter.
    // It has 'sent' (bool) and 'validationProblems' (List<Problem>).
    // The 'mailSystemReport' (SmtpMessage) within 'message' (Message) also might not be directly accessible post-send for errors.
    // The send() function itself will throw an exception on failure.

    // If 'send' completes without throwing, it's generally considered successful at the transport level.
    // However, mailer might still populate `message.mailSystemReport` or throw specific exceptions for common issues.
    // For robust error checking, rely on the try-catch.
    print('✅ Tax Email Sent (mobile) successfully (or at least no immediate error from send operation).');

  } catch (e, s) {
    print('❌ Tax Email sending failed (mobile): $e');
    print('Stack trace: $s');
  } finally {
    if (tempFile != null && await tempFile.exists()) {
      try {
        await tempFile.delete();
        print("Temporary PDF file for mobile email deleted: $tempFilePath");
      } catch (e) {
        print("Error deleting temporary PDF file for mobile email: $e");
      }
    }
  }
}