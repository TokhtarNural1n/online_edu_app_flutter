// lib/widgets/course_card.dart
import 'package:flutter/material.dart';
import '../models/course_model.dart';

class CourseCard extends StatelessWidget {
  final Course course;
  final VoidCallback onPressed;

  const CourseCard({
    super.key,
    required this.course,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Картинка курса
            SizedBox(
              height: 160,
              width: double.infinity,
              child: Image.network(
                course.imageUrl.isNotEmpty ? course.imageUrl : 'https://placehold.co/600x400/E0E0E0/BDBDBD?text=No+Image',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.school_outlined, color: Colors.grey, size: 40),
                ),
              ),
            ),
            // Информация о курсе
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.title,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  // --- ОБНОВЛЕННЫЙ БЛОК ИНФОРМАЦИИ ---
                  _buildInfoRow(context, Icons.person_outline, course.author),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildInfoRow(context, Icons.library_books_outlined, '${course.moduleCount} бөлім'),
                      const SizedBox(width: 16),
                      _buildInfoRow(context, Icons.play_circle_outline, '${course.lessonCount} сабақ'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Вспомогательный виджет для строки с иконкой и текстом
  Widget _buildInfoRow(BuildContext context, IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey.shade600, size: 16),
        const SizedBox(width: 8),
        Text(text, style: TextStyle(color: Colors.grey.shade700, fontSize: 14)),
      ],
    );
  }
}