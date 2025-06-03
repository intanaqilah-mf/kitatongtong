const functions = require("firebase-functions/v2");
const { onRequest } = require("firebase-functions/v2/https");
const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");

const admin = require("firebase-admin");
const nodemailer = require("nodemailer");
const { createCanvas, loadImage, registerFont } = require("canvas");
const path = require("path");
const axios = require("axios"); // Used axios instead of node-fetch for consistency
const { parse } = require("csv-parse");
const { ParquetReader } = require("parquets"); // This was in your package.json, ensure it's used or remove

// Initialize Firebase Admin SDK ONCE
if (!admin.apps.length) {
  try {
    admin.initializeApp();
    console.log("Firebase Admin SDK initialized.");
  } catch (e) {
    console.error("Firebase Admin SDK initialization error:", e);
  }
}

const db = admin.firestore();
// Use default bucket. If you have a specific one, use its full name: "YOUR_PROJECT_ID.appspot.com"
const bucket = admin.storage().bucket();
console.log(`Using GCS bucket: ${bucket.name}`);

// Nodemailer Transporter Initialization
let mailTransport;
try {
  const gmailEmail = functions.config().gmail?.email; // Optional chaining
  const gmailPassword = functions.config().gmail?.password; // Optional chaining

  if (gmailEmail && gmailPassword) {
    mailTransport = nodemailer.createTransport({
      service: "gmail",
      auth: {
        user: gmailEmail,
        pass: gmailPassword,
      },
    });
    console.log("Nodemailer transport configured for Gmail.");
  } else {
    console.error(
      "CRITICAL: Gmail email or password not set in Firebase Functions config (gmail.email, gmail.password). Email sending will fail."
    );
  }
} catch (error) {
  console.error("CRITICAL: Error initializing Nodemailer transport:", error);
}

// Register Font
try {
    // Ensure Impact.ttf is in the root of your 'functions' directory alongside index.js
    registerFont(path.join(__dirname, "Impact.ttf"), { family: "Impact" });
    console.log("Font Impact.ttf registered.");
} catch(fontError) {
    console.error("CRITICAL: Failed to register font Impact.ttf. Check path and if file is included in deployment.", fontError);
}

function normalizeItemName(name) {
  if (!name || typeof name !== 'string') return '';
  return name.toLowerCase().replace(/\s+/g, ' ').trim();
}

function getRecentPriceCatcherCSVFilePaths(monthsBack = 0) {
    const paths = [];
    const today = new Date();
    const basePath = "price_data_csv/pricecatcher_";

    for (let i = 0; i <= monthsBack; i++) {
        const targetDate = new Date(today.getFullYear(), today.getMonth() - i, 1);
        const year = targetDate.getFullYear();
        const month = (targetDate.getMonth() + 1).toString().padStart(2, '0');
        paths.push(`${basePath}${year}-${month}.csv`); // Corrected syntax
    }
    console.log(`Generated PriceCatcher CSV GCS paths: ${paths.join(', ')}`);
    return paths;
}

