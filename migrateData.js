const admin = require("firebase-admin");
const fs = require("fs");

// Initialize Firebase Admin SDK
const serviceAccount = require("./serviceAccountKey.json"); // Ensure the file is in the same folder

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

async function migrateAsnafInfo() {
  console.log("Starting migration...");

  const asnafCollection = await db.collection("asnafInfo").get();

  for (let doc of asnafCollection.docs) {
    const asnafData = doc.data();
    const userId = doc.id; // Use the same user ID from asnafInfo

    // Merge asnafInfo data into users collection
    await db.collection("users").doc(userId).set(
      {
        name: asnafData.name || "",
        nric: asnafData.nric || "",
        phone: asnafData.phone || "",
        address: asnafData.address || "",
        city: asnafData.city || "",
        postcode: asnafData.postcode || "",
        photoUrl: asnafData.photoUrl || "",
      },
      { merge: true } // Ensures existing user fields remain unchanged
    );

    console.log(`✅ Migrated asnafInfo for user: ${userId}`);
  }

  console.log("🎉 Migration completed successfully!");
}

// Run the migration function
migrateAsnafInfo().catch((error) => {
  console.error("❌ Migration failed:", error);
});
