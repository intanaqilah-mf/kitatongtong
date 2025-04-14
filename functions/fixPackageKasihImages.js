const functions = require("firebase-functions");
const admin = require("firebase-admin");
const { createCanvas, loadImage, registerFont } = require("canvas");
const fetch = require("node-fetch");
const path = require("path");

admin.initializeApp();

// Use Firebase Admin's Storage; this automatically uses the correct service account in production.
const bucket = admin.storage().bucket();

// Register your custom font. Ensure Impact.ttf is in your functions folder.
registerFont(path.resolve("Impact.ttf"), { family: "Impact" });

exports.generateVoucherImage = functions.https.onRequest(async (req, res) => {
  try {
    const { points, value } = req.body;
    if (!points || !value) {
      return res.status(400).send("Missing parameters");
    }

    // Define the template image path and the output path.
    const templatePath = "voucherTemplates/pointsVoucherTemplate.png"; // Ensure this file exists in Storage.
    const outputPath = `voucherBanner/${points}_points_RM${value}.png`;

    // Download template image from Storage.
    const templateFile = bucket.file(templatePath);
    const [templateBuffer] = await templateFile.download();
    const templateImage = await loadImage(templateBuffer);

    // Create canvas with the template size.
    const canvas = createCanvas(templateImage.width, templateImage.height);
    const ctx = canvas.getContext("2d");
    const centerX = canvas.width / 2;
    const centerY = canvas.height / 2;
    const lineSpacing = 110;

    // Draw the base template.
    ctx.drawImage(templateImage, 0, 0);

    // Draw the overlay text.
    ctx.textAlign = "center";

    // Title
    ctx.font = "bold 100px Arial";
    ctx.fillStyle = "#ffffff";
    ctx.fillText("Cash Voucher", centerX, centerY - lineSpacing * 2.2);

    // Highlighted RM value using Impact font.
    ctx.font = "bold 200px Impact";
    ctx.fillStyle = "#c1ff72";
    ctx.fillText(`RM${value}`, centerX, centerY - lineSpacing * 0.6);

    // Subtitle
    ctx.font = "bold 100px Arial";
    ctx.fillStyle = "#ffffff";
    ctx.fillText("with", centerX, centerY + lineSpacing * 0.6);

    // Points information.
    ctx.font = "bold 100px Arial";
    ctx.fillText(`${points} points`, centerX, centerY + lineSpacing * 1.7);

    // Convert canvas to a PNG buffer.
    const buffer = canvas.toBuffer("image/png");

    // Reference the file in the bucket.
    const newFile = bucket.file(outputPath);
    try {
      const [exists] = await newFile.exists();
      if (exists) {
        // If the file exists, delete it before saving the new one.
        await newFile.delete();
        console.log(`🗑️ Existing image deleted: ${outputPath}`);
      }
    } catch (err) {
      console.warn(`⚠️ Could not delete file "${outputPath}" (possibly non-existent): ${err.message}`);
    }

    // Save the new image buffer.
    await newFile.save(buffer, { contentType: "image/png" });
    console.log(`✅ New image saved: ${outputPath}`);

    // Generate a signed URL for the image (valid until March 1, 2030).
    const [url] = await newFile.getSignedUrl({ action: "read", expires: "03-01-2030" });
    res.json({ image_url: url });
  } catch (error) {
    console.error("🔥 FULL ERROR generating voucher image:", error);
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

    // Use the same bucket as above.
    // Fill background.
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

    // Iterate through each item to draw its image.
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
        console.log(`Reused image for: ${query}`);
      } else {
        // If the image is not found, query Serper.
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
        console.log(`Queried Serper for: ${query} → ${imageUrl}`);
        if (imageUrl) {
          const imgRes = await fetch(imageUrl);
          if (!imgRes.ok) throw new Error("Image fetch failed");
          const buffer = await imgRes.buffer();
          img = await loadImage(buffer);
          // Save the fetched image to Storage for future reuse.
          await imageFile.save(buffer, { contentType: "image/jpeg" });
        }
      }

      if (img) {
        // Center-crop the image.
        const aspect = img.width / img.height;
        let sx = 0,
          sy = 0,
          sWidth = img.width,
          sHeight = img.height;
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

    // Finalize the canvas image.
    const finalBuffer = canvas.toBuffer("image/png");
    const outputPath = `package_kasih_banner/packageKasih_${Date.now()}.png`;
    const file = bucket.file(outputPath);
    await file.save(finalBuffer, { contentType: "image/png" });

    const [signedUrl] = await file.getSignedUrl({ action: "read", expires: "03-01-2030" });
    res.json({ image_url: signedUrl });
  } catch (err) {
    console.error("Error generating package kasih image:", err);
    res.status(500).send("Failed to generate image.");
  }
});