// --- sendEmailWithPdf Function (v2 style) ---
exports.sendEmailWithPdf = onRequest(
  {
    cors: ["https://kita-tongtong-8cda4.web.app", "http://localhost:5000"], // Specify your web app's origin(s)
    memory: "256MiB",
    timeoutSeconds: 60,
    region: "us-central1",
  },
  async (req, res) => {
  console.log("Forcing redeploy with this new log for sendEmailWithPdf - v1.1");
    if (req.method !== "POST") {
      console.warn("sendEmailWithPdf: Method Not Allowed:", req.method);
      return res.status(405).send({ error: "Method Not Allowed" });
    }

    if (!mailTransport) {
      console.error("sendEmailWithPdf: Nodemailer mailTransport not initialized. Check Firebase Function config.");
      return res.status(500).send({ success: false, message: "Email service not configured on server." });
    }

    const { name, recipientEmail, pdfBase64, fileName } = req.body;

    if (!name || !recipientEmail || !pdfBase64 || !fileName) {
      console.warn("sendEmailWithPdf: Missing required fields in request body.");
      return res.status(400).send({ error: "Missing fields: name, recipientEmail, pdfBase64, fileName" });
    }

    const senderEmailFromConfig = functions.config().gmail?.email;
    if (!senderEmailFromConfig) {
        console.error("sendEmailWithPdf: Sender email (gmail.email) not configured in Firebase Functions.");
        return res.status(500).send({ success: false, message: "Server sender email not configured." });
    }

    const mailOptions = {
      from: `"Kita Tongtong Support" <${senderEmailFromConfig}>`,
      to: recipientEmail,
      subject: "Your Tax Exemption Receipt - Kita Tongtong Donation",
      html: `<p>Hi ${name},</p><p>Thank you for your generous donation...</p><p>Sincerely,<br>The Kita Tongtong Team</p>`,
      attachments: [{
        filename: fileName,
        content: pdfBase64,
        encoding: "base64",
        contentType: "application/pdf",
      }],
    };

    try {
      console.log(`sendEmailWithPdf: Attempting to send email to ${recipientEmail}...`);
      await mailTransport.sendMail(mailOptions);
      console.log(`sendEmailWithPdf: Email sent successfully to ${recipientEmail}`);
      return res.status(200).send({ success: true, message: "Email sent successfully." });
    } catch (error) {
      console.error("sendEmailWithPdf: Nodemailer failed to send email:", error);
      return res.status(500).send({ success: false, message: "Server error while sending email.", errorDetails: error.message });
    }
  }
);


// --- generateVoucherImage Function (Corrected and using v2 style) ---
exports.generateVoucherImage = onRequest(
  {
    cors: ["https://kita-tongtong-8cda4.web.app", "http://localhost:5000"], // Add allowed origins
    memory: "1GiB", // Image processing can be memory intensive
    timeoutSeconds: 120
  },
  async (req, res) => {
    try {
      const { points, value } = req.body;
      if (!points || !value) {
        return res.status(400).send("Missing parameters: points and value are required.");
      }

      const templatePath = "voucherTemplates/pointsVoucherTemplate.png";
      const outputPath = `voucherBanner/${points}_points_RM${value}.png`;

      const templateFile = bucket.file(templatePath); // Uses defaultBucket
      const [templateBuffer] = await templateFile.download();
      const templateImage = await loadImage(templateBuffer);

      const canvas = createCanvas(templateImage.width, templateImage.height);
      const ctx = canvas.getContext("2d");
      const centerX = canvas.width / 2;
      const centerY = canvas.height / 2;
      const lineSpacing = 110;

      ctx.drawImage(templateImage, 0, 0);
      ctx.textAlign = "center";
      ctx.font = "bold 100px Arial"; // Consider if Arial is available or use registered Impact
      ctx.fillStyle = "#ffffff";
      ctx.fillText("Cash Voucher", centerX, centerY - lineSpacing * 2.2);
      ctx.font = "bold 200px Impact"; // Using registered font
      ctx.fillStyle = "#c1ff72";
      ctx.fillText(`RM${value}`, centerX, centerY - lineSpacing * 0.6);
      ctx.font = "bold 100px Arial";
      ctx.fillStyle = "#ffffff";
      ctx.fillText("with", centerX, centerY + lineSpacing * 0.6);
      ctx.fillText(`${points} points`, centerX, centerY + lineSpacing * 1.7);

      const buffer = canvas.toBuffer("image/png");
      const newFile = bucket.file(outputPath); // Uses defaultBucket

      // Overwrite if exists (simplified from your original)
      await newFile.save(buffer, { contentType: "image/png", metadata: { cacheControl: 'public, max-age=300' } }); // Added cache control
      console.log(`✅ New voucher image saved: ${outputPath}`);

      const encodedPath = encodeURIComponent(newFile.name);
      const publicUrl = `https://firebasestorage.googleapis.com/v0/b/${bucket.name}/o/${encodedPath}?alt=media`;
      return res.status(200).json({ image_url: publicUrl });

    } catch (error) {
      console.error("🔥 ERROR generating voucher image:", error);
      return res.status(500).send("Error generating voucher image: " + error.message);
    }
  }
);

