const functions = require("firebase-functions");
const admin = require("firebase-admin");
const { Storage } = require("@google-cloud/storage");
const { createCanvas, loadImage } = require("canvas");

admin.initializeApp();
const storage = new Storage();

exports.generateVoucherImage = functions.https.onRequest(async (req, res) => {
  try {
    const { points, value } = req.body;
    if (!points || !value) {
      return res.status(400).send("Missing parameters");
    }

    const bucket = storage.bucket("gs://kita-tongtong.firebasestorage.app");
    const templatePath = "voucherTemplates/pointsVoucherTemplate.png"; // Replace with your actual template path
    const outputPath = `voucherBanner/${points}_points_RM${value}.png`;

    // Load the base voucher template
    const templateFile = bucket.file(templatePath);
    const [templateBuffer] = await templateFile.download();
    const templateImage = await loadImage(templateBuffer);

    // Create canvas with the same size as template
    const canvas = createCanvas(templateImage.width, templateImage.height);
    const ctx = canvas.getContext("2d");
    const centerX = canvas.width / 2;
    const centerY = canvas.height / 2;
    const lineSpacing = 110;
    const { registerFont } = require('canvas');
    const path = require('path');
    registerFont(path.resolve('Impact.ttf'), { family: 'Impact' });

    // Draw template on canvas
    ctx.drawImage(templateImage, 0, 0);

    // Set up styles
    ctx.textAlign = "center";
    ctx.fillStyle = "#ffffff";

    // Title
    ctx.font = "bold 100px Arial";
    ctx.fillText("Cash Voucher", centerX, centerY - (lineSpacing * 2.2));

    // Highlighted RM value
    ctx.font = "bold 200px Impact";
    ctx.fillStyle = "#c1ff72";
    ctx.fillText(`RM${value}`, centerX, centerY - lineSpacing * 0.6);

    // Subtitle
    ctx.font = "bold 100px Arial";
    ctx.fillStyle = "#ffffff";
    ctx.fillText("with", centerX, centerY + lineSpacing * 0.6);

    // Points info centered below
    ctx.font = "bold 100px Arial";
    ctx.fillText(`${points} points`, centerX, centerY + lineSpacing * 1.7);

    // Save image
    const buffer = canvas.toBuffer("image/png");
    const newFile = bucket.file(outputPath);
    await newFile.save(buffer, { contentType: "image/png" });

    const [url] = await newFile.getSignedUrl({ action: "read", expires: "03-01-2030" });

    res.json({ image_url: url });
  } catch (error) {
    console.error("Error generating image:", error);
    res.status(500).send("Error generating voucher image");
  }
});
