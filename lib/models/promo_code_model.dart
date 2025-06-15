// lib/models/promo_code_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class PromoCode {
  final String id; // Сам промокод
  final String courseId;
  final bool isUsed;
  final Timestamp createdAt;
  final String? usedBy;
  final Timestamp? usedAt;

  PromoCode({
    required this.id,
    required this.courseId,
    required this.isUsed,
    required this.createdAt,
    this.usedBy,
    this.usedAt,
  });

  factory PromoCode.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return PromoCode(
      id: doc.id,
      courseId: data['courseId'] ?? '',
      isUsed: data['isUsed'] ?? false,
      createdAt: data['createdAt'] ?? Timestamp.now(),
      usedBy: data['usedBy'],
      usedAt: data['usedAt'],
    );
  }
}