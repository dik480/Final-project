const QRCode = require('qrcode');
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const admin = require('firebase-admin');
const serviceAccount = require("./pawtner-firebase-key.json");

admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

const DOMAIN = 'https://pawtner.app';
const outputDir = path.join(__dirname, 'output_qrs');

// Ensure output directory exists
if (!fs.existsSync(outputDir)) {
    fs.mkdirSync(outputDir);
}

/**
 * Generate a new unique unassigned QR tag
 */
async function generateNewTag() {
    try {
        // 1. Generate unique 8-char ID
        const qrId = crypto.randomBytes(4).toString('hex');
        const urlToEncode = `${DOMAIN}/pet/${qrId}`;

        console.log(`Generating new tag: ${qrId}`);
        console.log(`URL to encode: ${urlToEncode}`);

        // 2. Save "unregistered" record to database
        if (db) {
            await db.collection('qrcodes').doc(qrId).set({
                is_registered: false,
                pet_data: null,
                owner_data: null,
                created_at: admin.firestore.FieldValue.serverTimestamp()
            });
            console.log(`Saved empty record for ${qrId} to Firestore.`);
        }

        // 3. Generate QR code image
        const outputPath = path.join(outputDir, `${qrId}.png`);
        await QRCode.toFile(outputPath, urlToEncode, {
            color: {
                dark: '#0f172a',  // Dark blue/black points
                light: '#ffffff' // White background
            },
            width: 500,
            margin: 2
        });

        console.log(`✅ Success! QR code saved to ${outputPath}`);

    } catch (error) {
        console.error('Failed to generate tag:', error);
    }
}

// Check args to see if we want to run multiple
const count = parseInt(process.argv[2]) || 1;
console.log(`Generating ${count} QR code(s)...`);

(async () => {
    for (let i = 0; i < count; i++) {
        await generateNewTag();
    }
    process.exit(0);
})();
