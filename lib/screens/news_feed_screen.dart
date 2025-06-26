import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/news_model.dart';
import '../view_models/news_view_model.dart';
import '../widgets/news_card_v2.dart';
import 'news_detail_screen.dart';

class NewsFeedScreen extends StatelessWidget {
  const NewsFeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Используем DefaultTabController для управления верхними вкладками
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Лента'),
          // Вкладки в AppBar
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Жаңа'),
              Tab(text: 'Танымал'),
              Tab(text: 'Менікі'),
            ],
          ),
        ),
        body: Column(
          children: [
            // Горизонтальный список с фильтрами-чипами
            SizedBox(
              height: 60,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                children: [
                  _buildFilterChip(context, 'Барлығы', isSelected: true),
                  _buildFilterChip(context, 'Мотивация'),
                  _buildFilterChip(context, 'Хабарландыру'),
                  _buildFilterChip(context, 'Пайдалы'),
                ],
              ),
            ),
            // Основной список новостей
            Expanded(
              child: FutureBuilder<List<NewsArticle>>(
                future: Provider.of<NewsViewModel>(context, listen: false).fetchNewsPaginated(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Ошибка: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('Новостей пока нет.'));
                  }

                  final newsList = snapshot.data!;
                  return ListView.builder(
                    itemCount: newsList.length,
                    itemBuilder: (context, index) {
                      final article = newsList[index];
                      return NewsCardV2(
                        article: article,
                        onTap: () {
                          // Переход на детальный экран
                          Navigator.push(context, MaterialPageRoute(builder: (_) => NewsDetailScreen(article: article)));
                        },
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

  // Вспомогательный виджет для создания чипа-фильтра
  Widget _buildFilterChip(BuildContext context, String label, {bool isSelected = false}) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Chip(
        label: Text(label),
        backgroundColor: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade200,
        labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87),
      ),
    );
  }
}
