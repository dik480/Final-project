import 'package:cloud_firestore/cloud_firestore.dart';

class PetModel {
  final String id;
  final String ownerId;
  final String name;
  final String breed;
  final int age;
  final String color;
  final String specialMarks;
  final String photoUrl;
  final String ownerName;
  final String ownerPhone;
  final String ownerEmail;
  final String qrCodeData;
  final DateTime createdAt;
  final bool isLost;

  final List<dynamic>? dominantColors;

  PetModel({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.breed,
    required this.age,
    required this.color,
    required this.specialMarks,
    required this.photoUrl,
    required this.ownerName,
    required this.ownerPhone,
    required this.ownerEmail,
    required this.qrCodeData,
    required this.createdAt,
    this.isLost = false,
    this.dominantColors,
  });

  factory PetModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return PetModel(
      id: doc.id,
      ownerId: data['ownerId'] ?? '',
      name: data['name'] ?? '',
      breed: data['breed'] ?? '',
      age: data['age'] ?? 0,
      color: data['color'] ?? '',
      specialMarks: data['specialMarks'] ?? '',
      photoUrl: data['photoUrl'] ?? '',
      ownerName: data['ownerName'] ?? '',
      ownerPhone: data['ownerPhone'] ?? '',
      ownerEmail: data['ownerEmail'] ?? '',
      qrCodeData: data['qrCodeData'] ?? '',
      createdAt: (data['createdAt'] is Timestamp) 
          ? (data['createdAt'] as Timestamp).toDate() 
          : DateTime.now(),
      isLost: data['isLost'] ?? false,
      dominantColors: data['dominantColors'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'ownerId': ownerId,
      'name': name,
      'breed': breed,
      'age': age,
      'color': color,
      'specialMarks': specialMarks,
      'photoUrl': photoUrl,
      'ownerName': ownerName,
      'ownerPhone': ownerPhone,
      'ownerEmail': ownerEmail,
      'qrCodeData': qrCodeData,
      'createdAt': Timestamp.fromDate(createdAt),
      'isLost': isLost,
      'dominantColors': dominantColors,
    };
  }
}

class ScanRecord {
  final String id;
  final String petId;
  final String scannedBy;
  final double latitude;
  final double longitude;
  final String address;
  final DateTime scannedAt;

  ScanRecord({
    required this.id,
    required this.petId,
    required this.scannedBy,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.scannedAt,
  });

  factory ScanRecord.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ScanRecord(
      id: doc.id,
      petId: data['petId'] ?? '',
      scannedBy: data['scannedBy'] ?? 'Anonymous',
      latitude: data['latitude'] ?? 0.0,
      longitude: data['longitude'] ?? 0.0,
      address: data['address'] ?? '',
      scannedAt: (data['scannedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'petId': petId,
      'scannedBy': scannedBy,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'scannedAt': Timestamp.fromDate(scannedAt),
    };
  }
}