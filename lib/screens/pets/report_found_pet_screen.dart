import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/custom_header.dart';

class ReportFoundPetScreen extends StatefulWidget {
  final File? imageFile;
  const ReportFoundPetScreen({super.key, this.imageFile});

  @override
  State<ReportFoundPetScreen> createState() => _ReportFoundPetScreenState();
}

class _ReportFoundPetScreenState extends State<ReportFoundPetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _breedController = TextEditingController();
  final _colorController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _finderNameController = TextEditingController();
  final _finderPhoneController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  void _loadUser() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _finderNameController.text = user.displayName ?? '';
    }
  }

  @override
  void dispose() {
    _breedController.dispose();
    _colorController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _finderNameController.dispose();
    _finderPhoneController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;
    if (widget.imageFile == null) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No image to upload.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Upload to Cloudinary
      String? photoUrl;
      final uri = Uri.parse('https://api.cloudinary.com/v1_1/dgzff9iz9/image/upload');
      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = 'p6dxs498'
        ..files.add(await http.MultipartFile.fromPath('file', widget.imageFile!.path));

      final response = await request.send();
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = await response.stream.toBytes();
        final jsonMap = jsonDecode(String.fromCharCodes(responseData));
        photoUrl = jsonMap['secure_url'];
      } else {
        throw Exception('Failed to upload image.');
      }

      // 2. Save to Firestore
      await FirebaseFirestore.instance.collection('found_pets').add({
        'photoUrl': photoUrl,
        'breed': _breedController.text.trim(),
        'color': _colorController.text.trim(),
        'description': _descriptionController.text.trim(),
        'locationFound': _locationController.text.trim(),
        'finderName': _finderNameController.text.trim(),
        'finderPhone': _finderPhoneController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'reporterId': FirebaseAuth.instance.currentUser?.uid,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report posted successfully!')),
        );
        Navigator.pop(context); // Back to ResultScreen
        Navigator.pop(context); // Back to ScanPetScreen
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
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
                            color: Colors.black.withValues(alpha: 0.03),
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
                            color: Colors.black.withValues(alpha: 0.03),
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
          ),
        ],
      ),
    );
  }
}
