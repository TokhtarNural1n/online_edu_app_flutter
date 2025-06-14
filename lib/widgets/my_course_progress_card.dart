// lib/widgets/my_course_progress_card.dart

import 'package:flutter/material.dart';
import '../models/my_course_progress_info.dart';

class MyCourseProgressCard extends StatelessWidget {
  final MyCourseProgressInfo progressInfo;

  const MyCourseProgressCard({
    super.key,
    required this.progressInfo,
  });

  @override
  Widget build(BuildContext context) {
    final course = progressInfo.course;
    final progressPercent = progressInfo.progressPercent;
    final currentLessonNumber = progressInfo.lessonNumberToContinue;
    final nextLessonTitle = progressInfo.nextContentItem?.title ?? "Курс пройден!";

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      margin: EdgeInsets.zero,
      child: Column(
        children: [
          // --- Верхняя часть с картинкой и прогрессом ---
          Stack(
            children: [
              SizedBox(
                height: 150,
                width: double.infinity,
                child: (course.imageUrl.isNotEmpty)
                  ? Image.network(
                      course.imageUrl,
                      fit: BoxFit.cover,
                      color: Colors.black.withOpacity(0.5),
                      colorBlendMode: BlendMode.darken,
                    )
                  : Container(color: Colors.grey),
              ),
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '$currentLessonNumber УРОК',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          _buildProgressCircle(context, progressPercent),
                        ],
                      ),
                      const Spacer(),
                      Row(
                        children: const [
                          Icon(Icons.play_circle, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text('Продолжить урок', style: TextStyle(color: Colors.white, fontSize: 14)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        nextLessonTitle,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // --- Нижняя часть с информацией о курсе ---
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                // --- ИСПРАВЛЕНО: Возвращаем простую иконку ---
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 40,
                    height: 40,
                    color: Colors.grey.shade200,
                    child: Icon(Icons.school, color: Colors.grey.shade400),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course.category.toUpperCase(),
                        style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      Text(course.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.star, color: Colors.orange, size: 16),
                const SizedBox(width: 4),
                Text('${course.rating} (${course.reviewCount})'),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildProgressCircle(BuildContext context, double progressPercent) {
    return SizedBox(
      width: 40,
      height: 40,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CircularProgressIndicator(
            value: progressPercent / 100,
            strokeWidth: 3,
            backgroundColor: Colors.white.withOpacity(0.3),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
          ),
          Center(
            child: Text(
              '${progressPercent.toInt()}%',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}