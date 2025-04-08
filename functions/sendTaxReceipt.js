const { onObjectFinalized } = require("firebase-functions/v2/storage");
const { config } = require("firebase-functions");
const admin = require("firebase-admin");
const nodemailer = require("nodemailer");
const path = require("path");
const os = require("os");
const fs = require("fs");

// Do NOT call admin.initializeApp() here because it's already called in your index.js
// admin.initializeApp();

const configData = config();
const GMAIL_EMAIL = configData.gmail.email;
const GMAIL_PASSWORD = configData.gmail.password;

const transporter = nodemailer.createTransport({
  service: "gmail",
  auth: {
    user: GMAIL_EMAIL,
    pass: GMAIL_PASSWORD,
  },
});

exports.sendTaxReceipt = onObjectFinalized(
  {
    region: "asia-southeast1",
  },
  async (event) => {
    const object = event.data;
    const filePath = object.name;

    // Only process files in the "receipts/" folder
    if (!filePath.startsWith("receipts/")) return null;

    const fileName = path.basename(filePath);
    const bucket = admin.storage().bucket();
    const tempFilePath = path.join(os.tmpdir(), fileName);

    // Download the PDF file locally
    await bucket.file(filePath).download({ destination: tempFilePath });

    // Expecting filename to be in format: Name_Email_Timestamp.pdf
    const match = fileName.match(/^(.+?)_(.+?)_\d+\.pdf$/);
    if (!match) return null;

    const name = decodeURIComponent(match[1]);
    const email = decodeURIComponent(match[2]);

    const mailOptions = {
      from: `Your Organization <${GMAIL_EMAIL}>`,
      to: email,
      subject: "Tax Exemption Letter",
      text: `Hi ${name},\n\nThank you for your donation. Please find your tax exemption letter attached.`,
      attachments: [
        {
          filename: "tax_receipt.pdf",
          path: tempFilePath,
        },
      ],
    };

    await transporter.sendMail(mailOptions);
    console.log(`✅ Email sent to ${email}`);
    return null;
  }
);
