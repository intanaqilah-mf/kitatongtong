const admin = require('firebase-admin');
const createCsvWriter = require('csv-writer').createObjectCsvWriter;
const fs = require('fs');

// --- IMPORTANT ---
// Place the 'service-account-key.json' file you downloaded in the same folder as this script
const serviceAccount = require('./serviceAccountKey.json');

// --- CONFIGURATION ---
// Create an 'exports' directory if it doesn't exist
const exportDir = 'exports';
if (!fs.existsSync(exportDir)){
    fs.mkdirSync(exportDir);
}

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

// Helper function to handle different data types for CSV export
function formatData(data) {
    if (data instanceof admin.firestore.Timestamp) {
        // Convert Firestore Timestamps to a readable date string
        return data.toDate().toISOString();
    }
    if (typeof data === 'object' && data !== null) {
        // Convert nested objects/arrays to a JSON string so they fit in one cell
        return JSON.stringify(data);
    }
    // Return other data types as is
    return data;
}

async function exportAllCollections() {
  console.log('Starting export of all collections...');

  try {
    // 1. Get all root-level collections
    const collections = await db.listCollections();

    if (collections.length === 0) {
        console.log("No collections found in the database.");
        return;
    }

    // 2. Loop through each collection
    for (const collectionRef of collections) {
      const collectionId = collectionRef.id;
      console.log(`\nProcessing collection: '${collectionId}'...`);

      const documentsSnapshot = await collectionRef.get();
      if (documentsSnapshot.empty) {
        console.log(`- Collection '${collectionId}' is empty. Skipping.`);
        continue;
      }

      const records = [];
      const headers = new Set(); // Use a Set to automatically handle unique headers

      // 3. Prepare data and gather all possible headers
      documentsSnapshot.forEach(doc => {
        const docData = doc.data();
        const record = { id: doc.id }; // Add the document ID as the first column

        for (const key in docData) {
          headers.add(key); // Add every field key to the headers
          record[key] = formatData(docData[key]);
        }
        records.push(record);
      });

      // 4. Define CSV writer for the current collection
      const csvHeaders = [{ id: 'id', title: 'Document ID' }, ...Array.from(headers).map(h => ({ id: h, title: h }))];
      const csvPath = `${exportDir}/export_${collectionId}.csv`;

      const csvWriter = createCsvWriter({
        path: csvPath,
        header: csvHeaders
      });

      // 5. Write records to the collection's CSV file
      await csvWriter.writeRecords(records);
      console.log(`✅ Successfully exported ${records.length} documents from '${collectionId}' to ${csvPath}`);
    }

    console.log('\nAll collections have been exported.');

  } catch (error) {
    console.error('❌ An error occurred during the export process:', error);
  }
}

// Run the export function
exportAllCollections();
