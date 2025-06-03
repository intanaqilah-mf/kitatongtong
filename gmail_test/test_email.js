const nodemailer = require('nodemailer');

// --- YOUR CREDENTIALS TO TEST ---
const GMAIL_EMAIL_TO_TEST = "mohdfaddilintan@gmail.com";
const GMAIL_APP_PASSWORD_TO_TEST = "kqpqhywafkzwflem"; // Your App Password
const RECIPIENT_EMAIL = "mohdfaddilintan@gmail.com"; // Or any other email you can check

async function sendTestEmail() {
  if (!GMAIL_EMAIL_TO_TEST || !GMAIL_APP_PASSWORD_TO_TEST) {
    console.error("Please set your Gmail email and App Password in the script.");
    return;
  }

  // Create a Nodemailer transporter using Gmail
  let transporter = nodemailer.createTransport({
    service: 'gmail',
    auth: {
      user: GMAIL_EMAIL_TO_TEST,
      pass: GMAIL_APP_PASSWORD_TO_TEST,
    },
  });

  // Email options
  let mailOptions = {
    from: `"Test Script" <${GMAIL_EMAIL_TO_TEST}>`,
    to: RECIPIENT_EMAIL, // Email address to send to
    subject: 'Nodemailer Gmail App Password Test',
    text: 'This is a test email sent using Nodemailer and a Gmail App Password.',
    html: '<b>This is a test email sent using Nodemailer and a Gmail App Password.</b>',
  };

  try {
    console.log(`Attempting to send test email from ${GMAIL_EMAIL_TO_TEST} to ${RECIPIENT_EMAIL}...`);
    let info = await transporter.sendMail(mailOptions);
    console.log('Test email sent successfully!');
    console.log('Message ID:', info.messageId);
    console.log('Preview URL:', nodemailer.getTestMessageUrl(info)); // Only for ethereal, not applicable for Gmail direct send
  } catch (error) {
    console.error('Failed to send test email:');
    console.error(error);
  }
}

sendTestEmail();