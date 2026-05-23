const express = require('express');
const router = express.Router();

/**
 * GET /api/pet/:qr_id
 * Returns registration status for a given QR ID.
 */
router.get('/pet/:qr_id', async (req, res) => {
    try {
        const qrId = req.params.qr_id;
        const petRef = req.db.collection('qrcodes').doc(qrId);
        const doc = await petRef.get();

        if (!doc.exists) {
            return res.status(404).json({ error: 'QR Code not found in database' });
        }

        const data = doc.data();
        res.json({
            qr_id: qrId,
            is_registered: data.is_registered || false,
            // Don't send full private info, just status and maybe basic pet data
            pet_data: data.pet_data || null
        });
    } catch (error) {
        console.error('Error fetching pet:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
});

/**
 * POST /api/register_pet
 * Attaches pet + owner data to a specific qr_id
 * Body: { qr_id: string, pet_data: object, owner_data: object }
 */
router.post('/register_pet', async (req, res) => {
    try {
        const { qr_id, pet_data, owner_data } = req.body;
        
        if (!qr_id || !pet_data || !owner_data) {
            return res.status(400).json({ error: 'Missing required fields' });
        }

        const petRef = req.db.collection('qrcodes').doc(qr_id);
        const doc = await petRef.get();

        if (!doc.exists) {
            return res.status(404).json({ error: 'Invalid QR Code' });
        }

        if (doc.data().is_registered) {
            return res.status(400).json({ error: 'QR Code is already registered to a pet' });
        }

        // Update document with pet and owner data, set registered to true
        await petRef.update({
            is_registered: true,
            pet_data: pet_data,
            owner_data: owner_data,
            registered_at: new Date().toISOString()
        });

        res.json({ success: true, message: 'Pet successfully registered to QR tag' });
    } catch (error) {
        console.error('Error registering pet:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
});

/**
 * POST /api/share-location
 * Sends finder location to owner
 * Body: { qr_id: string, lat: number, lng: number }
 */
router.post('/share-location', async (req, res) => {
    try {
        const { qr_id, lat, lng } = req.body;

        if (!qr_id || !lat || !lng) {
            return res.status(400).json({ error: 'Missing location data or qr_id' });
        }

        const petRef = req.db.collection('qrcodes').doc(qr_id);
        const doc = await petRef.get();

        if (!doc.exists || !doc.data().is_registered) {
            return res.status(404).json({ error: 'Pet profile not found' });
        }

        const ownerData = doc.data().owner_data;
        
        // In reality, here you would use Firebase Cloud Messaging, 
        // SendGrid (email), or Twilio (SMS) to notify the owner.
        // For demonstration, we just log it and potentially save to a "notifications" collection
        await req.db.collection('notifications').add({
            owner_id: ownerData.id || ownerData.email,
            title: 'Pet Location Shared!',
            body: `Someone just scanned your pet's tag at location ${lat}, ${lng}`,
            timestamp: new Date().toISOString(),
            location: { lat, lng }
        });

        console.log(`Sending GPS location (${lat}, ${lng}) to owner of animal on QR ${qr_id}...`);
        
        res.json({ success: true, message: 'Location securely shared with the pet owner' });
    } catch (error) {
        console.error('Error sharing location:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
});

module.exports = router;
