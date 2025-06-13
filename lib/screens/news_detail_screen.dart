import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/news_model.dart';
import '../view_models/news_view_model.dart';

// 1. Превращаем в StatefulWidget
class NewsDetailScreen extends StatefulWidget {
  final NewsArticle article;

  const NewsDetailScreen({super.key, required this.article});

  @override
  State<NewsDetailScreen> createState() => _NewsDetailScreenState();
}

class _NewsDetailScreenState extends State<NewsDetailScreen> {

  // 2. Вызываем метод увеличения счетчика один раз при инициализации экрана
  @override
  void initState() {
    super.initState();
    // Мы не слушаем изменения, нам нужно только один раз вызвать метод
    final newsViewModel = Provider.of<NewsViewModel>(context, listen: false);
    newsViewModel.incrementViewCount(widget.article.id);
  }

  @override
  Widget build(BuildContext context) {
    // Теперь используем widget.article для доступа к данным
    final article = widget.article;
    final formattedDate = DateFormat('dd MMMM yyyy, HH:mm', 'ru').format(article.createdAt.toDate());

    return Scaffold(
      appBar: AppBar(
        title: Text(article.category),
        actions: [
          IconButton(icon: const Icon(Icons.share), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              article.title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey),
                const SizedBox(width: 8),
                Text(formattedDate, style: const TextStyle(color: Colors.grey, fontSize: 14)),
              ],
            ),
            const SizedBox(height: 16),
            if (article.imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(article.imageUrl, width: double.infinity, fit: BoxFit.cover),
              ),
            const SizedBox(height: 16),
            Text(
              article.content,
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
            const Divider(height: 40),
            const Text('Комментарии (в разработке)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
