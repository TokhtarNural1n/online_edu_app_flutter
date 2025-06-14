// lib/screens/courses_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/course_model.dart';
import '../models/my_course_progress_info.dart'; // <-- Новый импорт
import '../view_models/course_view_model.dart';
import '../widgets/course_card.dart';
import '../widgets/my_course_progress_card.dart';
import 'course_detail_screen.dart';

class CoursesScreen extends StatelessWidget {
  const CoursesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final courseViewModel = Provider.of<CourseViewModel>(context, listen: false);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Курсы'),
          bottom: TabBar(
            indicatorColor: Theme.of(context).primaryColor,
            labelColor: Theme.of(context).primaryColor,
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(text: 'Все курсы'),
              Tab(text: 'Мои курсы'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Вкладка "Все курсы"
            _buildAllCoursesList(context, courseViewModel),
            // Вкладка "Мои курсы"
            _buildMyCoursesList(context, courseViewModel),
          ],
        ),
      ),
    );
  }

  // Виджет для вкладки "Все курсы" (без изменений)
  Widget _buildAllCoursesList(BuildContext context, CourseViewModel courseViewModel) {
    return FutureBuilder<List<Course>>(
      future: courseViewModel.fetchCourses(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('Доступных курсов пока нет.'));
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
    );
  }

  // --- ИЗМЕНЕННЫЙ ВИДЖЕТ ДЛЯ ВКЛАДКИ "МОИ КУРСЫ" ---
  Widget _buildMyCoursesList(BuildContext context, CourseViewModel courseViewModel) {
    // Теперь используем FutureBuilder с новым типом и новой функцией
    return FutureBuilder<List<MyCourseProgressInfo>>(
      future: courseViewModel.fetchMyCoursesWithProgress(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Произошла ошибка: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('Вы еще не записаны ни на один курс.'));
        }

        final progressInfoList = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: progressInfoList.length,
          itemBuilder: (context, index) {
            final progressInfo = progressInfoList[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: GestureDetector(
                onTap: () {
                   Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => CourseDetailScreen(course: progressInfo.course)),
                  );
                },
                // Передаем весь объект с реальными данными в карточку
                child: MyCourseProgressCard(
                  progressInfo: progressInfo,
                ),
              ),
            );
          },
        );
      },
    );
  }
}