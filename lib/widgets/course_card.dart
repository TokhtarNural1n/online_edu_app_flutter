import 'package:flutter/material.dart';
import '../models/course_model.dart'; // Импортируем нашу модель

class CourseCard extends StatelessWidget {
  final Course course; // Теперь принимаем объект Course
  final VoidCallback onPressed;

  const CourseCard({
    super.key,
    required this.course,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias, // Чтобы изображение не вылезало за скругленные углы
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.network(
            course.imageUrl, // Используем данные из модели
            height: 150,
            width: double.infinity,
            fit: BoxFit.cover,
            // Виджет-заглушка на случай ошибки загрузки изображения
            errorBuilder: (context, error, stackTrace) =>
              Container(height: 150, color: Colors.grey.shade300, child: const Icon(Icons.image_not_supported)),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(course.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                Text(course.author, style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                         Text(
                          course.originalPrice,
                          style: const TextStyle(
                              color: Colors.grey,
                              decoration: TextDecoration.lineThrough),
                        ),
                        Text(course.price, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: onPressed,
                      child: const Text('Подробнее'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade300, foregroundColor: Colors.white),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}