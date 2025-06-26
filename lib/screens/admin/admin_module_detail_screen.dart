// lib/screens/admin/admin_module_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/content_item_model.dart';
import '../../view_models/admin_view_model.dart';
import 'admin_lesson_screen.dart';
import 'admin_add_test_screen.dart';
import 'admin_add_material_screen.dart';

class AdminModuleDetailScreen extends StatefulWidget {
  final String courseId;
  final String moduleId;
  final String moduleTitle;

  const AdminModuleDetailScreen({
    super.key,
    required this.courseId,
    required this.moduleId,
    required this.moduleTitle,
  });

  @override
  State<AdminModuleDetailScreen> createState() => _AdminModuleDetailScreenState();
}

class _AdminModuleDetailScreenState extends State<AdminModuleDetailScreen> {
  late Future<List<ContentItem>> _contentFuture;

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  void _loadContent() {
    _contentFuture = Provider.of<AdminViewModel>(context, listen: false)
        .fetchContentItems(widget.courseId, widget.moduleId);
  }

  void _refreshContentList() {
    setState(() { _loadContent(); });
  }

  void _showAddContentMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Wrap(
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.video_collection_outlined),
              title: const Text('Добавить видеоурок'),
              onTap: () async {
                Navigator.pop(context);
                // Передаем null, так как это создание нового урока
                final result = await Navigator.push(context, MaterialPageRoute(builder: (_) =>
                  AdminLessonScreen(courseId: widget.courseId, moduleId: widget.moduleId, lessonToEdit: null)
                ));
                if (result == true) _refreshContentList();
              },
            ),
            ListTile(
              leading: const Icon(Icons.quiz_outlined),
              title: const Text('Добавить тест'),
              onTap: () async {
                Navigator.pop(context);
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AdminAddTestScreen(
                      courseId: widget.courseId,
                      moduleId: widget.moduleId,
                    ),
                  ),
                );
                if (result == true) _refreshContentList();
              },
            ),
            ListTile(
              leading: const Icon(Icons.attach_file_outlined),
              title: const Text('Добавить материал'),
              onTap: () async {
                Navigator.pop(context);
                final result = await Navigator.push(context, MaterialPageRoute(builder: (_) =>
                  AdminAddMaterialScreen(courseId: widget.courseId, moduleId: widget.moduleId)
                ));
                if (result == true) _refreshContentList();
              },
            ),
          ],
        );
      },
    );
  }
  
    // --- НОВЫЙ МЕТОД ДЛЯ НАВИГАЦИИ НА ЭКРАН РЕДАКТИРОВАНИЯ ---
  void _navigateToEditScreen(ContentItem item) async {
    bool? result;
    
    if (item.type == ContentType.lesson) {
      result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => AdminLessonScreen(
          courseId: widget.courseId,
          moduleId: widget.moduleId,
          lessonToEdit: item,
        )),
      );
    } else if (item.type == ContentType.test) {
      result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => AdminAddTestScreen(
          courseId: widget.courseId,
          moduleId: widget.moduleId,
          testToEdit: item,
        )),
      );
    } else if (item.type == ContentType.material) {
      result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => AdminAddMaterialScreen(
          courseId: widget.courseId,
          moduleId: widget.moduleId,
          materialToEdit: item,
        )),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Редактирование для типа "${item.type.name}" не реализовано'))
      );
      return;
    }
    
    if (result == true) {
      _refreshContentList();
    }
  }

  IconData _getIconForContentType(ContentType type) {
    switch (type) {
      case ContentType.lesson: return Icons.video_collection_outlined;
      case ContentType.test: return Icons.quiz_outlined;
      case ContentType.material: return Icons.attach_file_outlined;
      default: return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.moduleTitle)),
      body: FutureBuilder<List<ContentItem>>(
        future: _contentFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return const Center(child: Text('Контента в этом модуле еще нет.'));
          }
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return ListTile(
                leading: Icon(_getIconForContentType(item.type)),
                title: Text(item.title),
                // --- ИЗМЕНЕНИЕ ЗДЕСЬ: ДОБАВИЛИ КНОПКУ РЕДАКТИРОВАНИЯ ---
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: Colors.blueAccent),
                      onPressed: () => _navigateToEditScreen(item),
                      tooltip: 'Редактировать',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () async {
                        await Provider.of<AdminViewModel>(context, listen: false)
                            .deleteContentItem(courseId: widget.courseId, moduleId: widget.moduleId, contentId: item.id);
                        _refreshContentList();
                      },
                      tooltip: 'Удалить',
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'module_detail_fab',
        onPressed: _showAddContentMenu,
        child: const Icon(Icons.add),
        tooltip: 'Добавить контент',
      ),
    );
  }
}