import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../utils/custom_header.dart';
import '../utils/ml_service.dart';
import 'pets/report_found_pet_screen.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ScanPetScreen extends StatefulWidget {
  const ScanPetScreen({super.key});

  @override
  State<ScanPetScreen> createState() => _ScanPetScreenState();
}

class _ScanPetScreenState extends State<ScanPetScreen> {
  File? _image;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  Future<void> _captureImage() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  /// Parse a Cloudinary hex color string like "#a1b2c3" into [r, g, b] ints.
  List<int>? _hexToRgb(String hex) {
    try {
      final clean = hex.replaceAll('#', '');
      if (clean.length != 6) return null;
      return [
        int.parse(clean.substring(0, 2), radix: 16),
        int.parse(clean.substring(2, 4), radix: 16),
        int.parse(clean.substring(4, 6), radix: 16),
      ];
    } catch (_) {
      return null;
    }
  }

  /// Cloudinary returns colors as: [["#rrggbb", percentage], ...]
  /// This computes an average weighted RGB distance between the two palettes.
  double _calculateColorSimilarity(
      List<dynamic>? colors1, List<dynamic>? colors2) {
    if (colors1 == null ||
        colors2 == null ||
        colors1.isEmpty ||
        colors2.isEmpty) {
      return 0.0;
    }

    try {
      // Take up to 3 dominant colors from each palette
      final palette1 = colors1
          .take(3)
          .map((e) {
            final hex = (e is List) ? e[0] : (e is Map ? e['hex'] : e);
            return _hexToRgb(hex.toString());
          })
          .whereType<List<int>>()
          .toList();
      final palette2 = colors2
          .take(3)
          .map((e) {
            final hex = (e is List) ? e[0] : (e is Map ? e['hex'] : e);
            return _hexToRgb(hex.toString());
          })
          .whereType<List<int>>()
          .toList();

      if (palette1.isEmpty || palette2.isEmpty) return 0.0;

      // Compare each color in palette1 against the best match in palette2
      double totalSimilarity = 0.0;
      for (final c1 in palette1) {
        double bestMatch = 0.0;
        for (final c2 in palette2) {
          double rDiff = (c1[0] - c2[0]).toDouble();
          double gDiff = (c1[1] - c2[1]).toDouble();
          double bDiff = (c1[2] - c2[2]).toDouble();
          double dist = rDiff * rDiff + gDiff * gDiff + bDiff * bDiff;
          double sim = 1.0 - (dist / (255.0 * 255.0 * 3.0));
          if (sim > bestMatch) bestMatch = sim;
        }
        totalSimilarity += bestMatch;
      }

      return totalSimilarity / palette1.length;
    } catch (_) {
      return 0.0;
    }
  }

  Future<void> _findMatch() async {
    if (_image == null) return;

    setState(() => _isLoading = true);

    try {
      // 1. Upload captured image to Cloudinary (temp) to get visual metadata
      List<dynamic>? capturedColors;
      List<double>? capturedFeatureVector;

      if (_image != null) {
        capturedFeatureVector = await mlService.getFeatureVector(_image!);
      }

      final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/dgzff9iz9/image/upload',
      );
      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = 'p6dxs498'
        ..files.add(await http.MultipartFile.fromPath('file', _image!.path));

      final response = await request.send();
      final responseData = await response.stream.toBytes();
      final responseBody = utf8.decode(responseData);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonMap = jsonDecode(responseBody);
        capturedColors = jsonMap['colors'] as List<dynamic>?;

        // --- IMAGE QUALITY VALIDATION ---
        // 1. Check for dark/blank images
        if (capturedColors != null && capturedColors.isNotEmpty) {
          bool isTooDark = true;
          for (var colorEntry in capturedColors) {
            final hex = (colorEntry is List) ? colorEntry[0] : (colorEntry is Map ? colorEntry['hex'] : colorEntry);
            final rgb = _hexToRgb(hex.toString());
            if (rgb != null) {
              // If any dominant color has a brightness > 50 (out of 255), it's not "blank dark"
              if (rgb[0] > 50 || rgb[1] > 50 || rgb[2] > 50) {
                isTooDark = false;
                break;
              }
            }
          }
          if (isTooDark) {
            throw Exception('The image is too dark or lacks detail. Please try scanning in better lighting.');
          }
        }

        // 2. Check for "flat" images (all same color)
        if (capturedColors != null && capturedColors.length < 2) {
           // If there's only 1 dominant color, it's likely a flat surface (wall, floor, blank paper)
           throw Exception('The image lacks enough visual features. Please ensure the pet is clearly visible in the frame.');
        }
      } else {
        String cloudinaryError = responseBody;
        try {
          final errJson = jsonDecode(responseBody);
          cloudinaryError = errJson['error']?['message'] ?? responseBody;
        } catch (_) {}
        throw Exception('Failed to analyze image: $cloudinaryError');
      }

