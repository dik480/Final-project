import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/pet_model.dart';
import '../../utils/custom_header.dart';

class ScannedPetInfoScreen extends StatefulWidget {
  final String petId;
  final String scanLocation;
  final double? latitude;
  final double? longitude;
  final String? notificationId;
  final String? trackingId;
  final String? finderPhone;

  const ScannedPetInfoScreen({
    super.key,
    required this.petId,
    required this.scanLocation,
    this.latitude,
    this.longitude,
    this.notificationId,
    this.trackingId,
    this.finderPhone,
  });

  @override
  State<ScannedPetInfoScreen> createState() => _ScannedPetInfoScreenState();
}

class _ScannedPetInfoScreenState extends State<ScannedPetInfoScreen> {
  StreamSubscription<Position>? _positionStreamSubscription;
  double? _currentLat;
  double? _currentLng;
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _currentLat = widget.latitude;
    _currentLng = widget.longitude;
  }

  Future<void> _startLiveTracking() async {
    if (widget.notificationId == null) return;
    if (_positionStreamSubscription != null) return; // Already tracking

    // Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Location services are disabled. Please enable them to share your location.')),
        );
      }
      return;
    }

    // Check permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Location permission is required to share live location.')),
        );
      }
      return;
    }

    try {
      // Fetch pet data to get the name
      final petDoc = await FirebaseFirestore.instance
          .collection('pets')
          .doc(widget.petId)
          .get();
      final petName = petDoc.exists ? (petDoc.data()?['name'] ?? 'Pet') : 'Pet';

      // Get initial position immediately
      Position? initialPosition;
      try {
        initialPosition = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
            timeLimit: const Duration(seconds: 5));
      } catch (e) {
        initialPosition = await Geolocator.getLastKnownPosition();
      }

      if (initialPosition == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Could not get current location. Please check your GPS and try again.')),
          );
        }
        return;
      }

      if (mounted) {
        setState(() {
          _currentLat = initialPosition!.latitude;
          _currentLng = initialPosition.longitude;
        });
      }

      // Update Tracking collection with initial position
      if (widget.trackingId != null) {
        await FirebaseFirestore.instance
            .collection('tracking')
            .doc(widget.trackingId)
            .set({
          'notificationId': widget.notificationId,
          'petId': widget.petId,
          'petName': petName,
          'finder_phone': widget.finderPhone,
          'location': {
            'lat': initialPosition.latitude,
            'lng': initialPosition.longitude,
          },
          'status': 'active',
          'lastUpdate': FieldValue.serverTimestamp(),
        });
      }

      // Update Notification with tracking info and initial position
      if (widget.notificationId != null) {
        await FirebaseFirestore.instance
            .collection('notifications')
            .doc(widget.notificationId)
            .update({
          'location': {
            'lat': initialPosition.latitude,
            'lng': initialPosition.longitude,
          },
          'status': 'active',
          'lastUpdate': FieldValue.serverTimestamp(),
        });
      }

      // Start the stream for continuous updates
      _positionStreamSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter:
              10, // Update only if moved 10 meters to avoid flooding
        ),
      ).listen((Position position) {
        if (mounted) {
          setState(() {
            _currentLat = position.latitude;
            _currentLng = position.longitude;
          });

          // Move camera to follow user
          _mapController?.animateCamera(
            CameraUpdate.newLatLng(
                LatLng(position.latitude, position.longitude)),
          );
        }

        // Update Tracking collection
        if (widget.trackingId != null) {
          debugPrint(
              'Uploading location to tracking/${widget.trackingId}: ${position.latitude}, ${position.longitude}');
          FirebaseFirestore.instance
              .collection('tracking')
              .doc(widget.trackingId)
              .set({
            'location': {
              'lat': position.latitude,
              'lng': position.longitude,
            },
            'status': 'active',
            'lastUpdate': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true)).catchError(
                  (e) => debugPrint('Firestore Error: $e'));
        }

        // Also update Notification (optional, but good for overview)
        if (widget.notificationId != null) {
          FirebaseFirestore.instance
              .collection('notifications')
              .doc(widget.notificationId)
              .set({
            'location': {
              'lat': position.latitude,
              'lng': position.longitude,
            },
            'status': 'active',
            'lastUpdate': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
      }, onError: (e) {
        debugPrint('Location Stream Error: $e');
        _stopLiveTracking();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Tracking stopped due to error: $e')),
          );
        }
      });

      setState(() {}); // Trigger rebuild to show sharing status
    } catch (e) {
      debugPrint('Error starting tracking: $e');
    }
  }

  void _shareLocationLink() {
    if (_currentLat != null && _currentLng != null) {
      final String mapUrl =
          'https://www.google.com/maps?q=$_currentLat,$_currentLng';
      
      final RenderBox? box = context.findRenderObject() as RenderBox?;
      
      Share.share(
        'I found a pet! You can track my live location here: $mapUrl',
        subject: 'Live Pet Location',
        sharePositionOrigin: box != null ? box.localToGlobal(Offset.zero) & box.size : null,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Location not available yet. Please wait a moment.')),
      );
    }
  }

  void _stopLiveTracking() {
    _positionStreamSubscription?.cancel();
    setState(() {
      _positionStreamSubscription = null;
    });

    if (widget.notificationId != null) {
      FirebaseFirestore.instance
          .collection('notifications')
          .doc(widget.notificationId)
          .update({'status': 'inactive'});
    }
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    // Mark tracking as inactive when the screen is closed
    if (widget.notificationId != null) {
      FirebaseFirestore.instance
          .collection('notifications')
          .doc(widget.notificationId)
          .update({'status': 'inactive'});
    }
    super.dispose();
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  Future<void> _sendEmail(String email) async {
    final Uri launchUri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {
        'subject': 'Found Your Pet!',
        'body': 'Hi, I found your pet at ${widget.scanLocation}',
      },
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomHeaderScreen(
      floatingActionButton: _positionStreamSubscription != null
          ? FloatingActionButton.extended(
              onPressed: _shareLocationLink,
              backgroundColor: Colors.blue,
              icon: const Icon(Icons.share, color: Colors.white),
              label: const Text('Share Live Link',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            )
          : null,
      child: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('pets')
            .doc(widget.petId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.white));
          }

          if (snapshot.hasError ||
              !snapshot.hasData ||
              !snapshot.data!.exists) {
            return const Center(
              child: Text('Pet information not found',
                  style: TextStyle(color: Colors.white, fontSize: 18)),
            );
          }

          final pet = PetModel.fromFirestore(snapshot.data!);

          return Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
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
                      'Pet Found!',
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
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check_circle,
                                size: 64,
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Great! You found ${pet.name}!',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'The owner has been notified. You can share your live location to help them find you faster.',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black54,
                                height: 1.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton.icon(
                                onPressed: _positionStreamSubscription == null
                                    ? _startLiveTracking
                                    : _stopLiveTracking,
                                icon: Icon(_positionStreamSubscription == null
                                    ? Icons.location_on
                                    : Icons.location_off),
                                label: Text(
                                    _positionStreamSubscription == null
                                        ? 'Share Live Location'
                                        : 'Stop Sharing',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      _positionStreamSubscription == null
                                          ? Colors.blue
                                          : Colors.red,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: OutlinedButton.icon(
                                onPressed: _shareLocationLink,
                                icon: const Icon(Icons.share),
                                label: const Text('Share Location Link',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold)),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.blue,
                                  side: const BorderSide(
                                      color: Colors.blue, width: 2),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (_positionStreamSubscription != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 24),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: Colors.green.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: const [
                              Icon(Icons.share, color: Colors.green, size: 20),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Live location sharing is active.',
                                  style: TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const Text(
                        'Pet Information',
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Colors.black87),
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: pet.photoUrl.isNotEmpty
                            ? Image.network(
                                pet.photoUrl,
                                height: 250,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    _buildPlaceholder(),
                              )
                            : _buildPlaceholder(),
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow('Name', pet.name, Icons.pets),
                      _buildInfoRow('Breed', pet.breed, Icons.category),
                      _buildInfoRow('Age', '${pet.age} years', Icons.cake),
                      _buildInfoRow('Color', pet.color, Icons.palette),
                      _buildInfoRow(
                          'Special Marks', pet.specialMarks, Icons.description),
                      const SizedBox(height: 32),
                      const Text(
                        'Owner Contact',
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Colors.black87),
                      ),
                      const SizedBox(height: 24),
                      if (_positionStreamSubscription != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 24),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: Colors.red.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'LIVE: Sharing your location with the owner...',
                                  style: TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF6B35)
                                      .withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.person,
                                    color: Color(0xFFFF6B35)),
                              ),
                              title: Text(pet.ownerName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              subtitle: const Text('Owner Name'),
                            ),
                            const Divider(indent: 70),
                            ListTile(
                              leading: const Icon(Icons.phone,
                                  color: Colors.black54),
                              title: Text(pet.ownerPhone),
                              subtitle: const Text('Phone Number'),
                              trailing: IconButton(
                                icon:
                                    const Icon(Icons.call, color: Colors.green),
                                onPressed: () => _makePhoneCall(pet.ownerPhone),
                              ),
                            ),
                            const Divider(indent: 70),
                            ListTile(
                              leading: const Icon(Icons.email,
                                  color: Colors.black54),
                              title: Text(pet.ownerEmail),
                              subtitle: const Text('Email'),
                              trailing: IconButton(
                                icon:
                                    const Icon(Icons.mail, color: Colors.blue),
                                onPressed: () => _sendEmail(pet.ownerEmail),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      if (_currentLat != null && _currentLng != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Current Location',
                              style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.black87),
                            ),
                            const SizedBox(height: 16),
                            if (_currentLat != null && _currentLng != null)
                              Container(
                                height: 250,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.1),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(24),
                                  child: GoogleMap(
                                    myLocationEnabled: true,
                                    myLocationButtonEnabled: true,
                                    onMapCreated: (controller) =>
                                        _mapController = controller,
                                    initialCameraPosition: CameraPosition(
                                      target:
                                          LatLng(_currentLat!, _currentLng!),
                                      zoom: 17,
                                    ),
                                    markers: {
                                      Marker(
                                        markerId:
                                            const MarkerId('current_location'),
                                        position:
                                            LatLng(_currentLat!, _currentLng!),
                                        infoWindow: InfoWindow(
                                          title: 'Pet Location',
                                          snippet: widget.scanLocation,
                                        ),
                                      ),
                                    },
                                  ),
                                ),
                              )
                            else
                              Container(
                                height: 250,
                                decoration: BoxDecoration(
                                  color: Colors.grey.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: const Center(
                                  child: Text('Waiting for location...'),
                                ),
                              ),
                            const SizedBox(height: 12),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                widget.scanLocation,
                                style: const TextStyle(
                                    color: Colors.black54,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      height: 250,
      color: Colors.grey[300],
      child: const Icon(
        Icons.pets,
        size: 100,
        color: Colors.grey,
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            icon,
            color: const Color(0xFFFF6B35),
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
