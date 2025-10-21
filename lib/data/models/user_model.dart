import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String? photoUrl;
  final String? phoneNumber;
  final DateTime createdAt;
  final DateTime? lastLogin;
  final int uploadedVideosCount;
  final int uploadedShortsCount;
  final int subscribersCount;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.photoUrl,
    this.phoneNumber,
    required this.createdAt,
    this.lastLogin,
    this.uploadedVideosCount = 0,
    this.uploadedShortsCount = 0,
    this.subscribersCount = 0,
  });

  // From Firestore
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      photoUrl: data['photoUrl'],
      phoneNumber: data['phoneNumber'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastLogin: (data['lastLogin'] as Timestamp?)?.toDate(),
      uploadedVideosCount: data['uploadedVideosCount'] ?? 0,
      uploadedShortsCount: data['uploadedShortsCount'] ?? 0,
      subscribersCount: data['subscribersCount'] ?? 0,
    );
  }

  // To Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'phoneNumber': phoneNumber,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLogin': lastLogin != null ? Timestamp.fromDate(lastLogin!) : null,
      'uploadedVideosCount': uploadedVideosCount,
      'uploadedShortsCount': uploadedShortsCount,
      'subscribersCount': subscribersCount,
    };
  }

  // Copy with
  UserModel copyWith({
    String? name,
    String? email,
    String? photoUrl,
    String? phoneNumber,
    DateTime? lastLogin,
    int? uploadedVideosCount,
    int? uploadedShortsCount,
    int? subscribersCount,
  }) {
    return UserModel(
      uid: uid,
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      createdAt: createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      uploadedVideosCount: uploadedVideosCount ?? this.uploadedVideosCount,
      uploadedShortsCount: uploadedShortsCount ?? this.uploadedShortsCount,
      subscribersCount: subscribersCount ?? this.subscribersCount,
    );
  }
}

