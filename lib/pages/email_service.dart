import 'dart:io'; // dart:io is not available on web
import 'dart:typed_data';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:projects/config/app_config.dart'; // Import AppConfig
import 'package:flutter/foundation.dart' show kIsWeb;

Future<void> sendTaxEmail({
  required String name,
  required String recipientEmail,
  required Uint8List pdfBytes,
}) async {
  // This function should ideally not be called directly on web if using mailer for SMTP.
  // The logic in amount.dart/payPackage.dart already prevents this.
  if (kIsWeb) {
    print("sendTaxEmail: Direct SMTP sending is skipped on web.");
    // If you have a backend function for sending emails from web, trigger it here.
    return;
  }

  final String smtpHost = AppConfig.getSmtpHost();
  final int smtpPort = AppConfig.getSmtpPort();
  final String smtpUsername = AppConfig.getSmtpUsername();
  final String smtpPassword = AppConfig.getSmtpPassword();
  final String senderEmail = AppConfig.getSenderEmail();

  if (smtpHost.isEmpty || smtpUsername.isEmpty || smtpPassword.isEmpty || senderEmail.isEmpty || smtpPort == 0) {
    print('SMTP configuration is incomplete. Email will not be sent.');
    return;
  }

  // Using SmtpServer directly for more general configuration
  final smtpServer = SmtpServer(smtpHost,
    port: smtpPort,
    ssl: (smtpPort == 465 || smtpPort == 587), // SSL for 465, STARTTLS often for 587 (mailer handles STARTTLS if available)
    username: smtpUsername,
    password: smtpPassword,
    ignoreBadCertificate: false, // Set to true only if absolutely necessary for testing with self-signed certs
    allowInsecure: false, // Ensure this is false for production
  );
  // If your server specifically uses the 'gmail' helper from mailer, and you provide username/app_password:
  // final smtpServer = gmail(smtpUsername, smtpPassword);


  // Create a temporary file (only works on mobile/desktop, not web)
  // For web, you'd need a backend to handle email with attachment.
  File? tempFile;
  String? tempFilePath;

  try {
    // The Directory.systemTemp might not be writable or behave as expected in all environments
    // or might be restricted. For robust mobile/desktop, path_provider is better, but let's try.
    // This part will not run on web due to the kIsWeb check above.
    if (!kIsWeb) { // Redundant check, but emphasizes this is non-web
      final tempDir = await Directory.systemTemp.createTemp('kita_tongtong_receipts');
      tempFilePath = '${tempDir.path}/tax_receipt_${DateTime.now().millisecondsSinceEpoch}.pdf';
      tempFile = File(tempFilePath);
      await tempFile.writeAsBytes(pdfBytes);
      print("PDF written to temp file: $tempFilePath");
    } else {
      print("Skipping temp file creation for PDF on web.");
      return; // Cannot proceed with mailer attachments easily from web client-side
    }


    final message = Message()
      ..from = Address(senderEmail, 'Kita Tongtong') // Use configured sender email
      ..recipients.add(recipientEmail)
      ..subject = 'Tax Exemption Letter - Kita Tongtong Donation'
      ..html = """
      <p>Hi $name,</p>
      <p>Thank you for your generous donation to Kita Tongtong. We greatly appreciate your support.</p>
      <p>Please find your tax exemption letter attached to this email.</p>
      <p>If you have any questions, feel free to contact us.</p>
      <p>Sincerely,<br>The Kita Tongtong Team</p>
      """
      ..attachments = [
        if (tempFile != null) FileAttachment(tempFile)..fileName = 'tax_receipt.pdf',
      ];

    print("Attempting to send email to: $recipientEmail via $smtpHost");
    final sendReport = await send(message, smtpServer);
    } catch (e, s) {
    print('❌ Email sending failed: $e');
    print('Stack trace: $s');
    // Do not rethrow here unless you want to halt the calling process.
    // Let the calling function decide how to handle the email failure.
  } finally {
    // Clean up the temporary file if it was created (mobile/desktop only)
    if (tempFile != null && await tempFile.exists()) {
      try {
        await tempFile.delete();
        print("Temporary PDF file deleted: $tempFilePath");
      } catch (e) {
        print("Error deleting temporary PDF file: $e");
      }
    }
  }
}