// --- generatePackageKasihImage Function (Corrected and using v2 style) ---
exports.generatePackageKasihImage = onRequest(
  {
    cors: ["https://kita-tongtong-8cda4.web.app", "http://localhost:5000"],
    memory: "1GiB",
    timeoutSeconds: 180
  },
  async (req, res) => {
    try {
      const { items } = req.body;
      if (!items || !Array.isArray(items) || items.length === 0) {
        return res.status(400).send("Missing or invalid items array.");
      }

      const serperConfig = functions.config().serper; // Get serper config group
      const serperKey = serperConfig ? serperConfig.key : null; // Get the key
      if (!serperKey) {
        console.error("CRITICAL: Serper API key (serper.key) not configured in Firebase Functions.");
        return res.status(500).send("Image search service not configured.");
      }

      const canvas = createCanvas(1024, 768);
      const ctx = canvas.getContext("2d");
      ctx.fillStyle = "#FFF4D4";
      ctx.fillRect(0, 0, 1024, 768);

      const totalItems = items.length;
      const itemsPerRow = 3;
      const imageSize = 200;
      const padding = 40;
      const textOffsetY = 25; // For item name below image
      const itemBoxHeight = imageSize + textOffsetY + 10; // image + text + small margin

      const rows = Math.ceil(totalItems / itemsPerRow);
      const totalContentHeight = rows * itemBoxHeight + (rows > 0 ? (rows - 1) * padding : 0);
      const globalOffsetY = (canvas.height - totalContentHeight) / 2;


      for (let i = 0; i < totalItems; i++) {
        const item = items[i];
        const query = item.name;
        if (!query || typeof query !== 'string') {
            console.warn("Skipping item with invalid name:", item);
            continue;
        }
        const safeName = query.toLowerCase().replace(/\s+/g, "_").replace(/[^a-z0-9_]/gi, ''); // Sanitize further
        const imageFilePath = `packageItemsImageBank/${safeName}.jpg`;
        const imageFile = bucket.file(imageFilePath); // Uses defaultBucket

        const row = Math.floor(i / itemsPerRow);
        const col = i % itemsPerRow;

        const itemsInThisRow = Math.min(itemsPerRow, totalItems - (row * itemsPerRow));
        const rowWidth = itemsInThisRow * imageSize + (itemsInThisRow > 0 ? (itemsInThisRow - 1) * padding : 0);
        const globalOffsetX = (canvas.width - rowWidth) / 2;

        const x = globalOffsetX + col * (imageSize + padding);
        const y = globalOffsetY + row * (itemBoxHeight + padding);

        let img = null;
        const [exists] = await imageFile.exists();
        if (exists) {
          try {
            const [buffer] = await imageFile.download();
            img = await loadImage(buffer);
            console.log(`Reused image from GCS for: ${query}`);
          } catch (downloadError) {
            console.error(`Error downloading existing image ${imageFilePath} for ${query}:`, downloadError);
          }
        }

        if (!img) {
          console.log(`Image not in GCS or failed to load for ${query}, querying Serper...`);
          try {
            const serperRes = await axios.post("https://google.serper.dev/images",
              { q: query },
              { headers: { "X-API-KEY": serperKey, "Content-Type": "application/json" } }
            );
            const imageUrl = serperRes.data.images?.[0]?.imageUrl;
            console.log(`Queried Serper for: ${query} -> ${imageUrl || 'No image found'}`);
            if (imageUrl) {
              const imgRes = await axios.get(imageUrl, { responseType: 'arraybuffer' });
              const buffer = Buffer.from(imgRes.data, 'binary');
              img = await loadImage(buffer);
              await imageFile.save(buffer, { contentType: "image/jpeg" }); // Save for future reuse
              console.log(`Fetched and saved image from Serper for: ${query}`);
            }
          } catch (serperError) {
            console.error(`Error fetching image from Serper for ${query}:`, serperError.message);
            if (serperError.response) console.error("Serper Response:", serperError.response.data);
          }
        }

        if (img) {
          const aspect = img.width / img.height;
          let sx = 0, sy = 0, sWidth = img.width, sHeight = img.height;
          if (aspect > 1) { // Wider than tall
            sWidth = img.height; // Crop width to match height (make it square source)
            sx = (img.width - sWidth) / 2;
          } else { // Taller than wide, or square
            sHeight = img.width; // Crop height to match width
            sy = (img.height - sHeight) / 2;
          }
          ctx.drawImage(img, sx, sy, sWidth, sHeight, x, y, imageSize, imageSize);
          ctx.fillStyle = "#333333"; // Darker text
          ctx.font = "20px Arial"; // Consider Impact if you want consistency with voucher
          ctx.textAlign = "center";
          ctx.fillText(query, x + imageSize / 2, y + imageSize + textOffsetY);
        } else {
          ctx.fillStyle = "#cccccc";
          ctx.fillRect(x, y, imageSize, imageSize);
          ctx.fillStyle = "#555555";
          ctx.font = "16px Arial";
          ctx.textAlign = "center";
          ctx.fillText("Image N/A", x + imageSize/2, y + imageSize/2 + 8);
           ctx.fillStyle = "#333333";
          ctx.fillText(query, x + imageSize / 2, y + imageSize + textOffsetY);
        }
      }

      const finalBuffer = canvas.toBuffer("image/png");
      const outputPath = `package_kasih_banner/packageKasih_${Date.now()}.png`;
      const file = bucket.file(outputPath); // Uses defaultBucket
      await file.save(finalBuffer, { contentType: "image/png", metadata: { cacheControl: 'public, max-age=300'} });
      console.log(`✅ Package Kasih image saved: ${outputPath}`);

      const encodedPath = encodeURIComponent(file.name);
      const publicUrl = `https://firebasestorage.googleapis.com/v0/b/${bucket.name}/o/${encodedPath}?alt=media`;
      return res.status(200).json({ image_url: publicUrl });

    } catch (err) {
      console.error("🔥 ERROR generating package kasih image:", err);
      return res.status(500).send("Failed to generate image: " + err.message);
    }
  }
);

