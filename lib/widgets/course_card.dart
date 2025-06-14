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
        shadowColor: Colors.black.withOpacity(1.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(
              course.imageUrl.isNotEmpty
                  ? course.imageUrl
                  : 'https://placehold.co/600x400/E0E0E0/BDBDBD?text=No+Image',
              height: 160,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                  height: 160,
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.image_not_supported, color: Colors.grey)),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.title,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    // ИЗМЕНЕНИЕ: Выравниваем по нижнему краю, чтобы ценник "опустился"
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Левая колонка с информацией
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoRow(context, Icons.person_outline, course.author),
                          const SizedBox(height: 10),
                          _buildInfoRow(context, Icons.star_border_outlined,
                              '${course.rating} (${course.reviewCount} отзывов)'),
                          const SizedBox(height: 10),
                          _buildInfoRow(context, Icons.timer_outlined,
                              '${course.totalDurationMinutes} мин.'),
                        ],
                      ),
                      
                      // --- ИЗМЕНЕНИЕ: Правая колонка с ценами ---
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Возвращаем старую цену (если она есть)
                          if (course.originalPrice.isNotEmpty)
                            Text(
                              course.originalPrice,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          // "Чип" с новой ценой
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              course.price,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey.shade600, size: 16),
        const SizedBox(width: 8),
        Text(text,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 14)),
      ],
    );
  }
}