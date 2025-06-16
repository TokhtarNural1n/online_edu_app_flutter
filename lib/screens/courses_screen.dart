import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/course_model.dart';
import '../view_models/course_view_model.dart';
import '../widgets/course_card.dart';
import '../widgets/my_course_progress_card.dart';
import '../models/my_course_progress_info.dart';
import 'course_detail_screen.dart';

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  // --- НОВЫЕ ПОЛЯ ДЛЯ ОБНОВЛЕНИЯ ---
  late Future<List<Course>> _allCoursesFuture;
  late Future<List<MyCourseProgressInfo>> _myCoursesFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final courseViewModel = Provider.of<CourseViewModel>(context, listen: false);
    setState(() {
      _allCoursesFuture = courseViewModel.fetchCourses();
      _myCoursesFuture = courseViewModel.fetchMyCoursesWithProgress();
    });
  }

  // --- НОВЫЙ МЕТОД ДЛЯ ОБНОВЛЕНИЯ ---
  Future<void> _refresh() async {
    _loadData();
    // Мы можем дождаться завершения обоих запросов
    await Future.wait([_allCoursesFuture, _myCoursesFuture]);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Курсы'),
          bottom: const TabBar(tabs: [Tab(text: 'Все курсы'), Tab(text: 'Мои курсы')]),
        ),
        body: TabBarView(
          children: [
            _buildAllCoursesList(),
            _buildMyCoursesList(),
          ],
        ),
      ),
    );
  }

  Widget _buildAllCoursesList() {
    return FutureBuilder<List<Course>>(
      future: _allCoursesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text('Доступных курсов пока нет.'));
        
        final courses = snapshot.data!;
        // Оборачиваем ListView в RefreshIndicator
        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: courses.length,
            itemBuilder: (context, index) {
              final course = courses[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: CourseCard(
                  course: course,
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => CourseDetailScreen(course: course))),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildMyCoursesList() {
    return FutureBuilder<List<MyCourseProgressInfo>>(
      future: _myCoursesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text('Вы еще не записаны ни на один курс.'));
        
        final coursesInfo = snapshot.data!;
        // Оборачиваем ListView в RefreshIndicator
        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: coursesInfo.length,
            itemBuilder: (context, index) {
              final info = coursesInfo[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => CourseDetailScreen(course: info.course))),
                  child: MyCourseProgressCard(progressInfo: info),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
