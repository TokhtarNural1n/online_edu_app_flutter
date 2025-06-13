import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/course_model.dart';
import '../view_models/course_view_model.dart';
import '../widgets/course_card.dart';
import '../widgets/custom_dropdown.dart';
import 'course_detail_screen.dart';

class CoursesScreen extends StatelessWidget {
  const CoursesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Курсы'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // --- Блок с фильтрами пока остается без изменений ---
            Row(
              children: [
                Expanded(child: OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.all_inclusive), label: const Text('Bce'), style: OutlinedButton.styleFrom(foregroundColor: Colors.white, backgroundColor: Colors.blue))),
                const SizedBox(width: 10),
                Expanded(child: OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.bookmark_border), label: const Text('Сохраненные'), style: OutlinedButton.styleFrom(foregroundColor: Colors.black54, backgroundColor: Colors.grey.shade200))),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: CustomDropdown(hint: 'Категории', items: const ['IT', 'Дизайн', 'Маркетинг'])),
                const SizedBox(width: 10),
                Expanded(child: CustomDropdown(hint: 'Язык', items: const ['Казахский', 'Русский', 'Английский'])),
              ],
            ),
            const SizedBox(height: 20),
            
            // --- Динамический список курсов ---
            Expanded(
              child: FutureBuilder<List<Course>>(
                // Вызываем нашу функцию загрузки из ViewModel
                future: Provider.of<CourseViewModel>(context, listen: false).fetchCourses(),
                builder: (context, snapshot) {
                  // Пока данные грузятся, показываем индикатор
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  // Если произошла ошибка
                  if (snapshot.hasError) {
                    return Center(child: Text('Произошла ошибка: ${snapshot.error}'));
                  }
                  // Если данных нет
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('Курсов пока нет.'));
                  }

                  // Если все хорошо и данные есть, строим список
                  final courses = snapshot.data!;
                  return ListView.builder(
                    itemCount: courses.length,
                    itemBuilder: (context, index) {
                      final course = courses[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: CourseCard(
                          course: course,
                          // 2. ИЗМЕНИТЕ ЭТОТ БЛОК
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CourseDetailScreen(course: course),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}