      // 2. Fetch all pets from Firestore
      final querySnapshot =
          await FirebaseFirestore.instance.collection('pets').get();
      if (querySnapshot.docs.isEmpty) {
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const ResultScreen(potentialMatches: [])),
          );
        }
        return;
      }

      final List<Map<String, dynamic>> petsList = querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      // 3. Compare with registered pets
      List<Map<String, dynamic>> matches = [];

      for (var pet in petsList) {
        double score = 0.0;

        // MobileNetV2 Feature Vector Similarity - weight: 0.8
        if (capturedFeatureVector != null && pet['featureVector'] != null) {
          List<dynamic> dbVec = pet['featureVector'];
          double sim = mlService.calculateCosineSimilarity(capturedFeatureVector, dbVec);
          // Only add to score if similarity is decent, otherwise penalize heavily
          score += sim * 0.8;
        }

        // color similarity - weight: 0.2
        if (capturedColors != null && pet['dominantColors'] != null) {
          double colorScore =
              _calculateColorSimilarity(capturedColors, pet['dominantColors']);
          score += colorScore * 0.2;
        }

        // --- ACCURACY IMPROVEMENT ---
        // Threshold: 0.70 for high-confidence matches
        if (score > 0.70) {
          pet['matchScore'] = score;
          matches.add(pet);
        }
      }

      // Sort by score descending
      matches.sort((a, b) =>
          (b['matchScore'] as double).compareTo(a['matchScore'] as double));

      // Take top 3
      if (matches.length > 3) {
        matches = matches.sublist(0, 3);
      }

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ResultScreen(
              potentialMatches: matches,
              capturedImage: _image,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  'Scan Found Pet',
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
            child: SingleChildScrollView(
              child: Center(
                child: Container(
                  constraints: BoxConstraints(maxWidth: 600.w),
                  margin: EdgeInsets.all(24.r),
                  padding: EdgeInsets.all(32.r),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 20.r,
                        offset: Offset(0, 10.h),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _image == null
                          ? Container(
                              height: 200.h,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF6B35)
                                    .withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(24.r),
                                border: Border.all(
                                  color: const Color(0xFFFF6B35)
                                      .withValues(alpha: 0.3),
                                  width: 2,
                                  style: BorderStyle.solid,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_a_photo,
                                    size: 48.r,
                                    color: const Color(0xFFFF6B35)
                                        .withValues(alpha: 0.5),
                                  ),
                                  SizedBox(height: 12.h),
                                  Text(
                                    'No image selected',
                                    style: TextStyle(
                                      fontSize: 16.sp,
                                      color: Colors.black54,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(24.r),
                              child: Image.file(_image!,
                                  height: 250.h,
                                  width: double.infinity,
                                  fit: BoxFit.cover),
                            ),
                      SizedBox(height: 32.h),
                      SizedBox(
                        width: double.infinity,
                        height: 56.h,
                        child: ElevatedButton.icon(
                          onPressed: _captureImage,
                          icon: const Icon(Icons.camera_alt),
                          label: Text("Capture Image",
                              style: TextStyle(
                                  fontSize: 18.sp, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[100],
                            foregroundColor: Colors.black87,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16.r),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 16.h),
                      SizedBox(
                        width: double.infinity,
                        height: 56.h,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _findMatch,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF6B35),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16.r),
                            ),
                            elevation: 5,
                            shadowColor:
                                const Color(0xFFFF6B35).withValues(alpha: 0.5),
                          ),
                          child: _isLoading
                              ? SizedBox(
                                  height: 24.h,
                                  width: 24.w,
                                  child: const CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 3),
                                )
                              : Text("Find Match",
                                  style: TextStyle(
                                      fontSize: 18.sp, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ResultScreen extends StatelessWidget {
  final List<Map<String, dynamic>> potentialMatches;
  final File? capturedImage;
  const ResultScreen(
      {super.key, required this.potentialMatches, this.capturedImage});

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isAnyMatchFound = potentialMatches.isNotEmpty;

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
                  'Match Results',
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
            child: SingleChildScrollView(
              padding: EdgeInsets.all(24.r),
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(32.r),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(32.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 20.r,
                          offset: Offset(0, 10.h),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: EdgeInsets.all(20.r),
                          decoration: BoxDecoration(
                            color: isAnyMatchFound
                                ? Colors.green.withValues(alpha: 0.1)
                                : Colors.orange.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isAnyMatchFound
                                ? Icons.check_circle
                                : Icons.error_outline,
                            size: 64.r,
                            color:
                                isAnyMatchFound ? Colors.green : Colors.orange,
                          ),
                        ),
                        SizedBox(height: 24.h),
                        Text(
                          isAnyMatchFound
                              ? "${potentialMatches.length} Potential Match(es) Found!"
                              : "No Direct Match Found",
                          style: TextStyle(
                              fontSize: 24.sp,
                              fontWeight: FontWeight.w900,
                              color: Colors.black87),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 12.h),
                        if (isAnyMatchFound)
                          Text(
                            "We found pets in our database that visually match the image you provided.",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.black54, fontSize: 14.sp),
                          ),
                        SizedBox(height: 32.h),
                        if (isAnyMatchFound)
                          ...potentialMatches
                              .map((match) => _buildMatchCard(context, match))
                        else ...[
                          Text(
                            "We couldn't find a pet with matching visual features. You can report this found pet so the owner can find you.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 16.sp,
                                color: Colors.black54,
                                height: 1.5,
                                fontWeight: FontWeight.w500),
                          ),
                          SizedBox(height: 32.h),
                          SizedBox(
                            width: double.infinity,
                            height: 56.h,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ReportFoundPetScreen(
                                        imageFile: capturedImage),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFF6B35),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16.r),
                                ),
                              ),
                              child: Text("Report Found Pet",
                                  style: TextStyle(
                                      fontSize: 18.sp,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                        SizedBox(height: 24.h),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text("Back to Scanner",
                              style: TextStyle(
                                  color: Colors.black54,
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchCard(BuildContext context, Map<String, dynamic> match) {
    double score = match['matchScore'] ?? 0.0;
    int percentage = (score * 100).toInt();

    return Container(
      margin: EdgeInsets.only(bottom: 24.h),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16.r),
                child: match['photoUrl'] != null &&
                        match['photoUrl'].toString().isNotEmpty
                    ? Image.network(
                        match['photoUrl'].toString(),
                        height: 80.h,
                        width: 80.w,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        color: Colors.grey[300],
                        height: 80.h,
                        width: 80.w,
                        child: const Icon(Icons.pets)),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      match['name']?.toString() ?? 'Unknown',
                      style: TextStyle(
                          fontSize: 18.sp, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      "${match['breed']} • ${match['color']}",
                      style: TextStyle(color: Colors.black54, fontSize: 14.sp),
                    ),
                    SizedBox(height: 8.h),
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        "$percentage% Match Score",
                        style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 12.sp),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Divider(height: 32.h),
          _buildInfoRow(
              Icons.person, "Owner", match['ownerName']?.toString() ?? 'N/A'),
          _buildInfoRow(
              Icons.phone, "Contact", match['ownerPhone']?.toString() ?? 'N/A'),
          SizedBox(height: 16.h),
          SizedBox(
            width: double.infinity,
            height: 48.h,
            child: ElevatedButton.icon(
              onPressed: () =>
                  _makePhoneCall(match['ownerPhone']?.toString() ?? ''),
              icon: Icon(Icons.call, size: 20.r),
              label: Text("Call Owner",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.0.h),
      child: Row(
        children: [
          Icon(icon, size: 16.r, color: Colors.grey[600]),
          SizedBox(width: 12.w),
          Text("$label: ",
              style:
                  TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp)),
          Expanded(child: Text(value, style: TextStyle(fontSize: 14.sp))),
        ],
      ),
    );
  }
}
