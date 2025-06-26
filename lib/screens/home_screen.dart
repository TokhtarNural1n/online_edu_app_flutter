// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart'; // <-- НОВЫЙ ИМПОРТ
import '../models/course_model.dart';
import '../models/news_model.dart';
import '../view_models/course_view_model.dart';
import '../view_models/news_view_model.dart';
import '../widgets/course_card.dart';
import '../widgets/service_icon.dart';
import 'course_detail_screen.dart';
import 'news_detail_screen.dart';
import 'news_feed_screen.dart';
import 'courses_screen.dart';
import 'my_tests_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<NewsArticle>> _newsFuture;
  late Future<List<Course>> _coursesFuture;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() {
    final newsViewModel = Provider.of<NewsViewModel>(context, listen: false);
    final courseViewModel = Provider.of<CourseViewModel>(context, listen: false);
    setState(() {
      _newsFuture = newsViewModel.fetchLatestNews(limit: 5);
      _coursesFuture = courseViewModel.fetchPopularCourses(limit: 3);
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> services = [
  
      {'icon': Icons.emoji_events_outlined, 'label': 'Марафоны', 'onTap': () { /* TODO */ }},
      {'icon': Icons.assignment_outlined, 'label': 'Тесты', 'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyTestsScreen()))},
      {'icon': Icons.dynamic_feed_outlined, 'label': 'Лента', 'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NewsFeedScreen()))},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Басты бет'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async => _refreshData(),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              _buildNewsCarousel(),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text('Сервисы', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 16),
              GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 0.9),
                itemCount: services.length,
                itemBuilder: (context, index) {
                  final service = services[index];
                  return GestureDetector(onTap: service['onTap'], child: ServiceIcon(icon: service['icon'], label: service['label']));
                },
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                     Text('Популярные курсы', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                    TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CoursesScreen())), child: const Text('Все'))
                  ],
                ),
              ),
              const SizedBox(height: 15),
              _buildCoursesList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNewsCarousel() {
    return FutureBuilder<List<NewsArticle>>(
      future: _newsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const SizedBox(height: 180, child: Center(child: CircularProgressIndicator()));
        if (!snapshot.hasData || snapshot.data!.isEmpty) return const SizedBox.shrink();
        final newsList = snapshot.data!;
        return SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: newsList.length,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemBuilder: (context, index) => _buildNewsBannerCard(context, newsList[index]),
          ),
        );
      },
    );
  }

  Widget _buildCoursesList() {
    return FutureBuilder<List<Course>>(
      future: _coursesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) return const Padding(padding: EdgeInsets.symmetric(horizontal: 16.0), child: Text('Не удалось загрузить курсы.'));
        final popularCourses = snapshot.data!;
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: popularCourses.length,
          itemBuilder: (context, index) => Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: CourseCard(
              course: popularCourses[index],
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => CourseDetailScreen(course: popularCourses[index]))),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNewsBannerCard(BuildContext context, NewsArticle article) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => NewsDetailScreen(article: article)));
      },
      child: Container(
        width: MediaQuery.of(context).size.width * 0.75,
        margin: const EdgeInsets.only(right: 16),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(16)),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // --- ИЗМЕНЕНИЕ: Используем CachedNetworkImage ---
            if (article.thumbnailUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CachedNetworkImage(
                  imageUrl: article.thumbnailUrl, // Используем thumbnail для скорости
                  fit: BoxFit.cover,
                  placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                ),
              ),
            // Контейнер для градиента и текста
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                  begin: Alignment.bottomCenter,
                  end: Alignment.center,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Text(
                    article.title,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}