// --- pushOnNotification (Firestore Trigger v2) ---
exports.pushOnNotification = onDocumentCreated(
  { document: "notifications/{notifId}", region: "us-central1" }, // Example options
  async (event) => {
    console.log("pushOnNotification v2 triggered for notifId:", event.params.notifId);
    const snapshot = event.data;
    if (!snapshot) {
      console.log("No data associated with the event");
      return;
    }
    const notifData = snapshot.data();

    const text = notifData.message || `Asnaf ${notifData.applicantName} applied (${notifData.applicationCode})`;
    const role = notifData.recipientRole;
    console.log(`Notification for role: ${role}, message: ${text}`);

    if (!role) {
        console.log("No recipientRole specified in notification data. Aborting.");
        return;
    }

    const usersSnap = await db.collection('users').where('role','==',role).get();
    const tokens = [];
    for (const userDoc of usersSnap.docs) {
      const tokensSnap = await userDoc.ref.collection('fcmTokens').get();
      tokensSnap.forEach(tokenDoc => tokens.push(tokenDoc.id));
    }

    if (!tokens.length) {
        console.log(`No FCM tokens found for role: ${role}.`);
        return;
    }
    console.log(`Found ${tokens.length} tokens for role ${role}. Tokens:`, tokens.join(", "));


    const payload = {
      notification: {
        title: 'Kita Tongtong',
        body: text
      },
      data: {
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
        // You can add more custom data here if your app needs it
        // e.g., 'screen': '/specificPage', 'id': event.params.notifId
      }
    };

    // Batch send, FCM sendToDevice limit is 1000 tokens per call, though 500 is often used as a safe batch size
    const batchSize = 500;
    const batchedTokens = [];
    for (let i = 0; i < tokens.length; i += batchSize) {
        batchedTokens.push(tokens.slice(i, i + Math.min(batchSize, tokens.length - i)));
    }

    for (const tokenBatch of batchedTokens) {
        if (tokenBatch.length > 0) {
            try {
                console.log(`Sending FCM message to batch of ${tokenBatch.length} tokens.`);
                const response = await admin.messaging().sendToDevice(tokenBatch, payload);
                console.log("Successfully sent message to batch:", response.successCount, "successes,", response.failureCount, "failures.");
                response.results.forEach((result, index) => {
                    if (result.error) {
                        console.error(`Failed to send to token ${tokenBatch[index]}:`, result.error);
                    }
                });
            } catch (error) {
                console.error("Error sending FCM message batch:", error);
            }
        }
    }
  }
);

