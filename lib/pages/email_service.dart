import 'dart:io';
import 'dart:typed_data';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
// Removed path_provider import

Future<void> sendTaxEmail({
  required String name,
  required String recipientEmail,
  required Uint8List pdfBytes,
}) async {
  final smtpServer = gmail(
    'mohdfaddilintan@gmail.com', // your sender email
    'kqpqhywafkzwflem',           // Gmail App Password
  );

  // Use system temp directory instead of getTemporaryDirectory()
  final tempDir = Directory.systemTemp;
  print("Temp directory: ${tempDir.path}");
  final tempFilePath = '${tempDir.path}/tax_receipt.pdf';
  final tempFile = File(tempFilePath);
  await tempFile.writeAsBytes(pdfBytes);
  print("PDF written to temp file: $tempFilePath");

  // Build the email message.
  final message = Message()
    ..from = Address('mohdfaddilintan@gmail.com', 'kita_tongtong')
    ..recipients.add(recipientEmail)
    ..subject = 'Tax Exemption Letter'
    ..text = 'Hi $name,\n\nThank you for your donation. Please find your tax exemption letter attached.'
    ..attachments = [
      FileAttachment(tempFile)..fileName = 'tax_receipt.pdf'
    ];

  try {
    print("About to send email to: $recipientEmail");
    final sendReport = await send(message, smtpServer);
    print('✅ Email sent: $sendReport');
  } catch (e) {
    print('❌ Email sending failed: $e');
    rethrow;
  }
}
