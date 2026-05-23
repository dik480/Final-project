import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/custom_header.dart';
import 'pets/pet_tracking_screen.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  Future<void> _openMap(double lat, double lng) async {
    final url = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return CustomHeaderScreen(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  SizedBox(width: 16.w),
                  Text(
                    'Notifications',
                    style: TextStyle(
                      fontSize: 28.sp,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: Text(
                  'Please log in to view notifications.',
                  style: TextStyle(fontSize: 16.sp, color: Colors.black54, fontWeight: FontWeight.w500),
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
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                SizedBox(width: 16.w),
                Text(
                  'Notifications',
                  style: TextStyle(
                    fontSize: 28.sp,
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
                          padding: EdgeInsets.all(24.r),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 20.r,
                                offset: Offset(0, 10.h),
                              ),
                            ],
                          ),
                          child: Icon(Icons.notifications_none, size: 64.r, color: Colors.grey[400]),
                        ),
                        SizedBox(height: 24.h),
                        Text(
                          'No notifications yet',
                          style: TextStyle(color: Colors.black54, fontSize: 18.sp, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.all(24.r),
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
                      margin: EdgeInsets.only(bottom: 16.h),
                      padding: EdgeInsets.all(20.r),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 20.r,
                            offset: Offset(0, 10.h),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(12.r),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF6B35).withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.pets, color: const Color(0xFFFF6B35), size: 24.r),
                              ),
                              SizedBox(width: 16.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(title,
                                        style: TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 16.sp,
                                            color: Colors.black87)),
                                    if (timeFormatted.isNotEmpty)
                                      Text(timeFormatted,
                                          style: TextStyle(
                                              color: Colors.black54,
                                              fontSize: 12.sp,
                                              fontWeight: FontWeight.w500)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16.h),
                          Text(body, style: TextStyle(fontSize: 14.sp, color: Colors.black87, height: 1.4)),
                          if (data['finder_name'] != null) ...[
                            SizedBox(height: 12.h),
                            Text(
                              'Found by: ${data['finder_name']}',
                              style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: Colors.black54),
                            ),
                          ],
                          if (lat != null && lng != null) ...[
                            SizedBox(height: 20.h),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _openMap(lat, lng),
                                    icon: const Icon(Icons.map),
                                    label: const Text('Maps'),
                                    style: OutlinedButton.styleFrom(
                                      padding: EdgeInsets.symmetric(vertical: 12.h),
                                      foregroundColor: const Color(0xFFFF6B35),
                                      side: const BorderSide(color: Color(0xFFFF6B35)),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12.r),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 12.w),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => PetTrackingScreen(
                                            notificationId: docs[index].id,
                                            trackingId: data['trackingId'],
                                          ),
                                        ),
                                      );
                                    },
                                    icon: Icon(data['status'] == 'active' ? Icons.location_searching : Icons.history, size: 20.r),
                                    label: Text(data['status'] == 'active' ? 'Live Track' : 'Track Pet', style: TextStyle(fontSize: 14.sp)),
                                    style: ElevatedButton.styleFrom(
                                      padding: EdgeInsets.symmetric(vertical: 12.h),
                                      backgroundColor: data['status'] == 'active' ? const Color(0xFFFF6B35) : Colors.grey[700],
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12.r),
                                      ),
                                    ),
                                  ),
                                ),
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
  }
}
