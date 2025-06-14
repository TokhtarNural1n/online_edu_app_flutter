// lib/models/my_course_progress_info.dart

import 'package:online_edu_app_flutter/models/course_model.dart';
import 'package:online_edu_app_flutter/models/content_item_model.dart';

/// Этот класс объединяет информацию о курсе и прогрессе пользователя по нему.
class MyCourseProgressInfo {
  final Course course;
  final double progressPercent; // Прогресс в процентах (от 0.0 до 100.0)
  final int lessonNumberToContinue; // Номер следующего урока (напр. "7" для "7 УРОК")
  final ContentItem? nextContentItem; // Сам следующий урок, тест или null, если все пройдено

  MyCourseProgressInfo({
    required this.course,
    required this.progressPercent,
    required this.lessonNumberToContinue,
    this.nextContentItem,
  });
}