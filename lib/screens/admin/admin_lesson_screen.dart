import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/content_item_model.dart';
import '../../view_models/admin_view_model.dart';

class AdminLessonScreen extends StatefulWidget {
  final String courseId;
  final String moduleId;
  final ContentItem? lessonToEdit; // Теперь можем и редактировать

  const AdminLessonScreen({
    super.key, 
    required this.courseId, 
    required this.moduleId,
    this.lessonToEdit,
  });

  @override
  State<AdminLessonScreen> createState() => _AdminLessonScreenState();
}

class _AdminLessonScreenState extends State<AdminLessonScreen> {
  final _titleController = TextEditingController();
  final _durationController = TextEditingController();
  final _contentController = TextEditingController();
  final _videoUrlController = TextEditingController();
  final _additionalTitleController = TextEditingController(); // <-- НОВЫЙ КОНТРОЛЛЕР
  final _additionalContentController = TextEditingController(); // <-- НОВЫЙ КОНТРОЛЛЕР
  bool _isStopLesson = false;
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    if (widget.lessonToEdit != null) {
      // Заполняем поля, если это редактирование
      _titleController.text = widget.lessonToEdit!.title;
      _durationController.text = widget.lessonToEdit!.duration ?? '';
      _contentController.text = widget.lessonToEdit!.content ?? '';
      _videoUrlController.text = widget.lessonToEdit!.videoUrl ?? '';
      _additionalTitleController.text = widget.lessonToEdit!.additionalInfoTitle ?? '';
      _additionalContentController.text = widget.lessonToEdit!.additionalInfoContent ?? '';
      _isStopLesson = widget.lessonToEdit!.isStopLesson;
    }
  }

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

    String? error;

    if (widget.lessonToEdit == null) {
      // Режим СОЗДАНИЯ
      error = await adminViewModel.addVideoLesson(
        courseId: widget.courseId,
        moduleId: widget.moduleId,
        title: _titleController.text,
        duration: _durationController.text,
        content: _contentController.text,
        videoUrl: _videoUrlController.text,
        isStopLesson: _isStopLesson,
      );
    } else {
      // Режим ОБНОВЛЕНИЯ
      error = await adminViewModel.updateVideoLesson(
        courseId: widget.courseId,
        moduleId: widget.moduleId,
        contentId: widget.lessonToEdit!.id,
        title: _titleController.text,
        duration: _durationController.text,
        content: _contentController.text,
        videoUrl: _videoUrlController.text,
        isStopLesson: _isStopLesson,
      );
    }

    if (mounted) {
      setState(() { _isLoading = false; });
      if (error == null) {
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $error')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.lessonToEdit == null ? 'Добавить урок' : 'Редактировать урок')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'Название урока')),
            const SizedBox(height: 16),
            TextField(controller: _durationController, decoration: const InputDecoration(labelText: 'Длительность (напр. 05:30)')),
            const SizedBox(height: 16),
            TextField(controller: _videoUrlController, decoration: const InputDecoration(labelText: 'Ссылка на видео (YouTube)')),
            const SizedBox(height: 16),
            TextField(controller: _contentController, decoration: const InputDecoration(labelText: 'Текст урока'), maxLines: 5),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Стоп-урок'),
              value: _isStopLesson,
              onChanged: (val) => setState(() => _isStopLesson = val),
            ),
            
            const Divider(height: 40),
            
            // --- НОВЫЕ ПОЛЯ ---
            const Text('Дополнительная информация (необязательно)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(controller: _additionalTitleController, decoration: const InputDecoration(labelText: 'Заголовок (напр. "Домашнее задание")')),
            const SizedBox(height: 16),
            TextField(controller: _additionalContentController, decoration: const InputDecoration(labelText: 'Описание'), maxLines: 5),
            // --- КОНЕЦ НОВЫХ ПОЛЕЙ ---

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