import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../../utils/custom_header.dart';
import '../../utils/ml_service.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AddPetScreen extends StatefulWidget {
  const AddPetScreen({super.key});

  @override
  State<AddPetScreen> createState() => _AddPetScreenState();
}

class _AddPetScreenState extends State<AddPetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _breedController = TextEditingController();
  final _ageController = TextEditingController();
  final _colorController = TextEditingController();
  final _specialMarksController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _ownerAddressController = TextEditingController();
  final _ownerPhoneController = TextEditingController();

  final ImagePicker _picker = ImagePicker();

  File? _imageFile;
  Uint8List? _webImage;

  bool _isLoading = false;
  bool _isVaccinated = false;

  @override
  void initState() {
    super.initState();
    _loadOwnerDetails();
  }

  Future<void> _loadOwnerDetails() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      if (user.displayName != null && user.displayName!.isNotEmpty) {
        _ownerNameController.text = user.displayName!;
      }
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists) {
          final data = doc.data();
          if (data != null) {
            if (data['name'] != null && data['name'].toString().isNotEmpty) {
              _ownerNameController.text = data['name'];
            }
            if (data['phone'] != null && data['phone'].toString().isNotEmpty) {
              _ownerPhoneController.text = data['phone'];
            }
            if (data['address'] != null && data['address'].toString().isNotEmpty) {
              _ownerAddressController.text = data['address'];
            }
          }
        }
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
    _ageController.dispose();
    _colorController.dispose();
    _specialMarksController.dispose();
    _ownerNameController.dispose();
    _ownerAddressController.dispose();
    _ownerPhoneController.dispose();
    super.dispose();
  }

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

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (pickedFile == null) return;

      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _webImage = bytes;
          _imageFile = null;
        });
      } else {
        setState(() {
          _imageFile = File(pickedFile.path);
          _webImage = null;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  Future<void> _savePet() async {
    if (!_formKey.currentState!.validate()) return;

    // ✅ Make image selection mandatory
    if (_imageFile == null && _webImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a photo of your pet.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      String? photoUrl;
      List<dynamic>? dominantColors;

     
      if (_imageFile != null || _webImage != null) {
        final uri = Uri.parse(
          'https://api.cloudinary.com/v1_1/dgzff9iz9/image/upload',
        );
        final request = http.MultipartRequest('POST', uri)
          ..fields['upload_preset'] = 'p6dxs498';

        if (kIsWeb && _webImage != null) {
          request.files.add(http.MultipartFile.fromBytes(
            'file',
            _webImage!,
            filename: '${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg',
          ));
        } else if (_imageFile != null) {
          request.files.add(await http.MultipartFile.fromPath(
            'file',
            _imageFile!.path,
          ));
        }

        final response = await request.send();
        final responseData = await response.stream.toBytes();
        final responseString = utf8.decode(responseData);

        if (response.statusCode == 200 || response.statusCode == 201) {
          final jsonMap = jsonDecode(responseString);
          photoUrl = jsonMap['secure_url'];
          final rawColors = jsonMap['colors'] as List<dynamic>?;

         
          if (rawColors != null && rawColors.isNotEmpty) {
            bool isTooDark = true;
            for (var colorEntry in rawColors) {
              final hex = (colorEntry is List) ? colorEntry[0] : colorEntry.toString();
              final rgb = _hexToRgb(hex.toString());
              if (rgb != null) {
                // If any dominant color has a brightness > 50, it's acceptable
                if (rgb[0] > 50 || rgb[1] > 50 || rgb[2] > 50) {
                  isTooDark = false;
                  break;
                }
              }
            }
            if (isTooDark) {
              throw Exception('The photo is too dark or blurry. Please choose a clearer photo of your pet.');
            }
            if (rawColors.length < 2) {
              throw Exception('The photo lacks detail. Please choose a photo where your pet is clearly visible.');
            }
          }

          dominantColors = rawColors?.map((c) => {
            'hex': c[0],
            'percent': c[1],
          }).toList();
        } else {
          String errorMsg = 'Failed to upload image to Cloudinary.';
          try {
            final errorJson = jsonDecode(responseString);
            errorMsg = errorJson['error']?['message'] ?? responseString;
          } catch (_) {}
          throw Exception(errorMsg);
        }
      }

      // Generate feature vector locally using MobileNetV2
      List<double>? featureVector;
      try {
        if (_imageFile != null) {
          featureVector = await mlService.getFeatureVector(_imageFile!);
        } else if (_webImage != null) {
          featureVector = await mlService.getFeatureVectorFromBytes(_webImage!);
        }
      } catch (e) {
        debugPrint('Feature vector generation failed: $e');
      }

      final petRef = FirebaseFirestore.instance.collection('pets').doc();

      await petRef.set({
        'ownerId': user.uid,
        'name': _nameController.text.trim(),
        'breed': _breedController.text.trim(),
        'age': int.parse(_ageController.text),
        'color': _colorController.text.trim(),
        'specialMarks': _specialMarksController.text.trim(),
        'isVaccinated': _isVaccinated,

       
        'photoUrl': photoUrl ?? '',
        'dominantColors': dominantColors,
        'featureVector': featureVector,

        'ownerName': _ownerNameController.text.trim().isNotEmpty 
            ? _ownerNameController.text.trim() 
            : (userDoc.data()?['name'] ?? user.displayName ?? ''),
        'ownerPhone': _ownerPhoneController.text.trim().isNotEmpty 
            ? _ownerPhoneController.text.trim() 
            : (userDoc.data()?['phone'] ?? ''),
        'ownerAddress': _ownerAddressController.text.trim(),
        'ownerEmail': user.email ?? '',
        'qrCodeData': 'PAWTNER:${petRef.id}',
        'createdAt': FieldValue.serverTimestamp(),
        'isLost': false,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pet added successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildImagePreview() {
    if (kIsWeb && _webImage != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16.r),
        child: Image.memory(
          _webImage!,
          fit: BoxFit.cover,
        ),
      );
    }

    if (!kIsWeb && _imageFile != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16.r),
        child: Image.file(
          _imageFile!,
          fit: BoxFit.cover,
        ),
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_a_photo, size: 60.r, color: Colors.grey[600]),
        SizedBox(height: 8.h),
        Text(
          'Tap to add pet photo',
          style: TextStyle(color: Colors.grey[600], fontSize: 16.sp),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomHeaderScreen(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                  'Add New Pet',
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
              child: Center(
                child: Container(
                  constraints: BoxConstraints(maxWidth: 700.w),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            height: 200.h,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24.r),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 20.r,
                                  offset: Offset(0, 10.h),
                                ),
                              ],
                            ),
                            child: _buildImagePreview(),
                          ),
                        ),
                        SizedBox(height: 32.h),
                        Container(
                          padding: EdgeInsets.all(24.r),
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
                              Text(
                                'Pet Details',
                                style: TextStyle(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              SizedBox(height: 24.h),
                              TextFormField(
                                controller: _nameController,
                                decoration: const InputDecoration(
                                  labelText: 'Pet Name',
                                  prefixIcon: Icon(Icons.pets, color: Color(0xFFFF6B35)),
                                ),
                                validator: (v) => v == null || v.isEmpty ? 'Enter pet name' : null,
                              ),
                              SizedBox(height: 16.h),
                              TextFormField(
                                controller: _breedController,
                                decoration: const InputDecoration(
                                  labelText: 'Breed',
                                  prefixIcon: Icon(Icons.category, color: Color(0xFFFF6B35)),
                                ),
                                validator: (v) => v == null || v.isEmpty ? 'Enter breed' : null,
                              ),
                              SizedBox(height: 16.h),
                              TextFormField(
                                controller: _ageController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Age',
                                  prefixIcon: Icon(Icons.cake, color: Color(0xFFFF6B35)),
                                ),
                                validator: (v) => v == null || int.tryParse(v) == null ? 'Enter valid age' : null,
                              ),
                              SizedBox(height: 16.h),
                              TextFormField(
                                controller: _colorController,
                                decoration: const InputDecoration(
                                  labelText: 'Color',
                                  prefixIcon: Icon(Icons.palette, color: Color(0xFFFF6B35)),
                                ),
                                validator: (v) => v == null || v.isEmpty ? 'Enter color' : null,
                              ),
                              SizedBox(height: 16.h),
                              TextFormField(
                                controller: _specialMarksController,
                                maxLines: 3,
                                decoration: const InputDecoration(
                                  labelText: 'Special Marks',
                                  prefixIcon: Icon(Icons.description, color: Color(0xFFFF6B35)),
                                ),
                                validator: (v) => v == null || v.isEmpty ? 'Enter marks' : null,
                              ),
                              SizedBox(height: 16.h),
                              SwitchListTile(
                                title: Text('Is the pet vaccinated?', style: TextStyle(fontSize: 14.sp)),
                                value: _isVaccinated,
                                onChanged: (bool value) {
                                  setState(() {
                                    _isVaccinated = value;
                                  });
                                },
                                activeThumbColor: const Color(0xFFFF6B35),
                                secondary: const Icon(Icons.health_and_safety, color: Color(0xFFFF6B35)),
                                contentPadding: EdgeInsets.zero,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 24.h),
                        Container(
                          padding: EdgeInsets.all(24.r),
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
                              Text(
                                'Owner Details',
                                style: TextStyle(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              SizedBox(height: 24.h),
                              TextFormField(
                                controller: _ownerNameController,
                                decoration: const InputDecoration(
                                  labelText: 'Owner Name',
                                  prefixIcon: Icon(Icons.person, color: Color(0xFFFF6B35)),
                                ),
                                validator: (v) => v == null || v.isEmpty ? 'Enter owner name' : null,
                              ),
                              SizedBox(height: 16.h),
                              TextFormField(
                                controller: _ownerPhoneController,
                                keyboardType: TextInputType.phone,
                                decoration: const InputDecoration(
                                  labelText: 'Phone Number',
                                  prefixIcon: Icon(Icons.phone, color: Color(0xFFFF6B35)),
                                ),
                                validator: (v) => v == null || v.isEmpty ? 'Enter phone number' : null,
                              ),
                              SizedBox(height: 16.h),
                              TextFormField(
                                controller: _ownerAddressController,
                                decoration: const InputDecoration(
                                  labelText: 'Address',
                                  prefixIcon: Icon(Icons.location_on, color: Color(0xFFFF6B35)),
                                ),
                                validator: (v) => v == null || v.isEmpty ? 'Enter address' : null,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 32.h),
                        SizedBox(
                          width: double.infinity,
                          height: 56.h,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _savePet,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF6B35),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16.r),
                              ),
                            ),
                            child: _isLoading
                                ? SizedBox(
                                    height: 20.h,
                                    width: 20.w,
                                    child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : Text('Save Pet', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        SizedBox(height: 40.h),
                      ],
                    ),
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