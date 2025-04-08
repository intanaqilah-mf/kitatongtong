const admin = require("firebase-admin");
const { Storage } = require("@google-cloud/storage");

const serviceAccount = require("./serviceAccountKey.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});
const db = admin.firestore();
const storage = new Storage({ credentials: serviceAccount });
const bucket = storage.bucket("kita-tongtong.firebasestorage.app");

const mappings = [
  { folder: "event_banners/", collection: "events", field: "bannerUrl" },
  { folder: "packageItemsImageBank/", collection: "package_kasih", field: "bannerUrl" },
  { folder: "package_kasih_banner/", collection: "package_kasih", field: "bannerUrl" },
  { folder: "profile_pictures/", collection: "users", field: "photoUrl" },
  { folder: "voucherBanner/", collection: "vouchers", field: "bannerVoucher" }
 // { folder: "voucherTemplates/", collection: "voucher_templates", field: "imageUrl" }
];

async function runUpdate() {
  for (const map of mappings) {
    const { folder, collection, field } = map;
    const [files] = await bucket.getFiles({ prefix: folder });

    console.log(`📂 Processing folder: ${folder}`);

    for (const file of files) {
      const filePath = file.name;
      const encodedPath = encodeURIComponent(filePath);
      const publicUrl = `https://firebasestorage.googleapis.com/v0/b/kita-tongtong.firebasestorage.app/o/${encodedPath}?alt=media`;

      const snapshot = await db.collection(collection).get();

      for (const doc of snapshot.docs) {
        const data = doc.data();
        const currentUrl = data[field];

        if (typeof currentUrl === "string" && currentUrl.includes(filePath)) {
          await doc.ref.update({ [field]: publicUrl });
          console.log(`✅ Updated ${collection}/${doc.id} (${field})`);
        }
      }
    }
  }

  console.log("🔥 DONE. All URLs updated.");
}

runUpdate().catch(console.error);
