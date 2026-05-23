import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../pets/my_pets_screen.dart';
import '../pets/add_pet_screen.dart';
import '../pets/found_pet_reports_screen.dart';
import '../scanner/qr_scanner_screen.dart';
import '../ngo/ngo_finder_screen.dart';
import '../first_aid/first_aid_screen.dart';
import 'package:app_links/app_links.dart';
import '../notifications_screen.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../scan_pet_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  // ignore: unused_field
  String _userName = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
    handleIncomingLinks();
  }

  late AppLinks _appLinks;

  void handleIncomingLinks() async {
    _appLinks = AppLinks();

    // Check initial link
    try {
      final Uri? initialUri = await _appLinks.getInitialAppLink();
      if (mounted && initialUri != null) {
        _processUri(initialUri);
      }
    } catch (e) {
      // Ignored
    }

    // Listen to background links
    _appLinks.uriLinkStream.listen((uri) {
      if (mounted) {
        _processUri(uri);
      }
    });
  }

  void _processUri(Uri uri) {
    if (uri.pathSegments.contains('pet')) {
      String qrId = uri.pathSegments.last;
      Navigator.pushNamed(context, '/register', arguments: qrId);
    }
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists && mounted) {
        setState(() {
          _userName = doc.data()?['name'] ?? user.displayName ?? 'User';
        });
      }
    }
  }

  Widget _buildAppBarActions() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('notifications')
              .snapshots(),
          builder: (context, snapshot) {
            int count = 0;
            final user = FirebaseAuth.instance.currentUser;
            if (snapshot.hasData && user != null) {
              count = snapshot.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final ownerId = data['owner_id']?.toString() ?? '';
                return ownerId == user.uid || ownerId == user.email;
              }).length;
            }

            return Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NotificationsScreen(),
                      ),
                    );
                  },
                ),
                if (count > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '$count',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10.sp,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.logout),
          onPressed: () async {
            await FirebaseAuth.instance.signOut();
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      HomeTab(actions: _buildAppBarActions()),
      const MyPetsScreen(),
      const FirstAidScreen(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE), // Soft light background
      appBar: null,
      body: screens[_selectedIndex],
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const FoundPetReportsScreen()),
                );
              },
              backgroundColor: const Color(0xFFFF6B35),
              icon: const Icon(Icons.find_in_page_rounded, color: Colors.white),
              label: const Text('Found Reports',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        selectedItemColor: const Color(0xFFFF6B35),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pets),
            label: 'My Pets',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.medical_services),
            label: 'First Aid',
          ),
        ],
      ),
    );
  }
}

class HomeClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 80);

    var firstControlPoint = Offset(size.width / 4, size.height);
    var firstEndPoint = Offset(size.width / 2.25, size.height - 30);
    path.quadraticBezierTo(firstControlPoint.dx, firstControlPoint.dy,
        firstEndPoint.dx, firstEndPoint.dy);

    var secondControlPoint =
        Offset(size.width - (size.width / 3.25), size.height - 105);
    var secondEndPoint = Offset(size.width, size.height - 40);
    path.quadraticBezierTo(secondControlPoint.dx, secondControlPoint.dy,
        secondEndPoint.dx, secondEndPoint.dy);

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) {
    return false;
  }
}

class HomeTab extends StatelessWidget {
  final Widget actions;

  const HomeTab({super.key, required this.actions});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Stack(
      children: [
        // Top right organic blob using CustomClipper
        Positioned(
          top: 0,
          right: 0,
          left: 0,
          height: 250.h,
          child: ClipPath(
            clipper: HomeClipper(),
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFFB347), Color(0xFFFF6B35)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
        ),
        SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20.0, vertical: 5.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Image.asset(
                      'assets/images/logo_new.png',
                      height: 60.h,
                      fit: BoxFit.contain,
                    ),
                    Theme(
                      data: Theme.of(context).copyWith(
                        iconTheme: const IconThemeData(color: Colors.white),
                      ),
                      child: actions,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(screenWidth * 0.06, 0,
                      screenWidth * 0.06, 80), // Extra bottom padding for FAB
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pawtner Services',
                        style: TextStyle(
                          fontSize: 28.sp,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      FutureBuilder<DocumentSnapshot>(
                        future: user != null
                            ? FirebaseFirestore.instance
                                .collection('users')
                                .doc(user.uid)
                                .get()
                            : null,
                        builder: (context, snapshot) {
                          String name = user?.displayName ?? 'User';
                          if (snapshot.hasData && snapshot.data!.exists) {
                            name = snapshot.data!.get('name') ?? name;
                          }
                          return Text(
                            'Welcome back, $name!',
                            style: TextStyle(
                              fontSize: 16.sp,
                              height: 1,
                              color: Colors.white70,
                              fontWeight: FontWeight.w500,
                            ),
                          );
                        },
                      ),
                      SizedBox(height: 32.h),
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: isTablet ? 3 : 2,
                        crossAxisSpacing: 16.w,
                        mainAxisSpacing: 16.h,
                        childAspectRatio: isTablet
                            ? 1.0
                            : (screenWidth / 480).clamp(0.7, 0.9),
                        children: [
                          _buildFeatureCard(
                            context,
                            'Add Pet',
                            Icons.add_circle,
                            Colors.orange,
                            () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const AddPetScreen())),
                          ),
                          _buildFeatureCard(
                            context,
                            'Scan QR Code',
                            Icons.qr_code_scanner,
                            Colors.blue,
                            () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const QRScannerScreen())),
                          ),
                          _buildFeatureCard(
                            context,
                            'Scan Found Pet',
                            Icons.camera_alt,
                            Colors.purple,
                            () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const ScanPetScreen())),
                          ),
                          _buildFeatureCard(
                            context,
                            'Find NGOs/Veterinary',
                            Icons.location_on,
                            Colors.green,
                            () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const NGOFinderScreen())),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24.r),
                          boxShadow: [
                            BoxShadow(
                              // ignore: deprecated_member_use
                              color: Colors.black.withValues(alpha: 0.03),
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
                                const Icon(Icons.info_outline,
                                    color: Color(0xFFFF6B35)),
                                const SizedBox(width: 12),
                                Text(
                                  'How It Works',
                                  style: TextStyle(
                                    fontSize: 20.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            _buildInfoRow(
                                'Register your pet with details and photo'),
                            _buildInfoRow('Get a unique QR code for your pet'),
                            _buildInfoRow('Attach QR code to pet\'s collar'),
                            _buildInfoRow(
                                'If lost, anyone can scan and contact you'),
                            _buildInfoRow(
                                'Get instant notifications with location'),
                          ],
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
    );
  }

  Widget _buildFeatureCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            // ignore: deprecated_member_use
            color: color.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24.r),
          child: Padding(
            padding: EdgeInsets.all(16.r),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(12.r),
                  decoration: BoxDecoration(
                    // ignore: deprecated_member_use
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 28.r, color: color),
                ),
                SizedBox(height: 12.h),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle,
            color: Color(0xFFFF6B35),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
