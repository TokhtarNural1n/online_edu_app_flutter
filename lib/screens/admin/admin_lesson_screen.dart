import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../view_models/admin_view_model.dart';

class AdminLessonScreen extends StatefulWidget {
  final String courseId;
  final String moduleId;
  // final Lesson? lesson; // Для редактирования в будущем

  const AdminLessonScreen({
    super.key, 
    required this.courseId, 
    required this.moduleId,
  });

  @override
  State<AdminLessonScreen> createState() => _AdminLessonScreenState();
}

class _AdminLessonScreenState extends State<AdminLessonScreen> {
  final _titleController = TextEditingController();
  final _durationController = TextEditingController();
  final _contentController = TextEditingController();
  final _videoUrlController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _durationController.dispose();
    _contentController.dispose();
    _videoUrlController.dispose();
    super.dispose();
  }

  void _handleSaveLesson() async {
    setState(() { _isLoading = true; });
    final adminViewModel = Provider.of<AdminViewModel>(context, listen: false);

    String? error = await adminViewModel.addVideoLesson(
      courseId: widget.courseId,
      moduleId: widget.moduleId,
      title: _titleController.text,
      duration: _durationController.text,
      content: _contentController.text,
      videoUrl: _videoUrlController.text,
    );

    if (mounted) {
      setState(() { _isLoading = false; });
      if (error == null) {
        Navigator.of(context).pop(true); // Возвращаем true для обновления
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $error')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Добавить урок')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'Название урока')),
            const SizedBox(height: 16),
            TextField(controller: _durationController, decoration: const InputDecoration(labelText: 'Длительность (напр. 05:30)')),
            const SizedBox(height: 16),
            TextField(controller: _videoUrlController, decoration: const InputDecoration(labelText: 'Ссылка на видео (YouTube)')),
            const SizedBox(height: 16),
            TextField(controller: _contentController, decoration: const InputDecoration(labelText: 'Текст урока'), maxLines: 10),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _handleSaveLesson,
              child: _isLoading ? const CircularProgressIndicator() : const Text('Сохранить урок'),
            ),
          ],
        ),
      ),
    );
  }
}
