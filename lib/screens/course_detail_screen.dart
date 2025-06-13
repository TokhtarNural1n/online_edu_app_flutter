import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/course_model.dart';
import '../view_models/course_view_model.dart';

class CourseDetailScreen extends StatelessWidget {
  final Course course;

  const CourseDetailScreen({super.key, required this.course});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(course.title),
      ),
      body: FutureBuilder<Course>(
        future: Provider.of<CourseViewModel>(context, listen: false).fetchCourseDetails(course.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _buildNoAccessView(context, course: course);
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('Курс не найден.'));
          }
          final detailedCourse = snapshot.data!;
          return _buildFullCourseView(detailedCourse);
        },
      ),
    );
  }

  Widget _buildFullCourseView(Course course) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.network(course.imageUrl, width: double.infinity, height: 250, fit: BoxFit.cover),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(course.category.toUpperCase(), style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(course.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.timer_outlined, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text('${course.totalDurationMinutes} мин.'),
                    const SizedBox(width: 16),
                    const Icon(Icons.star, size: 16, color: Colors.orange),
                    const SizedBox(width: 4),
                    Text('${course.rating} (${course.reviewCount})'),
                  ],
                ),
                const Divider(height: 40),
                const Text('Программа курса', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: course.modules.length,
            itemBuilder: (context, index) {
              final module = course.modules[index];
              return ExpansionTile(
                title: Text(module.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${module.lectureCount} лекция • ${module.testCount} тест'),
                children: module.lessons.map((lesson) {
                  return ListTile(
                    leading: const Icon(Icons.play_circle_outline, color: Colors.grey),
                    title: Text(lesson.title),
                    trailing: Text(lesson.duration),
                    onTap: () { /* TODO: Переход на экран урока */ },
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildNoAccessView(BuildContext context, {required Course course}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.lock_outline, size: 80, color: Colors.grey),
          const SizedBox(height: 24),
          const Text(
            'Доступ к материалам курса закрыт',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            'Чтобы получить доступ ко всем лекциям и материалам, вам необходимо приобрести этот курс или получить доступ от администратора.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
            ),
            child: const Text('Приобрести курс'),
          ),
        ],
      ),
    );
  }
}
