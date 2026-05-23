import 'package:flutter/material.dart';
import '../../utils/custom_header.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class NGOFinderScreen extends StatefulWidget {
  const NGOFinderScreen({super.key});

  @override
  State<NGOFinderScreen> createState() => _NGOFinderScreenState();
}

class _NGOFinderScreenState extends State<NGOFinderScreen> {
  final TextEditingController _locationController = TextEditingController();
  bool _isLoading = false;

  List<Map<String, dynamic>> ngos = [
    {
      'name': 'Animal Welfare Foundation',
      'description': 'Free treatment and rescue services for stray animals',
      'phone': '+977-1-4371234',
      'email': 'info@awf.org.np',
      'address': 'Lalitpur, Nepal',
      'services': ['Emergency Care', 'Free Treatment', 'Adoption'],
    },
    {
      'name': 'Sneha Care Nepal',
      'description': 'Comprehensive animal care and rehabilitation',
      'phone': '+977-1-5551234',
      'email': 'contact@snehanepal.org',
      'address': 'Kathmandu, Nepal',
      'services': ['Vaccination', 'Surgery', 'Shelter'],
    },
    {
      'name': 'Himalayan Animal Rescue Trust',
      'description': 'Street animal rescue and medical support',
      'phone': '+977-1-4456789',
      'email': 'help@hart.org.np',
      'address': 'Bhaktapur, Nepal',
      'services': ['24/7 Rescue', 'Emergency Care', 'Rehabilitation'],
    },
    {
      'name': 'Paws for a Cause Nepal',
      'description': 'Low-cost veterinary services and animal welfare',
      'phone': '+977-1-4223456',
      'email': 'info@pawscause.org',
      'address': 'Pokhara, Nepal',
      'services': ['Low-Cost Treatment', 'Sterilization', 'Adoption'],
    },
    {
      'name': 'Nepal Street Dogs Protection',
      'description': 'Protecting and caring for street dogs across Nepal',
      'phone': '+977-1-4667890',
      'email': 'nsdp@streetdogs.org.np',
      'address': 'Multiple Locations',
      'services': ['Street Dog Care', 'Feeding Programs', 'Medical Aid'],
    },
  ];

