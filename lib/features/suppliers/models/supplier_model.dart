import 'package:cloud_firestore/cloud_firestore.dart';

class SupplierModel {
  final String id;
  final String name;
  final String contactPerson;
  final String phone;
  final String email;
  final String address;
  final String city;
  final String state;
  final String gstin;
  final String? logoUrl;
  final bool isActive;
  final DateTime createdAt;

  const SupplierModel({
    required this.id,
    required this.name,
    required this.contactPerson,
    required this.phone,
    required this.email,
    required this.address,
    required this.city,
    required this.state,
    required this.gstin,
    this.logoUrl,
    this.isActive = true,
    required this.createdAt,
  });

  factory SupplierModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return SupplierModel(
      id: doc.id,
      name: d['name'] ?? '',
      contactPerson: d['contactPerson'] ?? '',
      phone: d['phone'] ?? '',
      email: d['email'] ?? '',
      address: d['address'] ?? '',
      city: d['city'] ?? '',
      state: d['state'] ?? '',
      gstin: d['gstin'] ?? '',
      logoUrl: d['logoUrl'],
      isActive: d['isActive'] ?? true,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'contactPerson': contactPerson,
        'phone': phone,
        'email': email,
        'address': address,
        'city': city,
        'state': state,
        'gstin': gstin,
        'logoUrl': logoUrl,
        'isActive': isActive,
        'createdAt': FieldValue.serverTimestamp(),
      };
}