// --- updatePriceDataScheduled (Scheduled Function v2) ---
exports.updatePriceDataScheduled = onSchedule(
  {
    schedule: 'every 24 hours',
    timeoutSeconds: 540,
    memory: '1GiB',
    retryConfig: { retryCount: 1 },
    region: 'us-central1' // Specify region
  },
  async (event) => {
    console.log(`[updatePriceDataScheduled v2.CSV] Starting. Triggered at: ${event.scheduleTime || new Date().toISOString()}`);
    // ... (your existing logic for updatePriceDataScheduled, ensure it's robust) ...
    // Make sure to fix the getRecentPriceCatcherCSVFilePaths paths.push line
    // Make sure it uses the defaultBucket or a correctly specified bucket.
    // Make sure all error handling is robust.
    const ITEM_LOOKUP_CSV_PATH_IN_BUCKET = "price_data_csv/lookup_item.csv";
    const productsCollection = db.collection('products_market_price');
    const itemLookupData = new Map();

    try {
      console.log(`Fetching item lookup CSV from gs://${bucket.name}/${ITEM_LOOKUP_CSV_PATH_IN_BUCKET}`);
      const itemLookupFile = bucket.file(ITEM_LOOKUP_CSV_PATH_IN_BUCKET);
      const [itemLookupFileExists] = await itemLookupFile.exists();
      if (!itemLookupFileExists) {
        console.error(`CRITICAL: Lookup CSV file ${ITEM_LOOKUP_CSV_PATH_IN_BUCKET} does not exist. Aborting.`);
        return null;
      }
      const [itemLookupFileContents] = await itemLookupFile.download();
      const itemLookupCsvString = itemLookupFileContents.toString('utf-8');
      console.log(`Fetched lookup_item.csv. Size: ${itemLookupCsvString.length} chars.`);

      const lookupParser = parse(itemLookupCsvString, { columns: true, skip_empty_lines: true, trim: true, bom: true });
      for await (const record of lookupParser) {
        const itemCode = record.item_code?.toString().trim();
        const itemName = record.item?.toString().trim();
        if (itemCode && itemName) {
          itemLookupData.set(itemCode, {
            name: itemName,
            unit: (record.unit || 'N/A').trim(),
            group: (record.item_group || 'N/A').trim(),
            category: (record.item_category || 'N/A').trim(),
          });
        }
      }
      console.log(`Processed ${itemLookupData.size} items from lookup CSV.`);
      if (itemLookupData.size === 0) {
        console.error("Item lookup data is empty. Aborting.");
        return null;
      }

      const priceFilePaths = getRecentPriceCatcherCSVFilePaths(0); // Current month
      const aggregatedPrices = new Map();
      for (const priceFilePath of priceFilePaths) {
        console.log(`Processing price CSV: gs://${bucket.name}/${priceFilePath}`);
        const priceFile = bucket.file(priceFilePath);
        const [priceFileExists] = await priceFile.exists();
        if (!priceFileExists) {
          console.warn(`Price CSV ${priceFilePath} not found. Skipping.`);
          continue;
        }
        const [priceFileContents] = await priceFile.download();
        const priceCsvString = priceFileContents.toString('utf-8');
        const priceParser = parse(priceCsvString, { columns: true, skip_empty_lines: true, trim: true, bom: true });
        for await (const record of priceParser) {
          const itemCodeStr = record.item_code?.toString().trim();
          const priceVal = record.price;
          const price = parseFloat(priceVal);
          if (itemCodeStr && !isNaN(price) && itemLookupData.has(itemCodeStr)) {
            const itemDetails = itemLookupData.get(itemCodeStr);
            if (!aggregatedPrices.has(itemCodeStr)) {
              aggregatedPrices.set(itemCodeStr, {
                sum_price: 0, count: 0, name: itemDetails.name, unit: itemDetails.unit,
                group: itemDetails.group, category: itemDetails.category,
              });
            }
            const currentAgg = aggregatedPrices.get(itemCodeStr);
            currentAgg.sum_price += price;
            currentAgg.count += 1;
          }
        }
      }
      console.log(`Aggregated prices for ${aggregatedPrices.size} distinct items.`);

      if (aggregatedPrices.size === 0) {
        console.log('No price data to update in Firestore.');
        return null;
      }

      const batchCommits = [];
      let currentBatch = db.batch();
      let itemsInCurrentBatch = 0;
      aggregatedPrices.forEach((data, itemCode) => {
        const averagePrice = data.count > 0 ? data.sum_price / data.count : 0;
        const normalizedName = normalizeItemName(data.name);
        const productRef = productsCollection.doc(itemCode);
        currentBatch.set(productRef, {
          item_code: itemCode, item_name: data.name, normalized_item_name: normalizedName,
          average_price: parseFloat(averagePrice.toFixed(2)), unit: data.unit,
          item_group: data.group, item_category: data.category,
          price_samples_count: data.count, last_updated: admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });
        itemsInCurrentBatch++;
        if (itemsInCurrentBatch >= 490) {
          batchCommits.push(currentBatch.commit());
          currentBatch = db.batch();
          itemsInCurrentBatch = 0;
        }
      });
      if (itemsInCurrentBatch > 0) batchCommits.push(currentBatch.commit());
      if (batchCommits.length > 0) await Promise.all(batchCommits);
      console.log(`Successfully committed ${batchCommits.length} batch(es) to Firestore.`);
      console.log('PriceCatcher CSV data update completed.');
      return null;

    } catch (error) {
      console.error('CRITICAL ERROR in updatePriceDataScheduled:', error.message, error.stack);
      throw error;
    }
  }
);


