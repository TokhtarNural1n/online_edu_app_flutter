// lib/screens/admin/admin_edit_news_screen.dart

import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/news_model.dart';
import '../../view_models/admin_view_model.dart';

class AdminEditNewsScreen extends StatefulWidget {
  final NewsArticle article;
  const AdminEditNewsScreen({super.key, required this.article});

  @override
  State<AdminEditNewsScreen> createState() => _AdminEditNewsScreenState();
}

class _AdminEditNewsScreenState extends State<AdminEditNewsScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  bool _isLoading = false;
  XFile? _imageXFile;
  String? _currentImageUrl;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.article.title);
    _contentController = TextEditingController(text: widget.article.content);
    _currentImageUrl = widget.article.imageUrl; // Сохраняем URL текущего изображения
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (pickedFile != null) {
      setState(() {
        _imageXFile = pickedFile;
        _currentImageUrl = null;
      });
    }
  }

  // --- ИЗМЕНЕННЫЙ МЕТОД СОХРАНЕНИЯ ---
  void _handleUpdate() async {
    setState(() { _isLoading = true; });
    final adminViewModel = Provider.of<AdminViewModel>(context, listen: false);

    String? newImageUrl;
    String? newThumbnailUrl;

    // 1. Если было выбрано новое изображение, сначала загружаем его
    if (_imageXFile != null) {
      final imageUrls = await adminViewModel.uploadNewsImageAndThumbnail(_imageXFile!);
      if (imageUrls != null) {
        newImageUrl = imageUrls['imageUrl'];
        newThumbnailUrl = imageUrls['thumbnailUrl'];
      } else {
        // Если загрузка не удалась, прерываем операцию
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ошибка загрузки нового изображения.')));
          setState(() { _isLoading = false; });
        }
        return;
      }
    }
    
    // 2. Вызываем метод обновления, передавая либо новые ссылки, либо ничего
    String? error = await adminViewModel.updateNewsArticle(
      newsId: widget.article.id,
      title: _titleController.text,
      content: _contentController.text,
      newImageUrl: newImageUrl, // будет null, если изображение не меняли
      newThumbnailUrl: newThumbnailUrl, // будет null, если изображение не меняли
      oldImageUrl: widget.article.imageUrl, // всегда передаем старую ссылку для возможного удаления
    );

    if (mounted) {
      setState(() { _isLoading = false; });
      if (error == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Новость успешно обновлена!'), backgroundColor: Colors.green),
        );
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $error'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Редактировать новость')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade400),
                ),
                child: _buildImagePreview(),
              ),
            ),
            const SizedBox(height: 24),
            TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'Заголовок', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            TextField(controller: _contentController, decoration: const InputDecoration(labelText: 'Содержание', border: OutlineInputBorder()), maxLines: 8),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              icon: _isLoading ? const SizedBox.shrink() : const Icon(Icons.save),
              label: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Сохранить изменения'),
              onPressed: _isLoading ? null : _handleUpdate,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    if (_imageXFile != null) {
      return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: kIsWeb
              ? Image.network(_imageXFile!.path, fit: BoxFit.cover)
              : Image.file(File(_imageXFile!.path), fit: BoxFit.cover),
      );
    }
    if (_currentImageUrl != null && _currentImageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(_currentImageUrl!, fit: BoxFit.cover),
      );
    }
    return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_a_photo_outlined), Text('Нажмите, чтобы выбрать фото')]));
  }
}