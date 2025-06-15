// lib/models/enrollment_detail_model.dart

import 'course_model.dart';
import 'enrollment_model.dart';

// Этот класс-обертка объединяет данные о курсе и о том, как он был получен
class EnrollmentDetail {
  final Course course;
  final Enrollment enrollment;

  EnrollmentDetail({required this.course, required this.enrollment});
}