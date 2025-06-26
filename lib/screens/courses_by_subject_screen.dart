// lib/screens/courses_by_subject_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/course_model.dart';
import '../models/subject_model.dart';
import '../view_models/course_view_model.dart';
import '../widgets/course_card.dart';
import 'course_detail_screen.dart';

class CoursesBySubjectScreen extends StatelessWidget {
  final Subject subject;

  const CoursesBySubjectScreen({super.key, required this.subject});

  @override
  Widget build(BuildContext context) {
    final courseViewModel = Provider.of<CourseViewModel>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text(subject.name),
      ),
      body: FutureBuilder<List<Course>>(
        // Вызываем новый метод, который мы сейчас добавим в ViewModel
        future: courseViewModel.fetchCoursesBySubject(subject.name),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Ошибка загрузки курсов: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Курсы по этому предмету еще не добавлены.'));
          }

          final courses = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: courses.length,
            itemBuilder: (context, index) {
              final course = courses[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: CourseCard(
                  course: course,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => CourseDetailScreen(course: course)),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}