// --- getPackagePrice Function (Corrected and using v2 style) ---
exports.getPackagePrice = onRequest(
  {
    cors: ["https://kita-tongtong-8cda4.web.app", "http://localhost:5000"],
    memory: "256MiB"
  },
  async (req, res) => {
    try {
      const itemsFromBody = req.body.items;
      if (!Array.isArray(itemsFromBody) || itemsFromBody.length === 0) {
        return res.status(400).json({ error: "items must be a non-empty array" });
      }

      let expectedTotal = 0.0;
      const itemPricePromises = itemsFromBody.map(async (item) => {
        if (!item.name || typeof item.name !== 'string' || !item.number || typeof item.number !== 'number') {
          console.warn('Skipping invalid item structure in getPackagePrice:', item);
          return 0;
        }
        const searchName = normalizeItemName(item.name);
        if (!searchName) {
          console.warn(`Skipping item with empty normalized name: ${item.name}`);
          return 0;
        }

        // Corrected console log
        console.log(`getPackagePrice: Searching for: "${item.name}" (Normalized to: "${searchName}")`);

        const productQuerySnapshot = await db.collection('products_market_price')
                                       .where('normalized_item_name', '==', searchName)
                                       .limit(1)
                                       .get();
        if (productQuerySnapshot.empty) {
          console.warn(`Price not found in DB for item: "${item.name}"`);
          return 0;
        }
        const productData = productQuerySnapshot.docs[0].data();
        const unitPrice = parseFloat(productData.average_price);
        if (isNaN(unitPrice)) {
          console.warn(`Invalid price in DB for "${item.name}": ${productData.average_price}`);
          return 0;
        }
        return unitPrice * Number(item.number);
      });

      const individualTotals = await Promise.all(itemPricePromises);
      expectedTotal = individualTotals.reduce((sum, current) => sum + current, 0);

      return res.status(200).json({ expectedTotal: parseFloat(expectedTotal.toFixed(2)) });

    } catch (err) {
      console.error("Error in getPackagePrice:", err.message, err.stack);
      return res.status(500).json({ error: "Internal server error in getPackagePrice" });
    }
  }
);