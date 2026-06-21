import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/utils/helpers.dart';

class AppUser {
  final String  id;
  final String  name;        // owner name
  final String  shopName;
  final String  email;
  final String  phone;
  final String  role;
  final bool    profileCompleted;
  final bool    isActive;
  final String? fcmToken;
  final String? photoUrl;
  final DateTime createdAt;

  const AppUser({
    required this.id,
    required this.name,
    required this.shopName,
    required this.email,
    required this.phone,
    required this.role,
    required this.profileCompleted,
    required this.isActive,
    this.fcmToken,
    this.photoUrl,
    required this.createdAt,
  });

  bool get isAdmin => role == 'admin';
  bool get isUser  => role == 'user';

  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return AppUser(
      id:               doc.id,
      name:             d['name']             ?? '',
      shopName:         d['shopName']         ?? '',
      email:            d['email']            ?? '',
      phone:            d['phone']            ?? '',
      role:             d['role']             ?? 'user',
      profileCompleted: d['profileCompleted'] ?? false,
      isActive:         d['isActive']         ?? true,
      fcmToken:         d['fcmToken'],
      photoUrl:         d['photoUrl'],
      createdAt:        tsToDate(d['createdAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'name':             name,
    'shopName':         shopName,
    'email':            email,
    'phone':            phone,
    'role':             role,
    'profileCompleted': profileCompleted,
    'isActive':         isActive,
    'fcmToken':         fcmToken,
    'photoUrl':         photoUrl,
    'createdAt':        FieldValue.serverTimestamp(),
  };

  AppUser copyWith({
    String?  name,
    String?  shopName,
    String?  phone,
    String?  photoUrl,
    bool?    profileCompleted,
    bool?    isActive,
    String?  fcmToken,
  }) =>
      AppUser(
        id:               id,
        name:             name             ?? this.name,
        shopName:         shopName         ?? this.shopName,
        email:            email,
        phone:            phone            ?? this.phone,
        role:             role,
        profileCompleted: profileCompleted ?? this.profileCompleted,
        isActive:         isActive         ?? this.isActive,
        fcmToken:         fcmToken         ?? this.fcmToken,
        photoUrl:         photoUrl         ?? this.photoUrl,
        createdAt:        createdAt,
      );
}
