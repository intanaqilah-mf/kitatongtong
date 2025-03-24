const functions = require("firebase-functions");
const admin = require("firebase-admin");
const { Storage } = require("@google-cloud/storage");
const { createCanvas, loadImage } = require("canvas");

admin.initializeApp();
const storage = new Storage();
const fetch = require("node-fetch");

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

exports.generatePackageKasihImage = functions.https.onRequest(async (req, res) => {
  try {
    const { items } = req.body;
    if (!items || !Array.isArray(items) || items.length === 0) {
      return res.status(400).send("Missing or invalid items");
    }

    const serperKey = "aa6cd4b37689f3ab0ba650c83a9a286fb9462e9c";
    const canvas = createCanvas(1024, 768);
    const ctx = canvas.getContext("2d");
    const bucket = storage.bucket("gs://kita-tongtong.firebasestorage.app");

    ctx.fillStyle = "#FFF4D4";
    ctx.fillRect(0, 0, 1024, 768);

    const totalItems = items.length;
    const itemsPerRow = 3;
    const imageSize = 200;
    const padding = 40;
    const canvasWidth = 1024;
    const rows = Math.ceil(totalItems / itemsPerRow);
    const canvasHeight = 768;
    const totalHeight = rows * imageSize + (rows - 1) * padding;
    const offsetY = (canvasHeight - totalHeight) / 2;

    for (let i = 0; i < totalItems; i++) {
      const item = items[i];
      const query = item.name;
      const safeName = query.toLowerCase().replace(/\s+/g, "_");
      const imageFilePath = `packageItemsImageBank/${safeName}.jpg`;
      const imageFile = bucket.file(imageFilePath);

      const row = Math.floor(i / itemsPerRow);
      const col = i % itemsPerRow;
      const totalCols = Math.min(itemsPerRow, totalItems - row * itemsPerRow);
      const rowWidth = totalCols * imageSize + (totalCols - 1) * padding;
      const offsetX = (canvasWidth - rowWidth) / 2;
      const x = offsetX + col * (imageSize + padding);
        const y = offsetY + row * (imageSize + padding);

      let img = null;

      const [exists] = await imageFile.exists();
      if (exists) {
        const [buffer] = await imageFile.download();
        img = await loadImage(buffer);
        console.log(`✅ Reused image for: ${query}`);
      } else {
        // ❌ Not found, fetch from Serper.dev
        const serperRes = await fetch("https://google.serper.dev/images", {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            "X-API-KEY": serperKey,
          },
          body: JSON.stringify({ q: query }),
        });

        const serperData = await serperRes.json();
        const imageUrl = serperData.images?.[0]?.imageUrl;
        console.log(`🔍 Queried Serper for: ${query} → ${imageUrl}`);

        if (imageUrl) {
          const imgRes = await fetch(imageUrl);
          if (!imgRes.ok) throw new Error("Image fetch failed");

          const buffer = await imgRes.buffer();
          img = await loadImage(buffer);

          // ✅ Save for future reuse
          await imageFile.save(buffer, { contentType: "image/jpeg" });
        }
      }

      // Draw image (center-cropped square)
      if (img) {
        const aspect = img.width / img.height;
        let sx = 0, sy = 0, sWidth = img.width, sHeight = img.height;

        if (aspect > 1) {
          sx = (img.width - img.height) / 2;
          sWidth = img.height;
        } else if (aspect < 1) {
          sy = (img.height - img.width) / 2;
          sHeight = img.width;
        }

        ctx.drawImage(img, sx, sy, sWidth, sHeight, x, y, imageSize, imageSize);
        ctx.fillStyle = "#000";
        ctx.font = "20px Arial";
        ctx.fillText(query, x, y + imageSize + 20);
      }
    }

    const finalBuffer = canvas.toBuffer("image/png");
    const outputPath = `package_kasih_banner/packageKasih_${Date.now()}.png`;
    const file = bucket.file(outputPath);
    await file.save(finalBuffer, { contentType: "image/png" });

    const [signedUrl] = await file.getSignedUrl({
      action: "read",
      expires: "03-01-2030"
    });

    res.json({ image_url: signedUrl });
  } catch (err) {
    console.error("❌ Error generating image:", err);
    res.status(500).send("Failed to generate image.");
  }
});