  @override
  void dispose() {
    _locationController.dispose();
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
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  Future<void> _searchNGOs() async {
    final locationQuery = _locationController.text.trim();
    if (locationQuery.isEmpty) return;
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Get coordinates using Nominatim
      final nominatimUrl = Uri.parse(
          'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(locationQuery)}&format=json&limit=1');

      final nominatimResponse = await http.get(nominatimUrl, headers: {
        'User-Agent': 'PawtnerApp/1.0',
      });

      if (nominatimResponse.statusCode != 200) {
        throw Exception('Failed to get location coordinates');
      }

      final List<dynamic> locations = jsonDecode(nominatimResponse.body);
      if (locations.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content:
                    Text('Location not found. Please try a different search.')),
          );
        }
        return;
      }

      final lat = locations[0]['lat'];
      final lon = locations[0]['lon'];
      final locationName = locations[0]['display_name'] ?? locationQuery;

      // 2. Fetch NGOs and Vets using Overpass API
      // Search within a 20km radius (20000 meters)
      final overpassQuery = '''
        [out:json][timeout:25];
        (
          node["amenity"="animal_shelter"](around:20000,$lat,$lon);
          way["amenity"="animal_shelter"](around:20000,$lat,$lon);
          relation["amenity"="animal_shelter"](around:20000,$lat,$lon);
          node["amenity"="veterinary"](around:20000,$lat,$lon);
          way["amenity"="veterinary"](around:20000,$lat,$lon);
          relation["amenity"="veterinary"](around:20000,$lat,$lon);
        );
        out body;
        >;
        out skel qt;
      ''';

      final List<String> overpassUrls = [
        'https://overpass-api.de/api/interpreter',
        'https://lz4.overpass-api.de/api/interpreter',
        'https://z.overpass-api.de/api/interpreter',
      ];

      http.Response? overpassResponse;
      String lastError = '';

      for (var url in overpassUrls) {
        try {
          final response = await http.post(
            Uri.parse(url),
            headers: {'User-Agent': 'PawtnerApp/1.0'},
            body: {'data': overpassQuery},
          ).timeout(const Duration(seconds: 15));

          if (response.statusCode == 200) {
            overpassResponse = response;
            break;
          } else {
            lastError = 'Status ${response.statusCode} from $url';
          }
        } catch (e) {
          lastError = 'Error connecting to $url: $e';
        }
      }

      if (overpassResponse == null) {
        throw Exception('Failed to fetch data from all Overpass servers. Last error: $lastError');
      }

      final overpassData = jsonDecode(overpassResponse.body);
      final List<dynamic> elements = overpassData['elements'] ?? [];

      final List<Map<String, dynamic>> newNgos = [];

      for (var element in elements) {
        if (element['type'] == 'node' ||
            element['type'] == 'way' ||
            element['type'] == 'relation') {
          final tags = element['tags'];
          if (tags == null) continue;

          final name = tags['name'];
          if (name == null) continue; // Skip unnamed locations

          final isVet = tags['amenity'] == 'veterinary';
          final description =
              isVet ? 'Veterinary Clinic' : 'Animal Shelter / NGO';

          final phone = tags['phone'] ?? tags['contact:phone'] ?? 'N/A';
          final email = tags['email'] ?? tags['contact:email'] ?? 'N/A';

          // Try to construct address
          String address = '';
          if (tags['addr:full'] != null) {
            address = tags['addr:full'];
          } else {
            final street = tags['addr:street'];
            final city = tags['addr:city'];
            if (street != null && city != null) {
              address = '$street, $city';
            } else if (city != null) {
              address = city;
            } else {
              address = 'Near $locationName';
            }
          }

          newNgos.add({
            'name': name,
            'description': tags['description'] ?? description,
            'phone': phone,
            'email': email,
            'address': address,
            'services': isVet
                ? ['Veterinary', 'Medical Care']
                : ['Shelter', 'Animal Care', 'Rescue'],
          });
        }
      }

      if (newNgos.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No NGOs or Vets found nearby.')),
          );
        }
      }

      setState(() {
        // Only take the top 15 results so it doesn't get overwhelming
        ngos = newNgos.take(15).toList();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to fetch NGOs. Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomHeaderScreen(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                    const Icon(
                      Icons.location_on,
                      size: 32,
                      color: Colors.white,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  'Find Nearby NGOs/Veterinary',
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                //const SizedBox(height: 8),
                /* const Text(
                  'Discover veterinary and NGOs around you',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),*/
                const SizedBox(height: 40),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _locationController,
                          decoration: InputDecoration(
                            hintText: 'Enter your location (e.g., Kathmandu)',
                            hintStyle: TextStyle(color: Colors.grey[400]),
                            prefixIcon: const Icon(Icons.search,
                                color: Color(0xFFFF6B35)),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 16),
                          ),
                          onSubmitted: (_) => _searchNGOs(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                    color: Color(0xFFFF6B35), strokeWidth: 2),
                              )
                            : const Icon(Icons.arrow_forward,
                                color: Color(0xFFFF6B35)),
                        onPressed: _isLoading ? null : _searchNGOs,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFFF6B35)))
                : ListView.builder(
                    padding: const EdgeInsets.all(24),
                    itemCount: ngos.length,
                    itemBuilder: (context, index) {
                      final ngo = ngos[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 20),
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
                        child: Theme(
                          data: Theme.of(context).copyWith(
                            dividerColor: Colors.transparent,
                          ),
                          child: ExpansionTile(
                            leading: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF6B35)
                                    .withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.local_hospital,
                                color: Color(0xFFFF6B35),
                              ),
                            ),
                            title: Text(
                              ngo['name'],
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                ngo['description'],
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.black54,
                                ),
                              ),
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.location_on,
                                          size: 20,
                                          color: Color(0xFFFF6B35),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            ngo['address'],
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'Services',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: (ngo['services']
                                              as List<dynamic>)
                                          .map((service) => Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 6,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.green
                                                      .withValues(alpha: 0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                ),
                                                child: Text(
                                                  service.toString(),
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.green,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ))
                                          .toList(),
                                    ),
                                    const SizedBox(height: 24),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            onPressed: () =>
                                                _makePhoneCall(ngo['phone']),
                                            icon: const Icon(Icons.phone,
                                                size: 18),
                                            label: const Text('Call'),
                                            style: ElevatedButton.styleFrom(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                vertical: 16,
                                              ),
                                              backgroundColor:
                                                  const Color(0xFFFF6B35),
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            onPressed: () =>
                                                _sendEmail(ngo['email']),
                                            icon: const Icon(Icons.email,
                                                size: 18),
                                            label: const Text('Email'),
                                            style: OutlinedButton.styleFrom(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                vertical: 16,
                                              ),
                                              foregroundColor:
                                                  const Color(0xFFFF6B35),
                                              side: const BorderSide(
                                                color: Color(0xFFFF6B35),
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
