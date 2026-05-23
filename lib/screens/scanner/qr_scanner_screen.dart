import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'scanned_pet_info_screen.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  MobileScannerController cameraController = MobileScannerController();
  bool _isProcessing = false;

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? code = barcodes.first.rawValue;
    if (code == null || !code.startsWith('PAWTNER:')) return;

    setState(() => _isProcessing = true);

    try {
      final petId = code.substring(8); // Remove 'PAWTNER:' prefix

      // Get pet details
      final petDoc =
          await FirebaseFirestore.instance.collection('pets').doc(petId).get();

      if (!petDoc.exists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pet not found')),
          );
        }
        setState(() => _isProcessing = false);
        return;
      }

      // Get current location
      Position? position;
      String address = 'Location unavailable';

      try {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }

        if (permission != LocationPermission.denied &&
            permission != LocationPermission.deniedForever) {
          position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
            timeLimit: const Duration(seconds: 5),
          );

          try {
            List<Placemark> placemarks = await placemarkFromCoordinates(
              position.latitude,
              position.longitude,
            );

            if (placemarks.isNotEmpty) {
              final place = placemarks.first;
              address = '${place.street}, ${place.locality}, ${place.country}';
            }
          } catch (e) {
            // Geocoding error
          }
        }
      } catch (e) {
        // Location error
      }

      final mapsUrl = position != null 
          ? 'https://www.google.com/maps/search/?api=1&query=${position.latitude},${position.longitude}'
          : null;

      // Record scan
      final currentUser = FirebaseAuth.instance.currentUser;
      String scannedBy = currentUser?.displayName ?? currentUser?.email ?? 'Anonymous';
      
      // Get finder's phone from their profile if available
      String? finderPhone;
      if (currentUser != null) {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();
        if (userDoc.exists) {
          finderPhone = userDoc.data()?['phone'];
        }
      }

      final scanRef = await FirebaseFirestore.instance.collection('scans').add({
        'petId': petId,
        'scannedBy': scannedBy,
        'finderId': currentUser?.uid,
        'latitude': position?.latitude ?? 0.0,
        'longitude': position?.longitude ?? 0.0,
        'address': address,
        'scannedAt': FieldValue.serverTimestamp(),
      });

      final String trackingId = 'track_${DateTime.now().millisecondsSinceEpoch}';

      // Notify owner
      final notificationRef = await FirebaseFirestore.instance.collection('notifications').add({
        'owner_id': petDoc.data()?['ownerId'],
        'title': 'Pet Found!',
        'body': 'Your pet ${petDoc.data()?['name']} has been scanned at $address.${mapsUrl != null ? "\n\nMap Link: $mapsUrl" : ""}',
        'timestamp': DateTime.now().toIso8601String(),
        'location': {
          'lat': position?.latitude,
          'lng': position?.longitude,
        },
        'status': 'active',
        'petId': petId,
        'scanId': scanRef.id,
        'trackingId': trackingId,
        'finder_name': scannedBy,
        'finder_phone': finderPhone,
        'finder_id': currentUser?.uid,
      });

      // Navigate to pet info screen
      if (mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ScannedPetInfoScreen(
              petId: petId,
              scanLocation: address,
              latitude: position?.latitude,
              longitude: position?.longitude,
              notificationId: notificationRef.id,
              trackingId: trackingId,
              finderPhone: finderPhone,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'Scan QR Code',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.flash_off, color: Colors.white),
                      onPressed: () => cameraController.toggleTorch(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: const Icon(Icons.cameraswitch, color: Colors.white),
                      onPressed: () => cameraController.switchCamera(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                MobileScanner(
                  controller: cameraController,
                  onDetect: _onDetect,
                ),
                if (_isProcessing)
                  Container(
                    color: Colors.black54,
                    child: const Center(
                      child: CircularProgressIndicator(color: Color(0xFFFF6B35)),
                    ),
                  ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(32),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 20,
                          offset: const Offset(0, -10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF6B35).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.qr_code_scanner,
                            size: 40,
                            color: Color(0xFFFF6B35),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Scan Pet QR Code',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Position the QR code within the frame',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black54,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          ],
        ),
      ),
    );
  }
}