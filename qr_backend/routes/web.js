const express = require('express');
const router = express.Router();

/**
 * GET /pet/:qr_id
 * Web fallback for scanning QR codes
 */
router.get('/:qr_id', async (req, res) => {
    try {
        const qrId = req.params.qr_id;
        const petRef = req.db.collection('qrcodes').doc(qrId);
        const doc = await petRef.get();

        // If QR doesn't exist at all, you might want a 404 page
        if (!doc.exists) {
            return res.status(404).render('404', { message: 'QR Code not recognized.' });
        }

        const data = doc.data();

        // Check if pet is UNREGISTERED
        if (!data.is_registered) {
            // Render the page telling them to download the app to register
            return res.render('unregistered', { qr_id: qrId });
        }

        // If pet IS REGISTERED
        return res.render('profile', { 
            qr_id: qrId, 
            pet: data.pet_data, 
            owner: data.owner_data 
        });

    } catch (error) {
        console.error('Error rendering web profile:', error);
        res.status(500).send('<h1>Server Error</h1><p>We encountered an error processing your request.</p>');
    }
});

/**
 * POST /pet/:qr_id/register
 * Handles form submission from unregistered.ejs
 */
router.post('/:qr_id/register', async (req, res) => {
    try {
        const qrId = req.params.qr_id;
        const { petName, breed, age, color, ownerName, ownerPhone, ownerEmail } = req.body;

        const petRef = req.db.collection('qrcodes').doc(qrId);
        const doc = await petRef.get();

        if (!doc.exists) {
            return res.status(404).send('<h1>Error</h1><p>QR Code not found.</p>');
        }

        if (doc.data().is_registered) {
            return res.status(400).send('<h1>Error</h1><p>This QR Code is already registered.</p>');
        }

        // Format data to match pet_data and owner_data structures
        const petData = {
            id: qrId,
            name: petName,
            breed: breed || '',
            age: parseInt(age) || 0,
            color: color || '',
            specialMarks: '',
            photoUrl: '', // Could be updated later via app
            createdAt: new Date()
        };

        const ownerData = {
            name: ownerName,
            phone: ownerPhone,
            email: ownerEmail || ''
        };

        // Update document
        await petRef.update({
            is_registered: true,
            pet_data: petData,
            owner_data: ownerData,
            registered_at: require('firebase-admin').firestore.FieldValue.serverTimestamp()
        });

        // Redirect to profile page after successful registration
        res.redirect(`/pet/${qrId}`);
    } catch (error) {
        console.error('Error registering pet from web:', error);
        res.status(500).send('<h1>Server Error</h1><p>Failed to register pet. Please try again later.</p>');
    }
});

module.exports = router;
