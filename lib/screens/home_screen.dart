import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/course_model.dart';
import '../view_models/course_view_model.dart';
import '../widgets/service_icon.dart';
import '../widgets/course_card.dart';
import 'course_detail_screen.dart';
import 'news_feed_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Создаем список сервисов с их действиями
    final List<Map<String, dynamic>> services = [
      {'icon': Icons.school_outlined, 'label': 'Курсы', 'onTap': () { /* TODO: Navigate to All Courses */ }},
      {'icon': Icons.emoji_events_outlined, 'label': 'Марафоны', 'onTap': () {}},
      {'icon': Icons.assignment_outlined, 'label': 'Тесты', 'onTap': () {}},
      {'icon': Icons.dynamic_feed_outlined, 'label': 'Лента', 'onTap': () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const NewsFeedScreen()));
      }},
      {'icon': Icons.account_balance_outlined, 'label': 'ВУЗы', 'onTap': () {}},
      {'icon': Icons.business_center_outlined, 'label': 'Специальности', 'onTap': () {}},
    ];

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.sort), onPressed: () {}),
        actions: [
          IconButton(icon: const Icon(Icons.language, color: Colors.blueAccent), onPressed: () {}),
          IconButton(icon: const Icon(Icons.notifications_outlined, color: Colors.blueAccent), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ... (Верхняя часть без изменений) ...
              
              const SizedBox(height: 24),
              const Text('Сервисы', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              
              // --- ИСПРАВЛЕННЫЙ GRIDVIEW ---
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent( // <-- ИСПРАВЛЕНА ОПЕЧАТКА ЗДЕСЬ
                  maxCrossAxisExtent: 120.0,
                  mainAxisSpacing: 10.0,
                  crossAxisSpacing: 10.0,
                  childAspectRatio: 0.9,
                ),
                itemCount: services.length,
                itemBuilder: (context, index) {
                  final service = services[index];
                  return GestureDetector(
                    onTap: service['onTap'],
                    child: ServiceIcon(icon: service['icon'], label: service['label']),
                  );
                },
              ),
              // --- КОНЕЦ ИСПРАВЛЕНИЯ ---

              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   const Text('Популярные курсы', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  CircleAvatar(backgroundColor: Colors.blue.withOpacity(0.1), child: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.blue))
                ],
              ),
              const SizedBox(height: 15),
              // Динамический список курсов
              FutureBuilder<List<Course>>(
                future: Provider.of<CourseViewModel>(context, listen: false).fetchMyCourses(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('Не удалось загрузить популярные курсы.'));
                  }
                  final popularCourses = snapshot.data!;
                  return Column(
                    children: popularCourses.map((course) => Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: CourseCard(
                        course: course,
                        onPressed: () {
                           Navigator.push(context, MaterialPageRoute(builder: (context) => CourseDetailScreen(course: course)));
                        },
                      ),
                    )).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
