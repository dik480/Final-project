import os

def update_notifications():
    path = 'lib/screens/notifications_screen.dart'
    if not os.path.exists(path):
        print(f'{path} not found')
        return
    
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    if 'custom_header.dart' not in content:
        content = content.replace('import \'package:url_launcher/url_launcher.dart\';', 'import \'package:url_launcher/url_launcher.dart\';\nimport \'../utils/custom_header.dart\';')
    
    build_start = content.find('  @override\n  Widget build(BuildContext context) {')
    if build_start != -1:
        new_build = '''  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
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
                    'Notifications',
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
            const Expanded(
              child: Center(
                child: Text(
                  'Please log in to view notifications.',
                  style: TextStyle(fontSize: 16, color: Colors.black54, fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ],
        ),
      );
    }

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
                  'Notifications',
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
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('notifications').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFFFF6B35)));
                }

                if (snapshot.hasError) {
                  return const Center(child: Text('Error loading notifications'));
                }

                final docs = snapshot.data?.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final ownerId = data['owner_id']?.toString() ?? '';
                  return ownerId == user.uid || ownerId == user.email;
                }).toList() ?? [];

                docs.sort((a, b) {
                  final aData = a.data() as Map<String, dynamic>;
                  final bData = b.data() as Map<String, dynamic>;
                  final aTime = aData['timestamp'] as String? ?? '';
                  final bTime = bData['timestamp'] as String? ?? '';
                  return bTime.compareTo(aTime);
                });

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Icon(Icons.notifications_none, size: 64, color: Colors.grey[400]),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'No notifications yet',
                          style: TextStyle(color: Colors.black54, fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final title = data['title'] ?? 'Notification';
                    final body = data['body'] ?? '';
                    final timestampStr = data['timestamp'] ?? '';

                    DateTime? time;
                    if (timestampStr.isNotEmpty) {
                      time = DateTime.tryParse(timestampStr);
                    }

                    final timeFormatted = time != null
                        ? DateFormat('MMM d, yyyy - h:mm a').format(time.toLocal())
                        : '';

                    final location = data['location'] as Map<String, dynamic>?;
                    final lat = location?['lat'] as double?;
                    final lng = location?['lng'] as double?;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(20),
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
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF6B35).withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.pets, color: Color(0xFFFF6B35)),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(title,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 16,
                                            color: Colors.black87)),
                                    if (timeFormatted.isNotEmpty)
                                      Text(timeFormatted,
                                          style: TextStyle(
                                              color: Colors.black54,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(body, style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.4)),
                          if (lat != null && lng != null) ...[
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _openMap(lat, lng),
                                    icon: const Icon(Icons.map),
                                    label: const Text('Google Maps'),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      foregroundColor: const Color(0xFFFF6B35),
                                      side: const BorderSide(color: Color(0xFFFF6B35)),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                                if (data['status'] == 'active') ...[
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => PetTrackingScreen(
                                              notificationId: docs[index].id,
                                            ),
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.location_searching),
                                      label: const Text('Live Track'),
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        backgroundColor: const Color(0xFFFF6B35),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ]
                        ],
                      ),
                    );
                  },
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

def update_scanned_info():
    path = 'lib/screens/scanner/scanned_pet_info_screen.dart'
    if not os.path.exists(path):
        print(f'{path} not found')
        return
    
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    if 'custom_header.dart' not in content:
        content = content.replace('import \'../../models/pet_model.dart\';', 'import \'../../models/pet_model.dart\';\nimport \'../../utils/custom_header.dart\';')
    
    build_start = content.find('  @override\n  Widget build(BuildContext context) {')
    end = content.find('  Widget _buildPlaceholder', build_start)
    if build_start != -1 and end != -1:
        new_build = '''  @override
  Widget build(BuildContext context) {
    return CustomHeaderScreen(
      child: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('pets').doc(widget.petId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.white));
          }

          if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text('Pet information not found', style: TextStyle(color: Colors.white, fontSize: 18)),
            );
          }

          final pet = PetModel.fromFirestore(snapshot.data!);

          return Column(
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
                              color: Colors.black.withOpacity(0.05),
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
                                color: Colors.green.withOpacity(0.1),
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
                                onPressed: _positionStreamSubscription == null ? _startLiveTracking : _stopLiveTracking,
                                icon: Icon(_positionStreamSubscription == null ? Icons.location_on : Icons.location_off),
                                label: Text(_positionStreamSubscription == null ? 'Share Live Location' : 'Stop Sharing', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _positionStreamSubscription == null ? Colors.blue : Colors.red,
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
                      const SizedBox(height: 24),
                      if (_positionStreamSubscription != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 24),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.green.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: const [
                              Icon(Icons.share, color: Colors.green, size: 20),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Live location sharing is active.',
                                  style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const Text(
                        'Pet Information',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.black87),
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
                                errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
                              )
                            : _buildPlaceholder(),
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow('Name', pet.name, Icons.pets),
                      _buildInfoRow('Breed', pet.breed, Icons.category),
                      _buildInfoRow('Age', '${pet.age} years', Icons.cake),
                      _buildInfoRow('Color', pet.color, Icons.palette),
                      _buildInfoRow('Special Marks', pet.specialMarks, Icons.description),
                      const SizedBox(height: 32),
                      const Text(
                        'Owner Contact',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.black87),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(8),
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
                          children: [
                            ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF6B35).withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.person, color: Color(0xFFFF6B35)),
                              ),
                              title: Text(pet.ownerName, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: const Text('Owner Name'),
                            ),
                            const Divider(indent: 70),
                            ListTile(
                              leading: const Icon(Icons.phone, color: Colors.black54),
                              title: Text(pet.ownerPhone),
                              subtitle: const Text('Phone Number'),
                              trailing: IconButton(
                                icon: const Icon(Icons.call, color: Colors.green),
                                onPressed: () => _makePhoneCall(pet.ownerPhone),
                              ),
                            ),
                            const Divider(indent: 70),
                            ListTile(
                              leading: const Icon(Icons.email, color: Colors.black54),
                              title: Text(pet.ownerEmail),
                              subtitle: const Text('Email'),
                              trailing: IconButton(
                                icon: const Icon(Icons.mail, color: Colors.blue),
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
                              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.black87),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              height: 250,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(24),
                                child: GoogleMap(
                                  initialCameraPosition: CameraPosition(
                                    target: LatLng(_currentLat!, _currentLng!),
                                    zoom: 15,
                                  ),
                                  markers: {
                                    Marker(
                                      markerId: const MarkerId('current_location'),
                                      position: LatLng(_currentLat!, _currentLng!),
                                      infoWindow: InfoWindow(
                                        title: 'Pet Location',
                                        snippet: widget.scanLocation,
                                      ),
                                    ),
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                widget.scanLocation,
                                style: const TextStyle(color: Colors.black54, fontSize: 14, fontWeight: FontWeight.w500),
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
  }'''
        content = content[:build_start] + new_build + content[end:]
        with open(path, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f'Updated {path}')

if __name__ == '__main__':
    update_notifications()
    update_scanned_info()
