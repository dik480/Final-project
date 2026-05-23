import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../utils/custom_header.dart';

class PetTrackingScreen extends StatefulWidget {
  final String notificationId;
  final String? trackingId;
  const PetTrackingScreen(
      {super.key, required this.notificationId, this.trackingId});

  @override
  State<PetTrackingScreen> createState() => _PetTrackingScreenState();
}

class _PetTrackingScreenState extends State<PetTrackingScreen> {
  GoogleMapController? _mapController;

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  Future<void> _sendSMS(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'sms', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  void _updateCamera(double lat, double lng) {
    _mapController?.animateCamera(
      CameraUpdate.newLatLng(LatLng(lat, lng)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomHeaderScreen(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 16),
                const Text(
                  'Live Tracking',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection(
                      widget.trackingId != null ? 'tracking' : 'notifications')
                  .doc(widget.trackingId ?? widget.notificationId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(color: Colors.white));
                }

                if (snapshot.hasError ||
                    !snapshot.hasData ||
                    !snapshot.data!.exists) {
                  return const Center(
                      child: Text('Tracking session not found or ended.',
                          style: TextStyle(color: Colors.white)));
                }

                final data = snapshot.data!.data() as Map<String, dynamic>;

                // If we are listening to a tracking doc, we might still need some data from the notification doc
                // But for now, let's assume 'tracking' has what we need for location
                final location = data['location'] as Map<String, dynamic>?;
                final lat = location?['lat'] as double?;
                final lng = location?['lng'] as double?;
                final status = data['status'] ?? 'inactive';
                final title = data['petName'] ?? data['title'] ?? 'Pet Found';

                if (lat == null || lng == null) {
                  return const Center(
                      child: Text('Location data missing.',
                          style: TextStyle(color: Colors.white)));
                }

                final position = LatLng(lat, lng);

                // Schedule camera update after build
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _updateCamera(lat, lng);
                });

                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(32)),
                      child: GoogleMap(
                        onMapCreated: _onMapCreated,
                        initialCameraPosition:
                            CameraPosition(target: position, zoom: 16),
                        markers: {
                          Marker(
                            markerId: const MarkerId('pet_marker'),
                            position: position,
                            infoWindow: InfoWindow(title: title),
                            icon: BitmapDescriptor.defaultMarkerWithHue(
                                BitmapDescriptor.hueOrange),
                          ),
                        },
                      ),
                    ),
                    if (status == 'inactive')
                      Positioned(
                        top: 24,
                        left: 24,
                        right: 24,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5)),
                            ],
                          ),
                          child: const Text(
                            'Tracking offline. Showing last known location.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    Positioned(
                      bottom: 24,
                      left: 24,
                      right: 24,
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 10)),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Finder Location',
                              style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 20,
                                  color: Colors.black87),
                            ),
                            if (data['lastUpdate'] != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  'Last updated: ${DateFormat('h:mm:ss a').format((data['lastUpdate'] as Timestamp).toDate())}',
                                  style: const TextStyle(
                                      color: Colors.green,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            const Text(
                              'The finder is currently at this location. You can contact them below.',
                              textAlign: TextAlign.center,
                              style:
                                  TextStyle(color: Colors.black54, height: 1.4),
                            ),
                            const SizedBox(height: 24),
                            if (data['finder_phone'] != null)
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () =>
                                          _makePhoneCall(data['finder_phone']),
                                      icon: const Icon(Icons.phone),
                                      label: const Text('Call',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 16),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(16)),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () =>
                                          _sendSMS(data['finder_phone']),
                                      icon: const Icon(Icons.message),
                                      label: const Text('Message',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 16),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(16)),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            else
                              const Center(
                                child: Text(
                                  'No contact information provided by the finder.',
                                  style: TextStyle(
                                      color: Colors.black45,
                                      fontStyle: FontStyle.italic),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
