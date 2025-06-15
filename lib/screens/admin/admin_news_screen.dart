import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/news_model.dart';
import '../../view_models/admin_view_model.dart';
import 'admin_add_news_screen.dart';
import 'admin_edit_news_screen.dart';

class AdminNewsScreen extends StatefulWidget {
  const AdminNewsScreen({super.key});

  @override
  State<AdminNewsScreen> createState() => _AdminNewsScreenState();
}

class _AdminNewsScreenState extends State<AdminNewsScreen> {
  late Future<List<NewsArticle>> _newsFuture;

  @override
  void initState() {
    super.initState();
    _loadNews();
  }

  void _loadNews() {
    _newsFuture = Provider.of<AdminViewModel>(context, listen: false).fetchNews();
  }

  void _refreshNewsList() {
    setState(() {
      _loadNews();
    });
  }

  void _deleteArticle(NewsArticle article) {
    // Показываем диалог подтверждения
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Подтвердите удаление'),
        content: Text('Вы уверены, что хотите удалить новость "${article.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Отмена')),
          TextButton(
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
            onPressed: () async {
              Navigator.of(context).pop();
              final adminViewModel = Provider.of<AdminViewModel>(context, listen: false);
              await adminViewModel.deleteNewsArticle(newsId: article.id, imageUrl: article.imageUrl);
              _refreshNewsList();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Управление новостями')),
      body: FutureBuilder<List<NewsArticle>>(
        future: _newsFuture,
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
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: article.imageUrl.isNotEmpty
                      ? SizedBox(width: 50, child: Image.network(article.imageUrl, fit: BoxFit.cover))
                      : const Icon(Icons.image_not_supported),
                  title: Text(article.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(article.content, maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    onPressed: () => _deleteArticle(article),
                  ),
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AdminEditNewsScreen(article: article)),
                    );
                    if (result == true) {
                      _refreshNewsList();
                    }
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'news_fab',
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AdminAddNewsScreen()),
          );
          if (result == true) {
            _refreshNewsList();
          }
        },
        child: const Icon(Icons.add),
        tooltip: 'Создать новость',
      ),
    );
  }
}
