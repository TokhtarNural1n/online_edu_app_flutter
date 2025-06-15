// lib/models/enrollment_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

// Эта модель описывает документ о зачислении на курс
class Enrollment {
  final String courseId;
  final Timestamp enrolledAt;
  final String? grantMethod; // 'admin' или null
  final String? activatedWithCode; // сам промокод или null

  Enrollment({
    required this.courseId,
    required this.enrolledAt,
    this.grantMethod,
    this.activatedWithCode,
  });

  factory Enrollment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Enrollment(
      courseId: doc.id,
      enrolledAt: data['enrolledAt'] ?? Timestamp.now(),
      grantMethod: data['grantMethod'],
      activatedWithCode: data['activatedWithCode'],
    );
  }
}