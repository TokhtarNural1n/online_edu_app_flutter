// lib/models/continue_learning_info.dart

import 'course_model.dart';
import 'module_model.dart';
import 'content_item_model.dart';

class ContinueLearningInfo {
  final Course course;
  final Module module;
  final ContentItem contentItem;

  ContinueLearningInfo({
    required this.course,
    required this.module,
    required this.contentItem,
  });
}