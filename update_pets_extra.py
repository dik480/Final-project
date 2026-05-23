import os

def update_report_found():
    path = 'lib/screens/pets/report_found_pet_screen.dart'
    if not os.path.exists(path): return
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    if 'custom_header.dart' not in content:
        content = content.replace('import \'package:firebase_auth/firebase_auth.dart\';', 'import \'package:firebase_auth/firebase_auth.dart\';\nimport \'../../utils/custom_header.dart\';')
    
    build_start = content.find('  @override\n  Widget build(BuildContext context) {')
    if build_start != -1:
        new_build = '''  @override
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
                  'Report Found Pet',
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
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.imageFile != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Image.file(widget.imageFile!, height: 200, width: double.infinity, fit: BoxFit.cover),
                      ),
                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Pet Details', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Colors.black87)),
                          const SizedBox(height: 24),
                          TextFormField(
                            controller: _breedController,
                            decoration: const InputDecoration(labelText: 'Breed', prefixIcon: Icon(Icons.pets, color: Color(0xFFFF6B35))),
                            validator: (v) => v == null || v.isEmpty ? 'Please enter breed' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _colorController,
                            decoration: const InputDecoration(labelText: 'Color', prefixIcon: Icon(Icons.palette, color: Color(0xFFFF6B35))),
                            validator: (v) => v == null || v.isEmpty ? 'Please enter color' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _locationController,
                            decoration: const InputDecoration(labelText: 'Where was it found?', prefixIcon: Icon(Icons.location_on, color: Color(0xFFFF6B35))),
                            validator: (v) => v == null || v.isEmpty ? 'Please enter location' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _descriptionController,
                            maxLines: 3,
                            decoration: const InputDecoration(labelText: 'Description / Marks', prefixIcon: Icon(Icons.description, color: Color(0xFFFF6B35))),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Your Contact Info', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Colors.black87)),
                          const SizedBox(height: 24),
                          TextFormField(
                            controller: _finderNameController,
                            decoration: const InputDecoration(labelText: 'Your Name', prefixIcon: Icon(Icons.person, color: Color(0xFFFF6B35))),
                            validator: (v) => v == null || v.isEmpty ? 'Please enter your name' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _finderPhoneController,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(labelText: 'Your Phone', prefixIcon: Icon(Icons.phone, color: Color(0xFFFF6B35))),
                            validator: (v) => v == null || v.isEmpty ? 'Please enter your phone' : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitReport,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF6B35),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isLoading 
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Post Report', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }'''
        content = content[:build_start] + new_build
        with open(path, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f'Updated {path}')

def update_tracking():
    path = 'lib/screens/pets/pet_tracking_screen.dart'
    if not os.path.exists(path): return
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    if 'custom_header.dart' not in content:
        content = content.replace('import \'package:google_maps_flutter/google_maps_flutter.dart\';', 'import \'package:google_maps_flutter/google_maps_flutter.dart\';\nimport \'../../utils/custom_header.dart\';')
    
    build_start = content.find('  @override\n  Widget build(BuildContext context) {')
    if build_start != -1:
        new_build = '''  @override
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
                  .collection('notifications')
                  .doc(widget.notificationId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.white));
                }

                if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
                  return const Center(child: Text('Tracking session not found or ended.', style: TextStyle(color: Colors.white)));
                }

                final data = snapshot.data!.data() as Map<String, dynamic>;
                final location = data['location'] as Map<String, dynamic>?;
                final lat = location?['lat'] as double?;
                final lng = location?['lng'] as double?;
                final status = data['status'] ?? 'inactive';
                final title = data['title'] ?? 'Pet Found';

                if (lat == null || lng == null) {
                  return const Center(child: Text('Location data missing.', style: TextStyle(color: Colors.white)));
                }

                final position = LatLng(lat, lng);
                _mapController?.animateCamera(CameraUpdate.newLatLng(position));

                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                      child: GoogleMap(
                        onMapCreated: _onMapCreated,
                        initialCameraPosition: CameraPosition(target: position, zoom: 16),
                        markers: {
                          Marker(
                            markerId: const MarkerId('pet_marker'),
                            position: position,
                            infoWindow: InfoWindow(title: title),
                            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
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
                            color: Colors.red.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 5)),
                            ],
                          ),
                          child: const Text(
                            'Tracking offline. Showing last known location.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
                            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10)),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Finder Location',
                              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: Colors.black87),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'The finder is currently at this location. You can contact them below.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.black54, height: 1.4),
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Finder contact info is in the notification details.')),
                                  );
                                },
                                icon: const Icon(Icons.phone),
                                label: const Text('Contact Finder', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
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
  }'''
        content = content[:build_start] + new_build
        with open(path, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f'Updated {path}')

if __name__ == '__main__':
    update_report_found()
    update_tracking()
